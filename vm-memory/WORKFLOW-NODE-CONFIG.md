# Workflow Node Configuration for Variable Passing

This guide explains how to configure workflow nodes to properly pass variables between job templates.

## 🔍 **Debugging Variable Flow**

I've added debug output to both job templates to help identify where the variable passing is failing.

### Step 1: Run the Workflow and Check Logs

1. **Trigger your workflow** (via EDA or manually)
2. **Wait for "VM Scale Request" job to complete**
3. **Check the job output** for this section:
   ```
   === SETTING WORKFLOW VARIABLES ===
   vm_namespace_approved: webhook-store
   vm_name_approved: rhel-8-brown-stork-74
   current_instance_type_approved: u1.medium
   target_instance_type_approved: u1.large
   scaling_required: True
   ```

4. **When "VM Scale Execute" job runs**, check for:
   ```
   === ALL AVAILABLE VARIABLES ===
   vm_namespace_approved: webhook-store (should show values)
   vm_name_approved: rhel-8-brown-stork-74 (should show values)
   target_instance_type_approved: u1.large (should show values)
   ```

### Step 2: Identify the Issue

**If "VM Scale Request" shows variables but "VM Scale Execute" shows "NOT SET":**
- Variables aren't being passed between workflow nodes
- This indicates a workflow configuration issue

**If "VM Scale Request" shows empty values:**
- The request job itself has an issue
- Check the original variables from the trigger job

## 🔧 **Workflow Node Configuration**

### Method 1: Check Workflow Node Settings

1. **Edit your workflow template** "VM Scaling with Approval"
2. **Go to the Workflow Visualizer** 
3. **Click on each workflow node** and verify:

**VM Scale Request Node:**
- **Convergence**: `Any`
- **Job Template**: "VM Scale Request"
- **Prompt on Launch**: Should pass original variables

**Approval Node:**
- **Type**: Approval
- **Convergence**: `Any`
- **Timeout**: Set appropriately

**VM Scale Execute Node:**
- **Convergence**: `Any`  
- **Job Template**: "VM Scale Execute"
- **Run**: `Always` (not just on success)

### Method 2: Alternative - Use Extra Variables Instead of set_stats

If set_stats isn't working, we can modify the workflow to pass variables directly.

**Option A: Pass Variables via Workflow Template Extra Variables**

Edit the workflow template to include these default extra variables:
```yaml
vm_namespace_approved: "{{ vm_namespace | default('') }}"
vm_name_approved: "{{ vm_name | default('') }}"
target_instance_type_approved: "{{ new_instance_type | default('') }}"
```

**Option B: Modify Job Templates to Use Original Variables**

Update `scale-vm-execute.yml` to fall back to original variables:
```yaml
vm_namespace_final: "{{ vm_namespace_approved | default(vm_namespace) | default(namespace) | default('default') }}"
vm_name_final: "{{ vm_name_approved | default(vm_name) | default('') }}"
```

## 🚨 **Common Issues & Solutions**

### Issue 1: "set_stats not working between workflow nodes"

**Symptoms:** Request job sets variables but execute job shows "NOT SET"

**Solutions:**
1. **Check AAP Version**: Some older versions have issues with set_stats in workflows
2. **Verify Node Connections**: Ensure workflow nodes are properly connected
3. **Check Convergence Settings**: Set to "Any" on all nodes

### Issue 2: "Variables cleared by approval node"

**Symptoms:** Variables work until approval, then disappear

**Solutions:**
1. **Use workflow-level extra variables** instead of set_stats
2. **Configure approval node** to preserve variables
3. **Test without approval** to isolate the issue

### Issue 3: "Workflow template not passing variables to child jobs"

**Symptoms:** Workflow receives variables but child jobs don't

**Solutions:**
1. **Enable "Prompt on Launch" → "Extra Variables"** on ALL job templates
2. **Check workflow template configuration**
3. **Use workflow visualizer** to verify node settings

## 🧪 **Testing Methods**

### Test 1: Run Jobs Individually

1. **Run "VM Scale Request" manually** with these extra variables:
   ```yaml
   vm_name: rhel-8-brown-stork-74
   namespace: webhook-store
   ```

2. **Check if it completes successfully** and shows the debug output

3. **Run "VM Scale Execute" manually** with these extra variables:
   ```yaml
   vm_namespace_approved: webhook-store
   vm_name_approved: rhel-8-brown-stork-74
   target_instance_type_approved: u1.large
   current_instance_type_approved: u1.medium
   scaling_required: true
   ```

### Test 2: Simplified Workflow

Create a simple test workflow with just:
1. VM Scale Request → VM Scale Execute (no approval)
2. Test if variables pass correctly
3. Add approval back once basic flow works

## 🎯 **Expected Debug Output**

### Successful VM Scale Request Job:
```
=== SETTING WORKFLOW VARIABLES ===
vm_namespace_approved: webhook-store
vm_name_approved: rhel-8-brown-stork-74
current_instance_type_approved: u1.medium
target_instance_type_approved: u1.large
scaling_required: True

✅ Workflow variables have been set via set_stats for the next job
```

### Successful VM Scale Execute Job:
```
=== ALL AVAILABLE VARIABLES ===
vm_namespace_approved: webhook-store
vm_name_approved: rhel-8-brown-stork-74
target_instance_type_approved: u1.large
current_instance_type_approved: u1.medium
scaling_required: True
```

Once you see these debug outputs working correctly, the variable passing is fixed and the workflow will proceed to actual VM scaling!
