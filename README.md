# argocd-gitops-tpl-library

[Compatibility](https://github.com/grootan-devops/ai-skills/blob/main/COMPATIBILITY.md) · [Security](./SECURITY.md) · [Reporting policy](./CONTRIBUTING.md)

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![Type: library](https://img.shields.io/badge/Type-library-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)

Helm tpl library for gitops repo

## 1. Quick Start & Consumption

To use this library in your GitOps repository, declare it as a Helm dependency in `Chart.yaml`:

```console
# Login to OCI Registry
helm registry login registry.contoso.com --username <registry-username> --password <registry-token>
```

```yaml
# Chart.yaml
apiVersion: v2
name: <product-prefix>
version: 1.0.0
type: application
dependencies:
  - name: argocd-gitops-tpl-library
    version: 1.0.0
    repository: oci://registry.contoso.com/helm
```

Execute `helm dependency build` to download the library into your `charts/` directory.

---

## 2. Architecture: The ArgoCD App-of-Apps Pattern

This library powers enterprise GitOps repositories by implementing an automated, multi-tiered **App-of-Apps architecture**. A single root bootstrap application triggers ArgoCD to continuously synchronize all Helm microservices and raw manifest stacks declared in the repository.

```
+-----------------------------------------------------------------------+
|                Root Bootstrap Application                             |
|          <product-prefix>-<environment>-root                          |
|         (e.g., acme-cloud-myapp-dev-root)                         |
+-----------------------------------+-----------------------------------+
                                    |
          +-------------------------+-------------------------+
          |                                                   |
          v                                                   v
+------------------------------------+   +------------------------------------+
|     Helm Microservices Apps        |   |      Extras Parent App             |
|       (templates/apps.yaml)        |   |   <product-prefix>-extras-<env>    |
+------------------------------------+   | (e.g. acme-cloud-myapp-extras) |
| • <product>-<app1>-<env>           |   +-----------------+------------------+
| • <product>-<group>-<app2>-<env>   |                     |
| • <product>-<group>-<app3>-<env>   |                     v
+------------------------------------+   +------------------------------------+
                                         |    Raw Manifest Applications       |
                                         |  (extras/templates/manifest.yaml)  |
                                         +------------------------------------+
                                         | • <product>-extras-<env>-<manifest1>
                                         | • <product>-extras-<env>-<manifest2>
                                         | • <product>-extras-<env>-<manifest3>
                                         +------------------------------------+
```

---

## 3. The Critical Role of `Chart.yaml` in Application Naming

In this architecture, `Chart.yaml` is the **canonical source of identity** for your entire cluster stack:

1. **Product Prefix (`.Chart.Name`)**:
   The `name` field in `Chart.yaml` establishes the global prefix for every Kubernetes and ArgoCD resource (e.g., `acme-cloud-myapp`).
2. **Unified Naming Across Stacks**:
   Both the root chart and the `extras/` chart must define the **exact same `name`** in their respective `Chart.yaml` files.
   - **Root `Chart.yaml`**: `name: acme-cloud-myapp`
   - **`extras/Chart.yaml`**: `name: acme-cloud-myapp` (Do NOT append `-extras-dev`!)

### Naming Resolution Matrix

| Application Level | Source / Invocation | Naming Formula | Concrete Example |
|---|---|---|---|
| **Root App-of-Apps** | Bootstrap Manifest | `<Chart.Name>-<environment>-root` | `acme-cloud-myapp-dev-root` |
| **Standalone Helm App** | `apps.<name>` | `<Chart.Name>-<displayName>-<environment>` | `acme-cloud-myapp-notification-dev` |
| **Grouped Helm App** | `apps.<group>.<name>` | `<Chart.Name>-<group>-<displayName>-<environment>` | `acme-cloud-myapp-admin-frontend-dev` |
| **Nested Helm App** | `apps.<group>.<subgroup>.<name>` | `<Chart.Name>-<group>-<subgroup>-<displayName>-<environment>` | `acme-cloud-myapp-mcp-hub-connector-dev` |
| **Extras Parent App** | `extras:` in root `values.yaml` | `<Chart.Name>-extras-<environment>` | `acme-cloud-myapp-extras-dev` |
| **Raw Manifest App** | `extras/manifests/<dir>` | `<Chart.Name>-extras-<environment>-<dirName>` | `acme-cloud-myapp-extras-dev-clamav` |
| **Root Manifests App** | `extras/manifests/*.yaml` | `<Chart.Name>-extras-<environment>-root` | `acme-cloud-myapp-extras-dev-root` |

> [!IMPORTANT]
> In version `1.0.0`+, the library automatically generates `{Chart.Name}-extras-{environment}-{dirName}`. If `.Values.environment` is omitted in `extras/values.yaml`, it automatically falls back to the target branch name segment (e.g. branch `myapp/dev` $\rightarrow$ `dev`).

---

## 4. GitOps Directory Structure & File Layout

A standardized GitOps repository powered by `argocd-gitops-tpl-library` adheres to the following layout:

```text
gitops-repo/
├── Chart.yaml                  # Root chart metadata (name: <product-prefix>)
├── values.yaml                 # Root values: global options, environment, apps catalog
├── templates/
│   └── apps.yaml               # One-line template: {{- include "tpl.argocd.applications" $ }}
├── values/                     # Microservice Helm value overrides
│   ├── notification.yaml       # Overrides for standalone service "notification"
│   ├── chat/
│   │   └── frontend.yaml       # Overrides for grouped service "chat.frontend"
│   └── admin/
│       ├── frontend.yaml       # Overrides for "admin.frontend"
│       └── backend.yaml        # Overrides for "admin.backend"
└── extras/                     # Non-Helm raw manifest application stack
    ├── Chart.yaml              # Extras chart metadata (name: <product-prefix>)
    ├── values.yaml             # Extras parameters, sync policies & per-manifest toggles
    ├── templates/
    │   └── manifest.yaml       # One-line template: {{- include "tpl.argocd.application.extras" $ }}
    └── manifests/              # Plain Kubernetes manifests grouped by folder
        ├── clamav/
        │   └── deployment.yaml
        ├── auth/
        │   └── secret.yaml
        └── certificate/
            └── issuer.yaml
```

---

## 5. Values Configuration & Parameter Catalog

### 5.1. Root `values.yaml` Parameter Reference

The root `values.yaml` governs the global cluster settings and catalog of Helm microservices:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `enabled` | bool | `true` | Global master switch for all applications generated by the chart. |
| `project` | string | `"developer"` | ArgoCD Project to which generated Applications will belong. |
| `environment` | string | `""` | Target environment identifier (`dev`, `qa`, `staging`, `prod`). Appended to application names. |
| `server` | string | `"in-cluster"` | ArgoCD destination server name or cluster API endpoint. |
| `repoURL` | string | `""` | Git clone URL for this GitOps repository. |
| `branch` | string | `""` | Git branch or revision tracked by ArgoCD (e.g. `myapp/dev`, `main`). |
| `preserveResourcesOnDeletion` | bool | `false` | When `true`, removes the ArgoCD deletion finalizer so deleting the Application CR does not purge cluster resources. |
| `sync.options` | list | `[...]` | Global sync options applied to all applications (`Validate=true`, `PruneLast=true`, `ApplyOutOfSyncOnly=true`, etc.). |
| `sync.retry` | map | `{ limit: 5, backoff: ... }` | Default retry backoff settings for out-of-sync applications. |
| `notification` | map | `{}` | Keyed map of notification subscriptions configuring Teams/Slack channel annotations. |
| `extras.enabled` | bool | `true` | Toggles rendering of the parent Extras ArgoCD Application. |
| `extras.sync.automated` | map | `{ prune: true, selfHeal: true }` | Automated sync controls for the extras parent application. |
| `apps` | map | `{}` | Hierarchical dictionary of Helm microservices (supports standalone, 2-tier, and 3-tier nesting). |

#### `apps.<name>` Service Fields

Each application defined in `.Values.apps` supports:

- `enabled` *(bool)*: Enables or disables generating the Application CR. Default: `true`.
- `releaseName` *(string)*: Helm release name in the destination cluster. Defaults to the map key.
- `namespace` *(string)*: Target Kubernetes namespace. Inherits from group or defaults to branch name.
- `chart.repoURL` *(string)*: OCI or HTTP Helm repository where the application chart is hosted.
- `chart.name` *(string)*: Name of the chart in the repository.
- `chart.version` *(string)*: Semantic version or tag of the chart.
- `chart.path` *(string)*: Local path to chart (for in-repo charts).
- `chart.valuesFiles` *(list)*: Additional values files inside `valuesPath`.
- `sync.automated` *(map)*: Automated sync policy (`{ prune: true, selfHeal: true }`). Pass `{}` to disable auto-sync.
- `sync.options` *(list)*: Service-specific sync options (merged with global options).
- `ignoreDifferences` *(list)*: Resource mutation ignore rules (e.g. for external replicas or mutating webhooks).

### 5.2. Extras `values.yaml` (`extras/values.yaml`) Parameter Reference

The `extras/values.yaml` configures the non-Helm raw manifest stack:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `environment` | string | `""` | Target environment identifier (e.g. `dev`). If omitted, derived from `.Values.branch`. |
| `project` | string | `"developer"` | ArgoCD Project for extras applications. |
| `server` | string | `"in-cluster"` | ArgoCD destination server name or cluster API endpoint. |
| `repoURL` | string | `""` | Git clone URL for the GitOps repository. |
| `branch` | string | `""` | Git branch tracked for manifest directories. |
| `namespace` | string | `""` | Target Kubernetes namespace for raw manifests (defaults to branch name kebab-cased). |
| `preserveResourcesOnDeletion` | bool | `false` | When `true`, removes finalizer to prevent resource deletion on Application removal. |
| `sync.options` | list | `[...]` | Default sync options for all manifest applications. |
| `sync.retry` | map | `{ limit: 5, ... }` | Default retry backoff settings. |
| `apps.<dirName>.enabled` | bool | `true` | Granular toggle to enable or disable an individual manifest folder (e.g. `apps.clamav.enabled: false`). |
| `apps.<dirName>.sync` | map | `{}` | Granular sync policy override for an individual manifest folder. |

---

## 6. How to Enable, Disable & Control Stacks

### 6.1. Disabling the Entire Extras Stack
In root `values.yaml`, set `extras.enabled` to `false`:
```yaml
extras:
  enabled: false
```

### 6.2. Disabling an Individual Helm Microservice
In root `values.yaml`, toggle `enabled: false` at any level:
```yaml
apps:
  # Disable standalone service
  notification:
    enabled: false

  # Disable specific subservice within a group
  chat:
    frontend:
      enabled: false

  # Disable an entire group of services
  admin:
    enabled: false
```

### 6.3. Disabling an Individual Raw Manifest Application
In `extras/values.yaml`, toggle the folder name under `.Values.apps`:
```yaml
apps:
  clamav:
    enabled: false
  s3-bucket-sync:
    enabled: false
```

### 6.4. Switching an Application from Auto-Sync to Manual Sync
To prevent ArgoCD from automatically applying changes to production or sensitive services, provide an empty map for `automated`:
```yaml
apps:
  payment:
    backend:
      sync:
        automated: {}  # Empty map disables automated sync (manual sync only)
```

---

## 7. App-of-Apps Bootstrap Manifest

To initialize the entire GitOps stack in your Kubernetes cluster, create and apply the following bootstrap Application:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: acme-cloud-myapp-dev-root
  namespace: argo-cd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: developer
  source:
    repoURL: https://gitlab.contoso.com/devops/gitops/acme-cloud.git
    targetRevision: myapp/dev
    path: .
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: in-cluster
    namespace: argo-cd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - ApplyOutOfSyncOnly=true
      - RespectIgnoreDifferences=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

---

## Requirements

- Helm: `>=3.2.0`
- Kubernetes: `>=1.27`

| Repository | Name | Version |
|------------|------|---------|

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| enabled | bool | `true` |  |
| environment | string | `"sample"` |  |
| project | string | `"default"` |  |
| server | string | `"in-cluster"` |  |
| repoURL | string | `"https://gitlab.com/gitops.git"` |  |
| branch | string | `"sample"` |  |
| preserveResourcesOnDeletion | bool | `false` |  |
| sync.options[0] | string | `"Validate=true"` |  |
| sync.options[1] | string | `"CreateNamespace=true"` |  |
| sync.options[2] | string | `"PrunePropagationPolicy=foreground"` |  |
| sync.options[3] | string | `"PruneLast=true"` |  |
| sync.options[4] | string | `"RespectIgnoreDifferences=true"` |  |
| sync.options[5] | string | `"ApplyOutOfSyncOnly=true"` |  |
| sync.retry.limit | int | `5` |  |
| sync.retry.backoff.duration | string | `"5s"` |  |
| sync.retry.backoff.factor | int | `2` |  |
| sync.retry.backoff.maxDuration | string | `"3m"` |  |
| sync.ignoreDifferences | list | `[]` |  |
| notification.notification1.template | string | `"teams-template"` |  |
| notification.notification1.channel[0] | string | `"team-channel"` |  |
| extras.enabled | bool | `true` |  |
| extras.sync.automated.prune | bool | `true` |  |
| extras.sync.automated.selfHeal | bool | `true` |  |
| extras.sync.options | list | `[]` |  |
| extras.sync.retry | object | `{}` |  |
| apps.sample.enabled | bool | `true` |  |
| apps.sample.chart.repoURL | string | `"chart.cr.io/helm"` |  |
| apps.sample.chart.version | string | `"0.1.0"` |  |
| apps.sample.chart.name | string | `"test"` |  |
| apps.sample.sync.automated.prune | bool | `true` |  |
| apps.sample.sync.automated.selfHeal | bool | `true` |  |
| apps.sample.sync.options | list | `[]` |  |
| apps.sample.sync.retry | object | `{}` |  |
| apps.groupa.enabled | bool | `true` |  |
| apps.groupa.namespace | string | `"group-namespace"` |  |
| apps.groupa.sample1.enabled | bool | `true` |  |
| apps.groupa.sample1.releaseName | string | `"sample1-override"` |  |
| apps.groupa.sample1.namespace | string | `"namespace-override"` |  |
| apps.groupa.sample1.chart.repoURL | string | `"chart.cr.io/helm"` |  |
| apps.groupa.sample1.chart.version | string | `"0.1.0"` |  |
| apps.groupa.sample1.chart.name | string | `"acme-core"` |  |
| apps.groupa.sample1.sync.automated.prune | bool | `true` |  |
| apps.groupa.sample1.sync.automated.selfHeal | bool | `true` |  |
| apps.groupa.sample1.sync.options | list | `[]` |  |
| apps.groupa.sample1.sync.retry | object | `{}` |  |
| apps.groupa.sample2.enabled | bool | `true` |  |
| apps.groupa.sample2.releaseName | string | `"sample2-override"` |  |
| apps.groupa.sample2.chart.repoURL | string | `"chart.cr.io/helm"` |  |
| apps.groupa.sample2.chart.version | string | `"0.1.0"` |  |
| apps.groupa.sample2.chart.name | string | `"sample2"` |  |
| apps.groupa.sample2.sync.automated | object | `{}` |  |
| apps.groupa.sample2.sync.options | list | `[]` |  |
| apps.groupa.sample2.sync.retry | object | `{}` |  |
| apps.groupa.sample3.enabled | bool | `true` |  |
| apps.groupa.sample3.namespace | string | `"sample3"` |  |
| apps.groupa.sample3.releaseName | string | `"sample3"` |  |
| apps.groupa.sample3.chart.path | string | `"sample3"` |  |
| apps.groupa.sample3.chart.valuesFiles[0] | string | `"values1.yaml"` |  |
| apps.groupa.sample3.sync.automated.prune | bool | `true` |  |
| apps.groupa.sample3.sync.automated.selfHeal | bool | `true` |  |

## License

Copyright 2026 Grootan Technologies Pvt Ltd.

Licensed under the [GNU Affero General Public License v3.0](./LICENSE.md)
(`AGPL-3.0-only`). External contributions are not accepted; see
[CONTRIBUTING.md](./CONTRIBUTING.md) for bug and security reporting.

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)

## Usage

```console
helm-docs --template-files README.gotmpl --sort-values-order file --document-dependency-values
```
