# AAP Job Template for VM Creation

This directory contains Ansible playbooks for creating and managing AAP (Ansible Automation Platform) job templates that create virtual machines on OpenShift Virtualization.

## Files

- `create_vm.yml` - Original playbook that creates VMs on OpenShift Virtualization
- `create_job_template.yml` - Creates an AAP job template for VM creation
- `launch_vm_creation.yml` - Launches the VM creation job template
- `aap_vars.yml` - Configuration variables template
- `delete_vm.yml` - Deletes VMs (existing)

## Prerequisites

1. **AAP Controller Access**: You need access to an AAP Controller instance
2. **Ansible Collections**: Install the required collections:
   ```bash
   ansible-galaxy collection install ansible.controller
   ansible-galaxy collection install redhat.openshift_virtualization
   ```
3. **Credentials**: Set up proper credentials in AAP for OpenShift access
4. **Project**: Your code repository should be configured as a project in AAP

## Setup Instructions

### 1. Configure Variables

Copy and customize the variables file:
```bash
cp aap_vars.yml my_aap_vars.yml
# Edit my_aap_vars.yml with your actual AAP controller details
```

### 2. Set AAP Password

Use one of these methods to provide the AAP controller password:

**Option A: Environment Variable**
```bash
export AAP_CONTROLLER_PASSWORD="your-password"
```

**Option B: Ansible Vault**
```bash
ansible-vault create vault.yml
# Add: aap_controller_password: "your-password"
```

**Option C: Prompt**
```bash
ansible-playbook -e @my_aap_vars.yml --ask-vault-pass create_job_template.yml
```

### 3. Create the Job Template

```bash
ansible-playbook -e @my_aap_vars.yml create_job_template.yml
```

This will:
- Create a job template in AAP called "Create VM on OpenShift Virtualization"
- Configure a survey for user input (VM name, namespace, etc.)
- Set up proper defaults and validation
- Create a localhost inventory if needed

### 4. Launch Jobs

**Option A: Through AAP Web Interface**
1. Navigate to Templates in AAP
2. Find "Create VM on OpenShift Virtualization"
3. Click the rocket icon to launch
4. Fill out the survey form

**Option B: Programmatically**
```bash
ansible-playbook -e @my_aap_vars.yml \
  -e vm_name="my-test-vm" \
  -e vm_namespace="vms" \
  launch_vm_creation.yml
```

## Job Template Survey Parameters

The job template includes a survey with these parameters:

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| VM Name | Text | Name for the virtual machine | my-vm |
| VM Namespace | Text | OpenShift namespace | default |
| VM State | Choice | present/absent | present |
| VM Label | Text | Application label | my-app |
| Instance Type | Choice | VM size (u1.micro to u1.xlarge) | u1.medium |
| VM Preference | Choice | OS preference | fedora |
| DataVolume Template Name | Text | Name for DataVolume | vm-datavolume |

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Verify AAP controller credentials
   - Check network connectivity to AAP controller
   - Ensure SSL certificate validation settings

2. **Missing Resources**
   - Ensure the project exists in AAP
   - Verify inventory and credentials are configured
   - Check that the playbook path is correct

3. **Permission Errors**
   - Verify user has permissions to create job templates
   - Check OpenShift credentials have proper RBAC

### Debugging

Enable verbose output:
```bash
ansible-playbook -vvv -e @my_aap_vars.yml create_job_template.yml
```

Check job template in AAP:
```bash
ansible-playbook -e @my_aap_vars.yml \
  -e job_template_name="Create VM on OpenShift Virtualization" \
  -m ansible.controller.job_template \
  -a "controller_host={{ aap_controller_host }} state=present" \
  localhost
```

## Security Considerations

- Store passwords in Ansible Vault or environment variables
- Use proper SSL certificate validation in production
- Implement proper RBAC in both AAP and OpenShift
- Consider using AAP's credential management for OpenShift access

## Customization

### Adding New Survey Questions

Edit the `survey_spec` section in `create_job_template.yml`:

```yaml
- question_name: "Custom Parameter"
  question_description: "Description of the parameter"
  required: true
  type: "text"  # or "multiplechoice", "multiselect", "integer", "float"
  variable: "custom_param"
  default: "default_value"
```

### Modifying VM Defaults

Update the `vm_variables` section in `create_job_template.yml` or override in your variables file.

### Additional Job Settings

Modify the job template configuration in the `ansible.controller.job_template` task to add features like:
- Webhooks
- Notifications
- Labels
- Instance groups
- Execution environments