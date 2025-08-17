# AAP Workflow Template Configuration Guide

This guide shows exactly how to configure the workflow template to accept extra variables from the trigger job.

## 🔥 **Critical Configuration: Enable Extra Variables**

### Step 1: Access Workflow Template Settings

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

### Step 3: Verify Configuration

After saving, you should see:
- **"Prompt on Launch"** shows **"Extra Variables"** as enabled
- The workflow template now accepts variables from API calls

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

After enabling extra variables, test by manually launching the workflow:

1. **Go to the workflow template**
2. **Click "Launch"**
3. **You should see an "Extra Variables" text box** (if prompt is enabled correctly)
4. **If you don't see the text box**, the setting wasn't saved properly

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

## 🎉 **Success Indicators**

✅ **Template List View**: Shows "Extra Variables" in "Prompt on Launch" column  
✅ **Manual Launch**: Shows extra variables text box  
✅ **API Launch**: Returns 201/202 instead of 400  
✅ **Workflow Execution**: Variables are passed to child job templates

Once this is configured correctly, your EDA webhook → trigger job → workflow launch sequence will work perfectly!
