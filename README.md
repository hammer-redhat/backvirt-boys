# BackVirt Boys - OpenShift Developer Environment Setup

This repository provides a GitOps-based automated deployment of a comprehensive OpenShift developer environment using ArgoCD. The setup includes multiple Red Hat developer tools and services configured for seamless integration.

## 🚀 Overview

The **BackVirt Boys** project deploys a complete developer environment with the following components:

- **🤖 Ansible Automation Platform (AAP) 2.5** - Automation controller and hub for infrastructure management
- **💻 Red Hat OpenShift Dev Spaces** - Cloud-native development environments
- **📦 NFS Storage Provisioner** - Persistent storage solution
- **🏠 Red Hat Developer Hub (RHDH)** - Developer portal and backstage interface

## 🏗️ Architecture

The deployment uses a GitOps approach with ArgoCD managing the entire lifecycle:

```
┌─────────────────────────────────────────────────────────────┐
│                    OpenShift GitOps (ArgoCD)               │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────────────────────┐ │
│  │   Operators     │    │     Custom Resources            │ │
│  │   Application   │───▶│     Application                 │ │
│  └─────────────────┘    └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
          │                              │
          ▼                              ▼
┌─────────────────┐              ┌─────────────────┐
│   AAP Operator  │              │   AAP Instance  │
│ DevSpaces Op.   │              │ DevSpaces Inst. │
│   NFS Operator  │              │   NFS Instance  │
│   RHDH Operator │              │   RHDH Instance │
└─────────────────┘              └─────────────────┘
```

## 📁 Repository Structure

```
backvirt-boys/
├── setup/                          # Main deployment configuration
│   ├── 01-gitops-subscription.yaml # OpenShift GitOps installation
│   ├── 02-operator-application.yaml # Operator deployment & RBAC
│   ├── 03-customresource-application.yaml # Custom resource deployment
│   ├── argocd/                     # ArgoCD application definitions
│   │   ├── operators/              # Operator subscriptions
│   │   │   ├── aap.yaml           # AAP operator
│   │   │   ├── devspaces.yaml     # Dev Spaces operator
│   │   │   ├── nfs.yaml           # NFS operator
│   │   │   └── rhdh.yaml          # RHDH operator
│   │   └── crs/                   # Custom resource definitions
│   │       ├── aap.yaml           # AAP instance configuration
│   │       ├── devspaces.yaml     # Dev Spaces configuration
│   │       ├── nfs.yaml           # NFS provisioner configuration
│   │       └── rhdh.yaml          # RHDH instance configuration
│   └── README.md                   # Setup documentation
└── operator_configs/               # Standalone operator configs
    ├── aap.yml                     # AAP standalone deployment
    └── devspaces.yml               # Dev Spaces standalone deployment
```

## 🚦 Quick Start

### Prerequisites

- OpenShift 4.12+ cluster with cluster-admin privileges
- `oc` CLI tool configured and authenticated
- Internet access for operator installations

### Deployment Steps

1. **Install OpenShift GitOps**
   ```bash
   oc apply -f setup/01-gitops-subscription.yaml
   ```

2. **Deploy Operators and RBAC**
   ```bash
   oc apply -f setup/02-operator-application.yaml
   ```

3. **Deploy Custom Resources**
   ```bash
   oc apply -f setup/03-customresource-application.yaml
   ```

4. **Monitor Deployment**
   ```bash
   # Check ArgoCD applications
   oc get applications -n openshift-gitops
   
   # Monitor operator installations
   oc get csv -A
   
   # Check custom resource status
   oc get ansibleautomationplatform -A
   oc get checlusters -A
   ```

## 🔧 Component Details

### Ansible Automation Platform (AAP)
- **Version**: 2.5 (cluster-scoped)
- **Namespace**: `ansible-automation-platform`
- **Components**: Controller, Hub (EDA and Lightspeed disabled)
- **Storage**: NFS for hub file storage
- **Features**: 
  - Automated subscription loading via post-sync hooks
  - Edge TLS termination
  - Standalone Redis mode

### Red Hat OpenShift Dev Spaces
- **Namespace**: `devspaces`
- **Features**:
  - Per-user workspace isolation
  - 30-minute inactivity timeout
  - Container build support with SCC
  - OAuth proxy integration
  - Metrics enabled

### NFS Storage Provisioner
- **Namespace**: `nfs`
- **Purpose**: Provides persistent storage for AAP Hub and other components
- **Configuration**: Managed via custom resource definitions

### Red Hat Developer Hub (RHDH)
- **Namespace**: `rhdh-operator`
- **Features**: Developer portal and backstage interface
- **RBAC**: Custom cluster role bindings for GitOps integration

## 🔐 Security & RBAC

The setup implements comprehensive RBAC with:

- **Namespace isolation** for each component
- **Service account permissions** for ArgoCD controller
- **Role-based access** for custom resource management
- **Cluster-level permissions** where required (RHDH)

## 🔄 GitOps Configuration

### ArgoCD Applications

The setup creates two main ArgoCD applications:

1. **operators** - Manages operator subscriptions and namespaces
2. **customresources** - Manages custom resource instances

Both applications are configured with:
- **Automatic sync** enabled
- **Self-healing** enabled
- **Pruning** enabled
- **Source**: `https://github.com/hammer-redhat/backvirt-boys`
- **Branch**: `jason-devel`

### Sync Policies

- **Automated deployment** with self-healing
- **Post-sync hooks** for configuration tasks
- **Proper dependency management** between operators and custom resources

## 🛠️ Troubleshooting

### Common Issues

1. **Operator Installation Failures**
   ```bash
   # Check operator status
   oc get csv -A
   # Check subscription status
   oc get subscriptions -A
   ```

2. **Custom Resource Deployment Issues**
   ```bash
   # Check custom resource status
   oc describe ansibleautomationplatform -n ansible-automation-platform
   oc describe checlusters -n devspaces
   ```

3. **ArgoCD Application Sync Issues**
   ```bash
   # Check application health
   oc get applications -n openshift-gitops
   # View application details
   oc describe application operators -n openshift-gitops
   ```

### Logs and Monitoring

- **ArgoCD UI**: Access via OpenShift console → ArgoCD
- **Operator logs**: Check individual operator pod logs
- **Custom resource events**: Use `oc describe` for detailed events

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test in a development environment
5. Submit a pull request

## 📄 License

This project is licensed under the [MIT License](LICENSE).

## 📞 Support

For issues and questions:
- Create an issue in this repository
- Contact the BackVirt Boys team
- Refer to Red Hat documentation for specific component issues

---

**Note**: This setup is designed for development and testing environments. For production deployments, additional security hardening and configuration may be required.