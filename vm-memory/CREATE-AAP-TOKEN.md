# Creating AAP OAuth Token for API Access

This guide explains how to create an OAuth token in AAP for the workflow trigger job.

## 🔐 Method 1: Create Personal Access Token (Recommended)

### Step 1: Login to AAP Web Interface
1. Navigate to your AAP controller URL (e.g., `http://aap.aap`)
2. Login with your admin credentials

### Step 2: Create Personal Access Token
1. Click on your **username** in the top right corner
2. Select **"Personal Access Tokens"** from the dropdown
3. Click **"+ Add"** button
4. Fill in the form:
   - **Name**: `EDA Workflow Trigger Token`
   - **Description**: `Token for EDA to trigger VM scaling workflows`
   - **Application**: Leave blank (for personal token)
   - **Scope**: Select **"Write"** (required for launching jobs)
5. Click **"Save"**

### Step 3: Copy the Token
⚠️ **IMPORTANT**: The token will only be displayed **ONCE**. Copy it immediately!

```
Example token: ABC123def456ghi789jkl012mno345pqr678stu901vwx234yz
```

## 🔐 Method 2: Create Application Token (Advanced)

### Step 1: Create Application
1. Go to **Administration** → **Applications**
2. Click **"+ Add"**
3. Fill in:
   - **Name**: `EDA Workflow Application`
   - **Organization**: `Default`
   - **Authorization Grant Type**: `Authorization code`
   - **Client Type**: `Confidential`
4. Click **"Save"** and note the **Client ID** and **Client Secret**

### Step 2: Create Application Token
1. Go to **Administration** → **Applications**
2. Click on your application
3. Go to **"Tokens"** tab
4. Click **"+ Add"**
5. Fill in:
   - **User**: Select the user (e.g., admin)
   - **Scope**: `write`
6. Click **"Save"** and copy the token

## 🎯 Using the Token in AAP Job Template

### Option A: Environment Variables
Set these in your "Trigger VM Scaling Workflow" job template:

```bash
CONTROLLER_HOST=http://aap.aap
CONTROLLER_OAUTH_TOKEN=your-token-here
CONTROLLER_VERIFY_SSL=false
```

### Option B: Custom Credential Type
1. Go to **Administration** → **Credential Types**
2. Click **"+ Add"**
3. Create credential type:

**Input Configuration:**
```yaml
fields:
  - id: controller_host
    type: string
    label: Controller Host
    help_text: AAP Controller URL (e.g., https://aap.example.com)
  - id: oauth_token
    type: string
    label: OAuth Token
    secret: true
    help_text: AAP OAuth Token for API access
  - id: verify_ssl
    type: boolean
    label: Verify SSL
    help_text: Verify SSL certificates
    default: false
required:
  - controller_host
  - oauth_token
```

**Injector Configuration:**
```yaml
env:
  CONTROLLER_HOST: '{{ controller_host }}'
  CONTROLLER_OAUTH_TOKEN: '{{ oauth_token }}'
  CONTROLLER_VERIFY_SSL: '{{ verify_ssl }}'
```

4. Create credential using this type and attach to job template

## 🔍 Testing the Token

You can test your token using curl:

```bash
curl -H "Authorization: Bearer YOUR_TOKEN_HERE" \
     -H "Content-Type: application/json" \
     http://aap.aap/api/controller/v2/workflow_job_templates/
```

Expected response: JSON list of workflow templates

## ⚠️ Token Security Best Practices

1. **Store securely**: Use AAP credentials or environment variables, never hardcode
2. **Rotate regularly**: Create new tokens periodically and delete old ones
3. **Minimal scope**: Use the minimum required scope (`write` for launching jobs)
4. **Monitor usage**: Check token activity in AAP logs
5. **Revoke when done**: Delete tokens that are no longer needed

## 🚨 Troubleshooting

### "Bearer token not supported" Error
- Ensure you're using a valid OAuth token
- Check that the token hasn't expired
- Verify the token has `write` scope

### "Authentication failed" Error
- Verify the token is correctly set in environment variables
- Check that `CONTROLLER_HOST` doesn't include `/api/` paths
- Ensure `Authorization: Bearer` header format is correct

### "Permission denied" Error
- Token user must have permission to launch workflow templates
- Check organization membership and RBAC settings
- Verify the workflow template exists and is accessible

## 📋 Environment Variable Summary

For the **"Trigger VM Scaling Workflow"** job template, set:

```bash
# Required
CONTROLLER_HOST=http://aap.aap
CONTROLLER_OAUTH_TOKEN=your-oauth-token-here

# Optional
CONTROLLER_VERIFY_SSL=false
CONTROLLER_USERNAME=admin  # Fallback if token fails
CONTROLLER_PASSWORD=password  # Fallback if token fails
```

The playbook will automatically use token authentication if available, falling back to username/password if needed.
