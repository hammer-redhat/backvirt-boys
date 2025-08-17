# AAP Workflow Setup for VM Scaling with Approval

This guide explains how to set up an AAP Workflow Template for VM scaling that includes approval gates.

## 📋 Overview

Instead of using `ansible.builtin.pause` (which doesn't work in AAP), we create a workflow with:
1. **Request Job** → **Approval Node** → **Execution Job**

## 🔧 Setup Steps

### Step 1: Create Job Templates

Create these 3 job templates in AAP:

#### 1.1 "VM Scale Request" Job Template
- **Playbook**: `vm-memory/scale-vm-request.yml`
- **Purpose**: Validates VM and displays scaling request details
- **Survey Variables**:
  - `vm_name` (Text, Required)
  - `namespace` (Text, Default: "default")
  - `new_instance_type` (Choice, Optional: u1.nano, u1.micro, u1.small, etc.)

#### 1.2 "VM Scale Execute" Job Template  
- **Playbook**: `vm-memory/scale-vm-execute.yml`
- **Purpose**: Performs the actual VM scaling after approval
- **Variables**: Inherited from workflow

#### 1.3 "VM Scale Complete" Job Template (Optional)
- **Playbook**: `vm-memory/scale-vm.yml` (complete workflow in one job)
- **Purpose**: Direct scaling without approval (for emergency use)

### Step 2: Create Workflow Template

#### 2.1 Create Workflow Template
- **Name**: "VM Scaling with Approval"
- **Organization**: Default
- **Inventory**: Localhost

#### 2.2 Workflow Design
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

#### 2.3 Workflow Node Configuration

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

### Step 3: Configure EDA Integration

Update your EDA rulebook to trigger the workflow:

```yaml
# In extensions/eda/rulebooks/webhook_port.yml
- name: Trigger VM Scaling Workflow with Approval
  condition: >
    event.payload.status == "firing" and
    event.payload.commonLabels.alertname == "VMHighMemoryUsage"
  actions:
    - run_workflow_job_template:
        name: "VM Scaling with Approval"
        organization: "Default"
        extra_vars:
          vm_name: "{{ event.payload.commonLabels.name }}"
          namespace: "{{ event.payload.commonLabels.namespace }}"
          severity: "{{ event.payload.commonLabels.severity }}"
          description: "{{ event.payload.commonAnnotations.description }}"
```

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

- **VM Not Found**: Check namespace and VM name in request job output
- **Approval Timeout**: Extend timeout in approval node settings
- **Scaling Failures**: Review execute job logs for detailed errors
- **EDA Issues**: Verify webhook URL and EDA rulebook syntax

This approach provides enterprise-grade approval workflows while maintaining all the technical capabilities of the original scaling solution.
