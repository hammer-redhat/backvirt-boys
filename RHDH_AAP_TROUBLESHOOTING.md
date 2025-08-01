# Red Hat Developer Hub AAP Entity Provider Troubleshooting

## Issue Description

Red Hat Developer Hub fails to start with the following error:

```
ForwardedError [InputError]: Module 'rhaap' for plugin 'catalog' startup failed; caused by InputError: No schedule provided via config for AapResourceEntityProvider:production.
```

## Root Cause

The AAP (Ansible Automation Platform) entity provider requires a schedule configuration to periodically sync resources from AAP into the RHDH catalog. This schedule configuration was missing from the RHDH app-config.

## Solution

### 1. Add Schedule Configuration to RHDH App Config

The AAP entity provider needs a schedule configuration under `catalog.providers.rhaap.production.schedule` in the app-config.yaml:

```yaml
catalog:
  providers:
    rhaap:
      production:
        schedule:
          frequency: { minutes: 30 }    # Sync every 30 minutes
          timeout: { minutes: 3 }       # Timeout after 3 minutes
          initialDelay: { seconds: 15 }  # Wait 15 seconds before first sync
```

### 2. Configuration Options

The schedule configuration supports the same options as TaskScheduleDefinition:

- **frequency**: How often to sync (supports cron, ISO duration, or "human duration")
  - Examples: `{ minutes: 30 }`, `{ hours: 1 }`, `"0 */30 * * * ?"` (cron)
- **timeout**: Maximum time to wait for sync completion
  - Examples: `{ minutes: 3 }`, `{ seconds: 180 }`
- **initialDelay**: Delay before first sync starts
  - Examples: `{ seconds: 15 }`, `{ minutes: 1 }`

### 3. Example Configurations

#### Basic Configuration (Recommended)
```yaml
catalog:
  providers:
    rhaap:
      production:
        schedule:
          frequency: { minutes: 30 }
          timeout: { minutes: 3 }
          initialDelay: { seconds: 15 }
```

#### High-Frequency Configuration
```yaml
catalog:
  providers:
    rhaap:
      production:
        schedule:
          frequency: { minutes: 5 }
          timeout: { minutes: 1 }
          initialDelay: { seconds: 10 }
```

#### Cron-Based Configuration
```yaml
catalog:
  providers:
    rhaap:
      production:
        schedule:
          frequency: "0 */15 * * * ?"  # Every 15 minutes
          timeout: { minutes: 2 }
          initialDelay: { seconds: 30 }
```

## Implementation Steps

### For ArgoCD Deployment

1. Edit the RHDH ConfigMap in `setup/argocd/crs/rhdh.yaml`
2. Add the schedule configuration to the `app-config-rhdh.yaml` data
3. Apply the changes using ArgoCD or kubectl

### For Direct Kubernetes Deployment

1. Edit your RHDH ConfigMap:
```bash
kubectl edit configmap app-config-rhdh -n rhdh-operator
```

2. Add the schedule configuration under the `catalog.providers.rhaap.production` section

3. Restart the RHDH deployment:
```bash
kubectl rollout restart deployment/backstage-developer-hub -n rhdh-operator
```

## Verification

After applying the fix:

1. Check RHDH pod logs for successful startup:
```bash
kubectl logs -f deployment/backstage-developer-hub -n rhdh-operator
```

2. Look for successful plugin initialization messages:
```
Plugin initialization completed successfully
```

3. Verify the AAP entity provider is running without errors:
```bash
kubectl logs -f deployment/backstage-developer-hub -n rhdh-operator | grep -i "aap\|rhaap"
```

## Additional AAP Configuration

For a complete AAP integration, you may also need:

```yaml
ansible:
  rhaap:
    baseUrl: 'https://your-aap-controller-url'
    token: 'your-aap-token'
    checkSSL: true
    showCaseLocation:
      type: file
      target: '/tmp/aap-showcases/'
```

## Related Documentation

- [Red Hat Developer Hub Administration Guide](https://docs.redhat.com/en/documentation/red_hat_developer_hub/)
- [Ansible Automation Platform Integration](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.5/html/installing_ansible_plug-ins_for_red_hat_developer_hub/)
- [Backstage Entity Providers](https://backstage.io/docs/features/software-catalog/configuration/)

## Troubleshooting Tips

1. **Validate YAML Syntax**: Ensure proper indentation and syntax in your ConfigMap
2. **Check Namespace**: Verify the ConfigMap is in the correct namespace
3. **Restart Required**: Always restart RHDH deployment after ConfigMap changes
4. **Monitor Logs**: Watch the logs during startup for any configuration errors
5. **Test Connectivity**: Ensure RHDH can reach your AAP instance if configured 