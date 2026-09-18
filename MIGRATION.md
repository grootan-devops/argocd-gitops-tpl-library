# Migration Guide & Standard

This document defines the **Migration Standard** for the ArgoCD GitOps Template Library (`argocd-gitops-tpl-library`) and contains version-by-version migration instructions for releases containing structural or breaking changes.

This guide is designed for **Platform Engineers** and **AI Coding Assistants** (Antigravity, Cursor, Claude Code) to ensure seamless and zero-downtime upgrades across GitOps repositories.

---

## [1.2.1...1.3.0] - 2026-09-14

### 1. Overview
Version `1.3.0` fixes the extras application naming bug in `tpl.argocd.application.extras` and establishes clean, standardized naming across both Helm and raw manifest stacks.

### 2. What Changed
- **Elimination of Chart.yaml Name Workaround in Extras**:
  Previously, to generate ArgoCD applications named `<product>-extras-<env>-<manifest>`, users had to hack `extras/Chart.yaml` by setting `name: <product>-extras-<env>`. In `1.3.0`, both root `Chart.yaml` and `extras/Chart.yaml` must use the canonical product name (`<product-prefix>`).
- **Standardized Application Naming Formula**:
  Manifest applications discovered under `extras/manifests/<dir>` are now automatically named:
  ```
  {{ .Chart.Name }}-extras-{{ .Values.environment }}-{{ dirName }}
  ```
  *(Example: `acme-cloud-myapp` + `extras` + `dev` + `clamav` -> `acme-cloud-myapp-extras-dev-clamav`)*
- **Automatic Environment Fallback**:
  If `.Values.environment` is omitted, the template automatically derives the environment from the last segment of `.Values.branch` (e.g., `myapp/dev` -> `dev`).
- **Zero-Regression Backward Compatibility**:
  If `extras/Chart.yaml` still contains the legacy `-extras.*` suffix, the template cleanly strips it so names are never duplicated (e.g., `acme-cloud-myapp-extras-dev-extras-dev` is prevented).

### 3. Migration Instructions for GitOps Repositories

#### Step 1: Update `extras/Chart.yaml`
Align `extras/Chart.yaml` name with the root `Chart.yaml`:
```yaml
# Before (Legacy Workaround):
apiVersion: v2
name: acme-cloud-myapp-extras-dev
version: 1.0.0
dependencies:
  - name: argocd-gitops-tpl-library
    version: 1.2.1

# After (Standardized in 1.3.0):
apiVersion: v2
name: acme-cloud-myapp
version: 1.0.0
dependencies:
  - name: argocd-gitops-tpl-library
    version: 1.3.0
```

#### Step 2: (Optional) Set `environment` in `extras/values.yaml`
Explicitly specify `environment` in `extras/values.yaml` for consistency:
```yaml
environment: dev
project: developer
server: in-cluster
repoURL: https://gitlab.example.com/devops/gitops/acme-cloud.git
branch: myapp/dev
```

---

## Release `1.2.1`

### Summary
- Increased Argo CD `revisionHistoryLimit` from 1 to 3 to prevent UI/API source version lookup errors caused by pruned application revision history.

---

## Release `1.2.0`

### Summary
- Added support to delete ArgoCD applications without cascading resource deletion via `.Values.preserveResourcesOnDeletion: true`. When enabled, omits the `resources-finalizer.argocd.argoproj.io` finalizer.
