# AAP Workflow Template Configuration Guide

This guide shows exactly how to configure the workflow template to accept extra variables from the trigger job.

## 🔥 **Critical Configuration: Enable Extra Variables**

You need to enable "Prompt on Launch" → "Extra Variables" on **THREE** templates:
1. **Workflow Template**: "VM Scaling with Approval"
2. **Job Template**: "VM Scale Request" 
3. **Job Template**: "VM Scale Execute"

### Step 1: Configure Workflow Template

1. **Login to AAP Web Interface**
   - Navigate to `http://aap.aap`
   - Login with your credentials

2. **Go to Workflow Templates**
   - Click **Resources** → **Templates** 
   - Filter by **Workflow Job Template**
   - Find **"VM Scaling with Approval"**

3. **Edit the Workflow Template**
   - Click the **pencil/edit icon** next to the workflow template
   - OR click the template name and then click **Edit**

### Step 2: Configure Prompt on Launch Settings

1. **Find the "Prompt on Launch" Section**
   - Scroll down in the template edit form
   - Look for the **"Options"** or **"Prompt on Launch"** section

2. **Enable Extra Variables Prompt**
   ```
   ☐ Inventory
   ☐ Credentials  
   ☐ Other Prompts
   ☑ Extra Variables    ← CHECK THIS BOX!
   ☐ Tags
   ☐ Skip Tags
   ☐ Job Type
   ☐ Verbosity
   ☐ Diff Mode
   ```

3. **Save the Template**
   - Click **Save** at the bottom of the form
   - Verify the changes are saved

### Step 2: Configure "VM Scale Request" Job Template

1. **Go to Job Templates**
   - Click **Resources** → **Templates** 
   - Filter by **Job Template** (not Workflow)
   - Find **"VM Scale Request"**

2. **Edit the Job Template**
   - Click the **pencil/edit icon**
   - Scroll to **"Prompt on Launch"** section
   - Check ✅ **"Extra Variables"**
   - Click **Save**

### Step 3: Configure "VM Scale Execute" Job Template

1. **Find the Job Template**
   - In **Resources** → **Templates**
   - Find **"VM Scale Execute"**

2. **Edit and Enable Extra Variables**
   - Click the **pencil/edit icon**
   - Scroll to **"Prompt on Launch"** section  
   - Check ✅ **"Extra Variables"**
   - Click **Save**

### Step 4: Verify All Configurations

After saving all three templates, verify:
- **Workflow Template "VM Scaling with Approval"**: Shows "Extra Variables" enabled
- **Job Template "VM Scale Request"**: Shows "Extra Variables" enabled  
- **Job Template "VM Scale Execute"**: Shows "Extra Variables" enabled

## 🔍 **Visual Reference**

### What You're Looking For:
```
┌─────────────────────────────────────────┐
│ Edit Workflow Job Template              │
├─────────────────────────────────────────┤
│ Name: VM Scaling with Approval          │
│ Description: [optional]                 │
│ Organization: Default                   │
│ Inventory: Localhost                    │
│                                         │
│ OPTIONS:                                │
│ ☐ Enable Webhook                       │
│ ☐ Enable Concurrent Jobs               │
│                                         │
│ PROMPT ON LAUNCH:                       │
│ ☐ Inventory                            │
│ ☐ Credentials                          │
│ ☑ Extra Variables  ← MUST BE CHECKED!  │
│ ☐ Tags                                 │
│ ☐ Skip Tags                            │
│                                         │
│           [Save]    [Cancel]            │
└─────────────────────────────────────────┘
```

## ✅ **Testing the Configuration**

### Test 1: Workflow Template
1. **Go to the workflow template "VM Scaling with Approval"**
2. **Click "Launch"**
3. **You should see an "Extra Variables" text box**

### Test 2: Job Templates  
1. **Go to "VM Scale Request" job template**
2. **Click "Launch"** 
3. **You should see an "Extra Variables" text box**
4. **Repeat for "VM Scale Execute" job template**

### Test 3: End-to-End Flow
1. **Trigger the workflow** via the trigger job
2. **Workflow should pass variables** to "VM Scale Request"  
3. **Request job should complete** and pass variables via `set_stats`
4. **Execute job should receive** the approved variables

## 🎯 **Expected Variables**

The trigger job will pass these variables to your workflow:

```yaml
vm_name: "rhel-8-brown-stork-74"
namespace: "webhook-store"  
severity: "critical"
description: "VM rhel-8-brown-stork-74 in namespace webhook-store is using more than 80% of its available memory."
triggered_by: "EDA"
triggered_at: "2025-08-17T21:25:34Z"
```

## 🚨 **Common Issues**

### **"Prompt on Launch not visible"**
- Refresh the page and try again
- Check user permissions - you need edit access to the template
- Verify you're editing the correct template

### **"Changes not saving"**  
- Check for validation errors in the form
- Ensure all required fields are filled
- Try refreshing and editing again

### **"Still getting 400 error after enabling"**
- Wait a few seconds after saving (settings may need to propagate)
- Verify the template was actually saved (check the "Prompt on Launch" column in the template list)
- Test manual launch to confirm extra variables prompt appears

### **"Missing required approval variables" in VM Scale Execute**
- **Root Cause**: "VM Scale Execute" job template doesn't have "Prompt on Launch" → "Extra Variables" enabled
- **Solution**: Enable extra variables on ALL job templates in the workflow (not just the workflow template)
- **Quick Fix**: Edit "VM Scale Execute" job template → Prompt on Launch → ✅ Extra Variables

### **"target_instance_type != ''" assertion failed**
- The execute job expects variables from the request job: `vm_namespace_approved`, `vm_name_approved`, `target_instance_type_approved`
- Ensure "VM Scale Request" completed successfully and used `set_stats` to pass variables
- Check that both "VM Scale Request" AND "VM Scale Execute" have extra variables enabled

## 🎉 **Success Indicators**

✅ **All Templates Configured**: Workflow + both job templates show "Extra Variables" enabled  
✅ **Manual Launch**: All templates show extra variables text box when launched  
✅ **API Launch**: Returns 201/202 instead of 400  
✅ **Workflow Execution**: Variables flow correctly between all workflow nodes
✅ **No Variable Errors**: "VM Scale Execute" receives required approval variables

## 📋 **Quick Checklist**

Before testing your workflow, verify:
- [ ] **Workflow Template "VM Scaling with Approval"**: Extra Variables ✅
- [ ] **Job Template "VM Scale Request"**: Extra Variables ✅  
- [ ] **Job Template "VM Scale Execute"**: Extra Variables ✅
- [ ] **Job Template "Trigger VM Scaling Workflow"**: Extra Variables ✅

Once ALL four templates are configured correctly, your EDA webhook → trigger job → workflow launch sequence will work perfectly!
