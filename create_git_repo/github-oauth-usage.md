# GitHub OAuth Repository Creation Playbook

This Ansible playbook creates GitHub repositories using OAuth authentication and then initializes them locally with git. It combines GitHub API calls with local git operations for a complete repository setup experience.

## 🔑 OAuth Setup and Authentication

### Step 1: Generate a GitHub Personal Access Token

1. **Navigate to GitHub Token Settings**:
   - Go to [GitHub Settings > Developer settings > Personal access tokens](https://github.com/settings/tokens)
   - Or visit: `https://github.com/settings/tokens`

2. **Generate New Token**:
   - Click "Generate new token (classic)"
   - Give it a descriptive name (e.g., "Ansible Repository Creator")
   - Set expiration date (recommended: 90 days for security)

3. **Select Required Scopes**:
   
   **For Public Repositories:**
   - ✅ `public_repo` - Access to public repositories
   
   **For Private Repositories:**
   - ✅ `repo` - Full control of private repositories (includes public_repo)
   
   **Optional but Recommended:**
   - ✅ `user` - Read user profile data
   - ✅ `user:email` - Read user email addresses
   - ✅ `delete_repo` - Delete repositories (if needed)

4. **Generate and Save Token**:
   - Click "Generate token"
   - **⚠️ IMPORTANT**: Copy the token immediately - you won't see it again!

### Step 2: Secure Token Storage

**Option 1: Environment Variable (Recommended)**
```bash
export GITHUB_TOKEN="your_token_here"
```

**Option 2: Ansible Vault (Most Secure)**
```bash
# Create encrypted vault file
ansible-vault create github-secrets.yml

# Add to vault file:
github_token: "your_token_here"
```

**Option 3: Direct in Variables File (Not Recommended for Production)**
```yaml
github_token: "your_token_here"
```

## 🚀 Features

- ✅ **OAuth Authentication** - Uses GitHub Personal Access Tokens
- ✅ **Repository Creation** - Creates repositories via GitHub API
- ✅ **Repository Configuration** - Sets description, privacy, features
- ✅ **Duplicate Detection** - Checks if repository already exists
- ✅ **Local Initialization** - Initializes local git repository
- ✅ **Initial Files** - Creates README.md and .gitignore
- ✅ **Branch Management** - Creates main and development branches
- ✅ **Auto Push** - Pushes initial commit to GitHub
- ✅ **SSH/HTTPS Support** - Configurable connection method
- ✅ **Error Handling** - Graceful error handling and reporting

## 📋 Prerequisites

- Ansible installed on your system
- Git installed and accessible via command line
- GitHub account with appropriate permissions
- Valid GitHub Personal Access Token with required scopes
- SSH keys configured (if using SSH URLs)

## 🔧 Usage

### Basic Usage with Environment Variable

```bash
# Set your GitHub token
export GITHUB_TOKEN="ghp_your_token_here"

# Run the playbook
ansible-playbook create-github-repo-oauth.yml -e @github-oauth-vars.yml -e "github_token=${GITHUB_TOKEN}"
```

### Using Ansible Vault (Most Secure)

```bash
# Create vault file (one-time setup)
ansible-vault create github-secrets.yml

# Run playbook with vault
ansible-playbook create-github-repo-oauth.yml -e @github-oauth-vars.yml -e @github-secrets.yml --ask-vault-pass
```

### Command Line Variable Override

```bash
ansible-playbook create-github-repo-oauth.yml \
  -e "github_username=your-username" \
  -e "github_token=your-token" \
  -e "repo_name=my-new-project" \
  -e "create_private_repo=true" \
  -e "repo_description='My awesome project'"
```

## ⚙️ Configuration Options

### Required Variables

- `github_username`: Your GitHub username
- `github_token`: Your GitHub Personal Access Token
- `repo_name`: Name of the repository to create
- `git_user_name`: Git user name for commits
- `git_user_email`: Git user email for commits
- `repo_path`: Local path where repository will be created

### Repository Settings

- `create_private_repo`: Create private repository (default: false)
- `repo_description`: Repository description
- `enable_issues`: Enable GitHub Issues (default: true)
- `enable_projects`: Enable GitHub Projects (default: true)
- `enable_wiki`: Enable GitHub Wiki (default: true)
- `auto_init`: Let GitHub initialize repository (default: false)

### Connection Settings

- `use_ssh_url`: Use SSH URLs instead of HTTPS (default: true)
- `github_api_url`: GitHub API URL (default: https://api.github.com)

### Branch Configuration

- `git_default_branch`: Default branch name (default: "main")
- `create_development_branch`: Create development branch (default: true)
- `development_branch_name`: Development branch name (default: "develop")

## 📊 OAuth Scopes Reference

Based on [GitHub's OAuth Scopes Documentation](https://docs.github.com/enterprise/2.11/developer/apps/building-oauth-apps/understanding-scopes-for-oauth-apps/):

### Repository Scopes
- `repo` - Full access to private repositories
- `public_repo` - Access to public repositories only
- `delete_repo` - Delete repositories

### User Scopes
- `user` - Read user profile data
- `user:email` - Read user email addresses

### Organization Scopes
- `admin:org` - Full control of orgs and teams
- `read:org` - Read org and team membership

### Other Useful Scopes
- `admin:repo_hook` - Full control of repository hooks
- `admin:public_key` - Full control of user public keys

## 🔍 Example Output

```
PLAY [Create GitHub Repository with OAuth and Initialize Locally] *************

TASK [Validate required variables] ********************************************
ok: [localhost] => (item=repo_name)
ok: [localhost] => (item=github_oauth_token)
ok: [localhost] => (item=git_user_name)
ok: [localhost] => (item=git_user_email)

TASK [Display OAuth scopes information] ***************************************
ok: [localhost] => {
    "msg": [
        "Creating repository with OAuth authentication",
        "Required scopes: repo (for private repos) or public_repo (for public repos)",
        "Repository: cursor-test-project",
        "Private: False"
    ]
}

TASK [Check if repository already exists] *************************************
ok: [localhost]

TASK [Create GitHub repository via OAuth] *************************************
changed: [localhost]

TASK [Display created repository information] *********************************
ok: [localhost] => {
    "msg": [
        "✅ Repository created successfully!",
        "Repository URL: https://github.com/hammer-redhat/cursor-test-project",
        "Clone URL (HTTPS): https://github.com/hammer-redhat/cursor-test-project.git",
        "Clone URL (SSH): git@github.com:hammer-redhat/cursor-test-project.git",
        "Private: False"
    ]
}

TASK [Final repository summary] ***********************************************
ok: [localhost] => {
    "msg": [
        "🎉 Repository setup completed successfully!",
        "GitHub Repository: https://github.com/hammer-redhat/cursor-test-project",
        "Local Path: /home/user/cursor-test-project",
        "Repository Name: cursor-test-project",
        "Git User: user <user@redhat.com>",
        "Private Repository: False",
        "Default Branch: main",
        "Development Branch: Created",
        "Push Status: Success",
        "Remote URL: git@github.com:hammer-redhat/cursor-test-project.git"
    ]
}
```

## 🛠️ Troubleshooting

### Authentication Issues

#### Invalid Token
```
Error: 401 Unauthorized
```
**Solution**: Verify your token is correct and has the required scopes.

#### Insufficient Scopes
```
Error: 403 Forbidden
```
**Solution**: Check your token has the required scopes (`repo` or `public_repo`).

#### Expired Token
```
Error: 401 Unauthorized
```
**Solution**: Generate a new token with the same scopes.

### Repository Issues

#### Repository Already Exists
```
Error: 422 Unprocessable Entity
```
**Solution**: The playbook handles this gracefully and will use the existing repository.

#### Name Conflicts
```
Error: Name already exists on this account
```
**Solution**: Choose a different repository name.

### Network Issues

#### API Rate Limiting
```
Error: 403 rate limit exceeded
```
**Solution**: Wait for rate limit reset or use authenticated requests (tokens have higher limits).

#### Connection Timeout
```
Error: Connection timeout
```
**Solution**: Check your internet connection and GitHub status.

### Git Push Issues

#### SSH Key Not Configured
```
Error: Permission denied (publickey)
```
**Solution**: 
1. Generate SSH key: `ssh-keygen -t ed25519 -C "your_email@example.com"`
2. Add to GitHub: Settings > SSH and GPG keys
3. Test connection: `ssh -T git@github.com`

#### HTTPS Authentication
```
Error: Authentication failed
```
**Solution**: Use SSH URLs or configure Git credential helper.

### Verification Commands

```bash
# Test GitHub API access
curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user

# Test repository creation
curl -H "Authorization: token YOUR_TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     https://api.github.com/user/repos \
     -d '{"name":"test-repo"}'

# Test SSH connection
ssh -T git@github.com

# Check local repository
cd ~/cursor-test-project
git status
git remote -v
```

## 🔒 Security Best Practices

1. **Token Security**:
   - Use environment variables or Ansible Vault
   - Never commit tokens to version control
   - Set appropriate token expiration dates
   - Use minimum required scopes

2. **Repository Security**:
   - Review repository settings after creation
   - Set up branch protection rules
   - Enable security features (vulnerability alerts, etc.)

3. **Local Security**:
   - Use SSH keys for authentication
   - Keep your git configuration secure
   - Regularly audit repository access

## 📝 Integration with AAP

To run this playbook in Ansible Automation Platform:

1. **Create Project**: Point to your repository containing the playbook
2. **Create Credential**: Custom credential type for GitHub token
3. **Create Job Template**: Use the playbook with appropriate variables
4. **Set Survey**: Create survey for dynamic repository creation
5. **Run Job**: Execute with proper token and variables

## 🔄 Workflow Integration

This playbook can be integrated into larger automation workflows:

1. **CI/CD Pipeline**: Automatically create repositories for new projects
2. **Project Onboarding**: Part of new project setup automation
3. **Infrastructure as Code**: Manage repository creation alongside other resources
4. **Team Workflows**: Standardize repository creation process

## 📚 Additional Resources

- [GitHub REST API Documentation](https://docs.github.com/en/rest)
- [GitHub OAuth Apps Documentation](https://docs.github.com/en/developers/apps/building-oauth-apps)
- [GitHub Personal Access Tokens Guide](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [Ansible URI Module Documentation](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/uri_module.html) 