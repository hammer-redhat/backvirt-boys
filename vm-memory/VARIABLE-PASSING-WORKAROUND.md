# Variable Passing Workaround for AAP Workflows

This document explains the workaround implemented to handle variable passing issues between workflow nodes.

## 🔍 **Problem Identified**

Based on the debug output, we discovered:

### ✅ **Working:**
- Trigger job → Workflow template variable passing
- Original variables reach the execute job:
  - `vm_name: rhel-8-brown-stork-74`
  - `namespace: webhook-store`

### ❌ **Not Working:**
- VM Scale Request → VM Scale Execute variable passing via `set_stats`
- All approved variables show: `NOT SET`

## 🔧 **Workaround Implemented**

Since the original variables ARE reaching the execute job, I've modified `scale-vm-execute.yml` to:

### **1. Use Available Variables First**
```yaml
vm_namespace_final: "{{ vm_namespace_approved | default(vm_namespace) | default(namespace) | default('default') }}"
vm_name_final: "{{ vm_name_approved | default(vm_name) | default('') }}"
```

### **2. Auto-Detect VM Details When Needed**
If approved variables aren't available, the execute job will:
1. **Collect VM information** using the available `vm_name` and `namespace`
2. **Determine current instance type** from the VM spec
3. **Calculate next instance type** using the progression mapping
4. **Proceed with scaling** using the auto-detected values

### **3. Maintain Approval Workflow**
The workflow still includes the approval step, but the execute job doesn't depend on variables from the request job.

## 🎯 **How It Works Now**

### **End-to-End Flow:**
```
EDA Webhook → Trigger Job → Workflow Launch
     ↓              ↓             ↓
vm_name, namespace → extra_vars → VM Scale Request (validates, requests approval)
     ↓                              ↓
Direct to Execute ←────────────────────
     ↓
VM Scale Execute (uses original vars + auto-detection)
     ↓
Actual VM Scaling
```

### **Variable Sources in Execute Job:**
1. **Preferred**: Approved variables from request job (when working)
2. **Fallback**: Original variables from trigger job + auto-detection
3. **Result**: Always has the data needed for scaling

## ✅ **Benefits of This Approach**

### **1. Robust**
- Works regardless of `set_stats` issues
- Uses multiple fallback mechanisms
- Always has the required data for scaling

### **2. Maintains Approval**
- Approval workflow still functions
- User can review and approve scaling requests
- Execute job runs after approval

### **3. Auto-Detection**
- Automatically determines current VM instance type
- Calculates appropriate next instance type
- No manual configuration needed

### **4. Backwards Compatible**
- Still works with approved variables when available
- Gracefully falls back to workaround when needed
- Debug output shows which method was used

## 🚀 **Expected Behavior**

### **Debug Output (Execute Job):**
```
=== ALL AVAILABLE VARIABLES ===
vm_namespace_approved: NOT SET
vm_name_approved: NOT SET
target_instance_type_approved: NOT SET

Fallback variables:
vm_name: rhel-8-brown-stork-74
namespace: webhook-store

========== EXECUTING VM SCALING ==========
VM: rhel-8-brown-stork-74
Namespace: webhook-store
Current Instance Type: u1.medium  (auto-detected)
Target Instance Type: u1.large    (auto-calculated)
Scaling Required: True
Variables Source: Direct (Workaround)
```

### **Scaling Process:**
1. ✅ Collects VM information from OpenShift
2. ✅ Determines current instance type (e.g., u1.medium)
3. ✅ Calculates next instance type (e.g., u1.large)
4. ✅ Proceeds with hot-plug scaling
5. ✅ Verifies scaling success

## 🔄 **Future Improvements**

When the `set_stats` variable passing is fixed in your AAP environment:
- The execute job will automatically use approved variables
- Debug output will show "Variables Source: Approved (from Request Job)"
- No changes needed - the workaround will be bypassed

## 🎯 **Testing**

Your next workflow run should:
1. ✅ **Pass validation** (no more "target_instance_type != ''" errors)
2. ✅ **Show auto-detected values** in debug output
3. ✅ **Proceed to actual VM scaling** after approval
4. ✅ **Successfully scale** `rhel-8-brown-stork-74` from current to next instance type

This workaround ensures your VM scaling workflow works end-to-end while maintaining the approval process!
