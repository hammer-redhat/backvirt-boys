# Git Repository Creation Playbook

This Ansible playbook automates the creation and initialization of git repositories with proper configuration and initial files.

## Features

- ✅ Creates new git repository directory
- ✅ Initializes git repository
- ✅ Sets up local git user configuration
- ✅ Creates initial files (README.md, .gitignore, and example script)
- ✅ Makes initial commit
- ✅ Optionally adds remote origin
- ✅ **NEW: Pushes initial commit to remote repository**
- ✅ **NEW: Sets default branch (main/master)**
- ✅ **NEW: Creates and pushes development branch (optional)**
- ✅ **NEW: Automatic branch management**
- ✅ Displays repository information and status

## Prerequisites

- Ansible installed on your system
- Git installed and accessible via command line
- Write permissions to the target directory
- **NEW: Git authentication configured for remote repositories** (SSH keys, tokens, or credentials)
- **NEW: Remote repository must exist** (GitHub, GitLab, etc.) if using remote_origin_url

## Authentication Setup

When using remote repositories, you'll need to configure authentication:

### SSH Authentication (Recommended)
```bash
# Generate SSH key if you don't have one
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add your SSH key to your Git provider (GitHub/GitLab)
cat ~/.ssh/id_ed25519.pub
```

### Token Authentication
```bash
# For HTTPS URLs, configure git to use your personal access token
git config --global credential.helper store
```

### Using SSH URLs
Update your variables file to use SSH URLs:
```yaml
remote_origin_url: "git@github.com:hammer-redhat/{{ repo_name }}.git"
```

## Usage

### Basic Usage

Run the playbook with default settings:

```bash
ansible-playbook create-git-repo.yml
```

### Using Custom Variables

1. **Edit the variables file** (`git-repo-vars.yml`):
   ```yaml
   repo_name: "my-new-project"
   git_user_name: "John Doe"
   git_user_email: "john.doe@example.com"
   remote_origin_url: "https://github.com/johndoe/my-new-project.git"
   ```

2. **Run with custom variables**:
   ```bash
   ansible-playbook create-git-repo.yml -e @git-repo-vars.yml
   ```

### Command Line Variable Override

You can override variables directly from the command line:

```bash
ansible-playbook create-git-repo.yml \
  -e "repo_name=my-special-repo" \
  -e "git_user_name='Jane Smith'" \
  -e "git_user_email=jane@example.com" \
  -e "remote_origin_url=https://github.com/jane/my-special-repo.git"
```

### Advanced Usage

#### Create Repository Without Initial Files

```bash
ansible-playbook create-git-repo.yml -e "create_initial_files=false"
```

#### Specify Custom Repository Path

```bash
ansible-playbook create-git-repo.yml \
  -e "repo_name=my-repo" \
  -e "repo_path=/path/to/custom/location/my-repo"
```

#### Set Custom Initial Commit Message

```bash
ansible-playbook create-git-repo.yml \
  -e "initial_commit_message='🎉 Project initialization with Ansible'"
```

## Configuration Options

### Required Variables

- `repo_name`: Name of the repository (default: "my-new-repo")
- `repo_path`: Full path where repository will be created
- `git_user_name`: Git user name for commits
- `git_user_email`: Git user email for commits

### Optional Variables

- `create_initial_files`: Create README, .gitignore, and example files (default: true)
- `initial_commit_message`: Message for the initial commit
- `remote_origin_url`: URL of remote repository to add as origin
- **NEW: `git_default_branch`**: Default branch name (default: "main")
- **NEW: `create_development_branch`**: Create and push development branch (default: false)
- **NEW: `development_branch_name`**: Name of development branch (default: "develop")

## Generated Files

When `create_initial_files` is true, the playbook creates:

1. **README.md** - Basic project documentation template
2. **.gitignore** - Comprehensive gitignore file for common artifacts
3. **hello.py** - Example Python script (optional, can be disabled)

## Branch Management

The playbook now supports automatic branch management:

- **Main Branch**: Sets up and pushes to your default branch (main/master)
- **Development Branch**: Optionally creates and pushes a development branch
- **Automatic Switching**: Returns to main branch after development branch creation

## Remote Repository Features

### Push to Remote
- Automatically pushes initial commit to remote repository
- Sets up upstream tracking for branches
- Handles authentication errors gracefully

### Branch Creation
- Creates development branch if enabled
- Pushes development branch to remote
- Maintains clean branch structure

## Example Output

```
PLAY [Create and Initialize Git Repository] ***********************************

TASK [Check if git is installed] **********************************************
ok: [localhost]

TASK [Display git version] ****************************************************
ok: [localhost] => {
    "msg": "Git version: git version 2.39.0"
}

TASK [Create repository directory] ********************************************
changed: [localhost]

TASK [Initialize git repository] **********************************************
changed: [localhost]

TASK [Set git user name] ******************************************************
changed: [localhost]

TASK [Set git user email] *****************************************************
changed: [localhost]

TASK [Create initial files] ***************************************************
changed: [localhost]

TASK [Add files to git staging] ***********************************************
changed: [localhost]

TASK [Create initial commit] **************************************************
changed: [localhost]

TASK [Display repository information] *****************************************
ok: [localhost] => {
    "msg": [
        "Repository created successfully!",
        "Location: /home/user/my-new-repo",
        "Repository name: my-new-repo",
        "Git user: user <user@example.com>",
        "Initial files created: True",
        "Remote origin: Not set"
    ]
}
```

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure you have write permissions to the target directory
2. **Git Not Found**: Install git or ensure it's in your PATH
3. **Repository Already Exists**: The playbook will skip initialization if the directory already contains a git repository
4. **NEW: Authentication Failed**: Configure SSH keys or personal access tokens for remote repositories
5. **NEW: Remote Repository Not Found**: Ensure the remote repository exists on GitHub/GitLab
6. **NEW: Push Rejected**: Check if the remote repository has conflicting commits or branch protection rules

### Git Push Troubleshooting

#### Authentication Issues
```bash
# Test SSH connection
ssh -T git@github.com

# For HTTPS, check if credentials are stored
git config --global credential.helper

# Reset stored credentials if needed
git config --global --unset credential.helper
```

#### Remote Repository Issues
```bash
# Check remote URL
git remote -v

# Test if remote repository exists
git ls-remote origin

# Verify branch exists on remote
git branch -r
```

#### Branch Protection
If your repository has branch protection rules:
- Create the repository without protection initially
- Or use a different branch name for the initial push
- Configure protection rules after the initial setup

### Verification

After running the playbook, verify the repository:

```bash
cd ~/my-new-repo  # or your custom path
git status
git log --oneline
ls -la
```

## Integration with AAP

To run this playbook in Ansible Automation Platform:

1. Create a project pointing to your repository
2. Create a job template using this playbook
3. Set the variables in the job template or survey
4. Run the job template

## License

This playbook is provided as-is for educational and automation purposes. 