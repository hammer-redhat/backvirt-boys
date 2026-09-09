# VM Disk Stress Testing Playbook

## Overview
The `vm-disk-stress.yml` playbook creates high disk usage by allocating a large file that fills up to 90% of the target filesystem. It includes automatic cleanup when cancelled or when the test completes.

## How It Works
1. **Analyzes** current filesystem usage on the target path
2. **Calculates** how much space needed to reach the target percentage (default 90%)
3. **Creates** a large file using `fallocate` (fast, doesn't write actual data)
4. **Waits** for the specified timeout duration
5. **Automatically cleans up** the stress file when done or cancelled

## Usage

### Basic Usage
```bash
ansible-playbook vm-memory/vm-disk-stress.yml -i inventory
```

### Custom Configuration
```bash
ansible-playbook vm-memory/vm-disk-stress.yml -i inventory \
  -e stress_disk_percentage=85 \
  -e stress_disk_path="/var" \
  -e stress_timeout="60m"
```

## Configuration Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `stress_disk_percentage` | 90 | Target filesystem usage percentage |
| `stress_disk_path` | "/tmp" | Target filesystem path to stress |
| `stress_file_name` | "stress_disk_test.img" | Name of the temporary stress file |
| `stress_timeout` | "30m" | How long to maintain disk stress |
| `cleanup_on_signal` | true | Enable automatic cleanup on cancellation |

## Example Scenarios

### 1. Test /tmp filesystem at 85% for 45 minutes
```bash
ansible-playbook vm-memory/vm-disk-stress.yml \
  -e stress_disk_percentage=85 \
  -e stress_timeout="45m"
```

### 2. Test /var filesystem at 95% for 2 hours
```bash
ansible-playbook vm-memory/vm-disk-stress.yml \
  -e stress_disk_path="/var" \
  -e stress_disk_percentage=95 \
  -e stress_timeout="120m"
```

### 3. Test root filesystem with custom file name
```bash
ansible-playbook vm-memory/vm-disk-stress.yml \
  -e stress_disk_path="/" \
  -e stress_file_name="root_disk_stress.test" \
  -e stress_timeout="15m"
```

## Safety Features

### ✅ **Automatic Cleanup**
- Stress file is automatically removed when:
  - Test completes normally
  - Job is cancelled (Ctrl+C)
  - Playbook encounters an error
  - System interruption occurs

### ✅ **Pre-flight Checks**
- Verifies sufficient space is available
- Prevents running if filesystem already at target percentage
- Validates calculated file sizes

### ✅ **Real-time Monitoring**
- Shows filesystem usage before and after
- Displays exact file sizes in human-readable format
- Provides clear status messages

## Integration with AAP

### Job Template Variables
When creating a Job Template in Ansible Automation Platform:

```yaml
stress_disk_percentage: 90
stress_disk_path: "/tmp" 
stress_timeout: "30m"
```

### EDA Integration Example
```yaml
# In your EDA rulebook for disk alerts
- name: Simulate High Disk Usage
  condition: event.payload.status == "testing"
  actions:
    - run_job_template:
        name: "Disk Stress Test"
        organization: "Default"
        job_args:
          extra_vars:
            stress_disk_percentage: 95
            stress_disk_path: "/var/log"
            stress_timeout: "60m"
```

## Troubleshooting

### Common Issues

1. **"Not enough space available"**
   - Reduce `stress_disk_percentage`
   - Choose a filesystem with more available space
   - Clean up existing files first

2. **"File size is negative or zero"**
   - Filesystem is already at or above target percentage
   - Lower `stress_disk_percentage` value
   - Check current disk usage with `df -h`

3. **Permission denied**
   - Ensure `become: true` is set
   - Check write permissions on target path
   - Verify sudo access for the ansible user

### Manual Cleanup (if needed)
```bash
# If stress file wasn't cleaned up automatically
sudo rm -f /tmp/stress_disk_test.img

# Check current disk usage
df -h /tmp
```

## Comparison with Memory Stress

| Feature | Memory Stress | Disk Stress |
|---------|---------------|-------------|
| **Tool** | stress-ng | fallocate |
| **Resource** | RAM | Disk Space |
| **Cleanup** | Automatic (process exit) | Manual (file removal) |
| **Impact** | System performance | Storage capacity |
| **Reversible** | Immediate | Requires cleanup |

## Best Practices

1. **Start Small**: Begin with lower percentages (70-80%) for testing
2. **Monitor Systems**: Watch for alerts and system behavior during stress
3. **Test Cleanup**: Verify automatic cleanup works in your environment  
4. **Use /tmp**: Default path is usually safe for testing
5. **Set Timeouts**: Always specify reasonable timeout durations
6. **Document Tests**: Record what scenarios you're testing and why

## Security Considerations

- **Temporary Files**: Stress files contain no sensitive data (allocated but not written)
- **Disk Space**: Could cause legitimate applications to fail if disk fills completely
- **Root Access**: Requires sudo privileges for file creation in system paths
- **Monitoring**: Should trigger disk space alerts in monitoring systems

This playbook is ideal for testing disk space monitoring, alerting systems, and application behavior under storage pressure conditions.
