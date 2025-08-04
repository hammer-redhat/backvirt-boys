# VM Lifecycle Playbook Usage Guide

This guide shows different ways to use the variablized `vm_lifecycle.yml` playbook for managing VM operations.

## Overview

The `vm_lifecycle.yml` playbook has been enhanced to accept variables for flexible VM management. It supports:
- **Operations**: `start`, `stop`, `restart`
- **Target Selection**: By VM name(s) or label selectors
- **Multiple VMs**: Comma-separated names or label-based selection

## Prerequisites

Ensure you have OpenShift environment variables set:
```bash
export K8S_AUTH_HOST=$(oc whoami --show-server)
export K8S_AUTH_API_KEY=$(oc whoami --show-token)
export K8S_AUTH_VERIFY_SSL=false
```

## Usage Methods

### Method 1: Command Line Variables

**Single VM restart:**
```bash
ansible-playbook vm_lifecycle.yml \
  -e vm_operation="restart" \
  -e vm_name="hammer-test" \
  -e vm_namespace="vms-aap-day2"
```

**Multiple VMs by name:**
```bash
ansible-playbook vm_lifecycle.yml \
  -e vm_operation="stop" \
  -e vm_name="vm1,vm2,vm3" \
  -e vm_namespace="production"
```

**VMs by label selector:**
```bash
ansible-playbook vm_lifecycle.yml \
  -e vm_operation="start" \
  -e vm_name="" \
  -e vm_label="app=web,env=prod" \
  -e vm_namespace="production"
```

### Method 2: External Variables File

**Create a variables file:**
```bash
# Create vm_vars.yml
cat > vm_vars.yml << EOF
vm_operation: "restart"
vm_name: "hammer-test"
vm_namespace: "vms-aap-day2"
vm_label: ""
EOF
```

**Run with variables file:**
```bash
ansible-playbook vm_lifecycle.yml -e @vm_vars.yml
```

### Method 3: Using the Provided Template

**Use the provided template:**
```bash
# Edit vm_lifecycle_vars.yml with your values
ansible-playbook vm_lifecycle.yml -e @vm_lifecycle_vars.yml
```

## Variable Reference

| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `vm_operation` | Operation to perform | Yes | `restart`, `start`, `stop` |
| `vm_name` | VM name(s), comma-separated | Yes* | `"hammer-test"` or `"vm1,vm2,vm3"` |
| `vm_namespace` | OpenShift namespace | Yes | `"vms-aap-day2"` |
| `vm_label` | Label selector, comma-separated | No** | `"app=web,env=prod"` |

*Required unless using label selectors
**Alternative to vm_name for bulk operations

## Examples by Use Case

### Development Environment
```bash
# Restart development VMs
ansible-playbook vm_lifecycle.yml \
  -e vm_operation="restart" \
  -e vm_name="dev-app1,dev-app2" \
  -e vm_namespace="development"
```

### Production Maintenance
```bash
# Stop all production web servers
ansible-playbook vm_lifecycle.yml \
  -e vm_operation="stop" \
  -e vm_name="" \
  -e vm_label="app=web,env=production" \
  -e vm_namespace="production"
```

### Emergency Recovery
```bash
# Start all VMs in disaster recovery namespace
ansible-playbook vm_lifecycle.yml \
  -e vm_operation="start" \
  -e vm_name="" \
  -e vm_label="backup=true" \
  -e vm_namespace="disaster-recovery"
```

## Default Values

The playbook includes these defaults (can be overridden):
- `vm_operation`: `"restart"`
- `vm_name`: `"hammer-test"`
- `vm_namespace`: `"default"`
- `vm_label`: `""`

## Advanced Usage

### Dry Run
```bash
ansible-playbook vm_lifecycle.yml \
  -e @vm_lifecycle_vars.yml \
  --check
```

### Verbose Output
```bash
ansible-playbook vm_lifecycle.yml \
  -e vm_operation="restart" \
  -e vm_name="hammer-test" \
  -e vm_namespace="vms-aap-day2" \
  -vvv
```

### With Custom Inventory
```bash
ansible-playbook -i custom_inventory vm_lifecycle.yml \
  -e @vm_lifecycle_vars.yml
```

## Troubleshooting

### Common Issues

1. **Missing Environment Variables**
   ```bash
   # Check if variables are set
   echo "Host: $K8S_AUTH_HOST"
   echo "Token: ${K8S_AUTH_API_KEY:0:10}..."
   ```

2. **VM Not Found**
   - Verify VM name and namespace
   - Check if VM exists: `oc get vm -n <namespace>`

3. **Permission Errors**
   - Ensure your OpenShift user has VM management permissions
   - Verify namespace access

### Debug Commands
```bash
# List all VMs
oc get vm -A

# Check specific VM
oc get vm hammer-test -n vms-aap-day2 -o yaml

# Check VMI status
oc get vmi hammer-test -n vms-aap-day2
```

## Integration with CI/CD

### GitLab CI Example
```yaml
restart_vms:
  script:
    - export K8S_AUTH_HOST=$OPENSHIFT_SERVER
    - export K8S_AUTH_API_KEY=$OPENSHIFT_TOKEN
    - ansible-playbook vm_lifecycle.yml -e @production_vms.yml
```

### Jenkins Pipeline Example
```groovy
stage('Restart VMs') {
    steps {
        withCredentials([string(credentialsId: 'openshift-token', variable: 'K8S_AUTH_API_KEY')]) {
            sh '''
                export K8S_AUTH_HOST=https://api.cluster.example.com:6443
                ansible-playbook vm_lifecycle.yml -e vm_operation=restart -e vm_name=prod-app
            '''
        }
    }
}
```

## Best Practices

1. **Use Variables Files**: Store common configurations in files for reusability
2. **Test First**: Always use `--check` mode in production environments
3. **Label Strategy**: Use consistent labeling for bulk operations
4. **Documentation**: Document your VM naming and labeling conventions
5. **Access Control**: Implement proper RBAC in OpenShift for VM operations
6. **Monitoring**: Monitor VM states after operations to ensure success

## Files Reference

- `vm_lifecycle.yml` - Main playbook
- `vm_lifecycle_vars.yml` - Variables template
- `vars.yml` - Role default variables
- `VM_LIFECYCLE_USAGE.md` - This documentation