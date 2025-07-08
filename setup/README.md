# Steps to Produce Base Environment

1. Install OpenShift GitOps Operator `oc apply -f 01-gitops-subscription.yaml` 
    * Optional: Enable Console Plugin `oc patch console.operator cluster -n openshift-storage --type json -p '[{"op": "add", "path": "/spec/plugins", "value": ["gitops-plugin"]}]'`
1. Install Application `oc apply -f 02-backstage-application.yaml`

# Steps to Unwind Base Environment

1. Remove Application
1. Remove console-plugin
1. Uninstall OpenShift GitOps Operator 
