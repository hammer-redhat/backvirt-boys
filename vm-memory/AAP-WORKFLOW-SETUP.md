# AAP Workflow Setup for VM Scaling with Approval

This guide explains how to set up an AAP Workflow Template for VM scaling that includes approval gates.

## 📋 Overview

Instead of using `ansible.builtin.pause` (which doesn't work in AAP), we create a workflow with:
1. **Request Job** → **Approval Node** → **Execution Job**

## 🔧 Setup Steps

### Step 1: Create Job Templates

Create these 4 job templates in AAP:

#### 1.1 "Trigger VM Scaling Workflow" Job Template
- **Playbook**: `vm-memory/trigger-workflow.yml`
- **Purpose**: EDA-callable job that triggers the workflow via AAP API
- **Credentials**: AAP Controller credentials
- **Environment Variables**:
  - `CONTROLLER_HOST`: Your AAP controller URL (e.g., https://aap.example.com)
  - `CONTROLLER_USERNAME`: AAP username (usually admin)
  - `CONTROLLER_PASSWORD`: AAP password
  - `CONTROLLER_VERIFY_SSL`: false (for self-signed certs)

#### 1.2 "VM Scale Request" Job Template
- **Playbook**: `vm-memory/scale-vm-request.yml`
- **Purpose**: Validates VM and displays scaling request details
- **🔥 CRITICAL**: Enable **"Prompt on Launch"** for **"Extra Variables"**
- **Survey Variables**:
  - `vm_name` (Text, Required)
  - `namespace` (Text, Default: "default")
  - `new_instance_type` (Choice, Optional: u1.nano, u1.micro, u1.small, etc.)

#### 1.3 "VM Scale Execute" Job Template  
- **Playbook**: `vm-memory/scale-vm-execute.yml`
- **Purpose**: Performs the actual VM scaling after approval
- **🔥 CRITICAL**: Enable **"Prompt on Launch"** for **"Extra Variables"**
- **Variables**: Inherited from workflow via set_stats

#### 1.4 "VM Scale Complete" Job Template (Optional)
- **Playbook**: `vm-memory/scale-vm.yml` (complete workflow in one job)
- **Purpose**: Direct scaling without approval (for emergency use)

### Step 2: Create Workflow Template

#### 2.1 Create Workflow Template
- **Name**: "VM Scaling with Approval"
- **Organization**: Default
- **Inventory**: Localhost
- **🔥 CRITICAL**: Enable **"Prompt on Launch"** for **"Extra Variables"**

**Important Configuration Steps:**
1. In the workflow template settings, check **"Prompt on Launch"** 
2. Ensure **"Extra Variables"** is selected in the prompt options
3. This allows the trigger job to pass variables to the workflow

📋 **For detailed step-by-step instructions, see: `WORKFLOW-TEMPLATE-CONFIG.md`**

#### 2.2 Configure Variable Passing Between Workflow Nodes

**🔥 CRITICAL - ALL Job Templates Need Extra Variables Enabled:**

1. **"VM Scale Request" Job Template**:
   - Edit template → **Prompt on Launch** → ✅ **Extra Variables**

2. **"VM Scale Execute" Job Template**:  
   - Edit template → **Prompt on Launch** → ✅ **Extra Variables**

3. **Workflow Template**:
   - Edit template → **Prompt on Launch** → ✅ **Extra Variables**

**Variable Flow:**
```
Trigger Job → Workflow → VM Scale Request → set_stats → VM Scale Execute
     ↓            ↓           ↓                ↓            ↓
  EDA vars → extra_vars → validates VM → approved vars → scaling
```

#### 2.3 Workflow Design
```
┌─────────────────────┐
│  VM Scale Request   │
│  (Job Template)     │
└─────────┬───────────┘
          │ On Success
          ▼
┌─────────────────────┐
│   Approval Node     │
│  (Manual Review)    │
└─────────┬───────────┘
          │ On Approval
          ▼
┌─────────────────────┐
│  VM Scale Execute   │
│  (Job Template)     │
└─────────────────────┘
```

#### 2.4 Workflow Node Configuration

**Node 1: VM Scale Request**
- **Type**: Job Template
- **Job Template**: "VM Scale Request"
- **Convergence**: Any
- **On Success**: Go to Approval Node

**Node 2: Approval Node**
- **Type**: Approval
- **Name**: "Approve VM Scaling"
- **Description**: "Review and approve VM instance type scaling"
- **Timeout**: 3600 seconds (1 hour)
- **On Approval**: Go to VM Scale Execute
- **On Denial/Timeout**: End workflow

**Node 3: VM Scale Execute**
- **Type**: Job Template  
- **Job Template**: "VM Scale Execute"
- **Convergence**: Any
- **🔥 CRITICAL**: Configure to **"Always"** run (not just on success)
- **🔥 CRITICAL**: Ensure variables are passed from previous node

### Step 3: Configure EDA Integration

The EDA rulebook now uses a trigger job template (since `run_workflow_job_template` isn't supported in all EDA versions):

```yaml
# In extensions/eda/rulebooks/webhook_port.yml
- name: Trigger VM Scaling Workflow with Approval
  condition: >
    event.payload.status == "firing" and
    event.payload.commonLabels.alertname == "VMHighMemoryUsage"
  actions:
    - run_job_template:
        name: "Trigger VM Scaling Workflow"  # Job that triggers workflow via API
        organization: "Default"
        extra_vars:
          vm_name: "{{ event.payload.commonLabels.name }}"
          namespace: "{{ event.payload.commonLabels.namespace }}"
          severity: "{{ event.payload.commonLabels.severity }}"
          description: "{{ event.payload.commonAnnotations.description }}"
          workflow_name: "VM Scaling with Approval"
```

### Step 4: Configure AAP Controller Access

The trigger job needs AAP API access. **OAuth tokens are recommended** for better security.

#### **Option A: OAuth Token Authentication (Recommended)**
1. **Create OAuth Token**: Follow the guide in `CREATE-AAP-TOKEN.md`
2. **Set Environment Variables** in the job template:
```bash
CONTROLLER_HOST=http://aap.aap
CONTROLLER_OAUTH_TOKEN=your-oauth-token-here
CONTROLLER_VERIFY_SSL=false
```

#### **Option B: Username/Password Authentication (Fallback)**
```bash
CONTROLLER_HOST=http://aap.aap
CONTROLLER_USERNAME=admin
CONTROLLER_PASSWORD=your-aap-password
CONTROLLER_VERIFY_SSL=false
```

#### **Option C: Custom Credential Type**
See `CREATE-AAP-TOKEN.md` for detailed credential type configuration.

**Important:** 
- `CONTROLLER_HOST` should be the base URL only (e.g., `http://aap.aap`)
- Do NOT include `/api/controller/` or other paths - these are added by the playbook
- OAuth tokens provide better security and are the preferred method

## 🔧 Complete Workflow Architecture

```
EDA Webhook Alert (namespace: webhook-store)
        │
        ▼
┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│ Trigger Workflow    │───▶│  VM Scale Request   │───▶│   Approval Node     │───▶│  VM Scale Execute   │
│   (Job Template)    │    │   (Job Template)    │    │  (Manual Review)    │    │   (Job Template)    │
│                     │    │                     │    │                     │    │                     │
│ • Call AAP API      │    │ • Validate VM       │    │ • Review details    │    │ • Perform scaling   │
│ • Launch workflow   │    │ • Check permissions │    │ • Approve/Deny      │    │ • Verify results    │
│ • Pass variables    │    │ • Display plan      │    │ • Timeout handling  │    │ • Report status     │
└─────────────────────┘    └─────────────────────┘    └─────────────────────┘    └─────────────────────┘
```

**Why this approach?**
- EDA `run_workflow_job_template` action not supported in all versions
- Uses standard `run_job_template` action which is universally supported  
- Trigger job uses AAP API to launch workflow with proper variable passing
- Maintains all approval and error handling capabilities

## 🎯 Workflow Benefits

### ✅ **Approval Control**
- Manual review before scaling operations
- Configurable approval timeouts
- Audit trail of approvals/denials

### ✅ **EDA Integration** 
- Automatic workflow triggers from alerts
- Proper namespace detection from webhook events
- Context preservation between workflow nodes

### ✅ **Error Handling**
- VM discovery across namespaces
- Clear failure messages and troubleshooting
- Rollback capabilities

### ✅ **Flexibility**
- Emergency direct scaling option (bypass approval)
- Manual workflow triggers with custom parameters
- Instance type auto-detection or manual override

## 🔍 Usage Scenarios

### Scenario 1: EDA-Triggered Scaling
1. Prometheus alert fires for high VM memory
2. EDA webhook triggers workflow
3. Request job validates VM and shows scaling plan
4. Approval node waits for manual review
5. Execute job performs scaling after approval

### Scenario 2: Manual Scaling
1. Operator launches workflow manually
2. Provides VM name and namespace via survey
3. Same approval process follows
4. Scaling executes after approval

### Scenario 3: Emergency Scaling
1. Use "VM Scale Complete" job template directly
2. Bypasses approval for urgent situations
3. Still provides validation and error handling

## 📝 Variables Flow

```
EDA/Manual Input → Request Job → Workflow Variables → Execute Job
     ↓               ↓              ↓               ↓
  vm_name      → validates VM → sets approved → uses approved
  namespace    → gets current → variables    → variables
  severity     → instance type→ via stats   → for scaling
```

## 🚨 Troubleshooting

### Common Job Template Issues
- **VM Not Found**: Check namespace and VM name in request job output
- **Approval Timeout**: Extend timeout in approval node settings
- **Scaling Failures**: Review execute job logs for detailed errors
- **EDA Issues**: Verify webhook URL and EDA rulebook syntax

### Authentication Issues
- **"Bearer token not supported"**: Create OAuth token in AAP (see `CREATE-AAP-TOKEN.md`)
- **"Authentication failed"**: Verify token/credentials and `CONTROLLER_HOST` format
- **"Permission denied"**: Check user permissions and workflow template access

### Variable Issues
- **"ansible_date_time is undefined"**: Playbook uses `gather_facts: false` for performance
- **"namespace conflicts"**: Playbook uses safe variable aliases to avoid Jinja2 conflicts
- **"Missing variables"**: Check EDA webhook payload and job template variable passing
- **"Variables not allowed on launch"**: Enable "Prompt on Launch" → "Extra Variables" on workflow template

### Collection/Filter Issues
- **"Could not load json_query"** or **"unable to locate collection community.general"**:
  - **Root Cause**: Execution environment missing `community.general` collection
  - **Solution**: Playbooks now use native Jinja2 filters instead of `json_query`
  - **Alternative**: Add `community.general` collection to your execution environment

### Workflow Template Configuration Issues
- **HTTP 400: "Variables not allowed on launch"**: 
  1. Edit your workflow template "VM Scaling with Approval"
  2. Go to **Settings** → **Prompt on Launch**
  3. Check ✅ **"Extra Variables"**
  4. Save the template
- **Workflow not found**: Verify workflow template name matches exactly: "VM Scaling with Approval"
- **Permission denied**: User must have execute permission on workflow template

### Variable Passing Issues Between Workflow Nodes
- **"Missing required approval variables"** in VM Scale Execute job:
  1. **Enable Extra Variables** on "VM Scale Execute" job template:
     - Edit job template → **Prompt on Launch** → ✅ **Extra Variables**
  2. **Verify VM Scale Request** job completed successfully and used `set_stats`
  3. **Check workflow node configuration** - variables should flow between nodes
  4. **Debug the variable flow**: See detailed guide in `WORKFLOW-NODE-CONFIG.md`

- **"target_instance_type != ''" assertion failed**:
  - **Root Cause**: Variables from "VM Scale Request" not reaching "VM Scale Execute"
  - **Debug Steps**: Both job templates now include detailed debug output
  - **Check Logs**: Look for "=== SETTING WORKFLOW VARIABLES ===" and "=== ALL AVAILABLE VARIABLES ==="
  - **Expected Variables**: `vm_namespace_approved`, `vm_name_approved`, `target_instance_type_approved`

📋 **For detailed debugging steps, see: `WORKFLOW-NODE-CONFIG.md`**  
📋 **For variable passing workaround, see: `VARIABLE-PASSING-WORKAROUND.md`**

This approach provides enterprise-grade approval workflows while maintaining all the technical capabilities of the original scaling solution.
