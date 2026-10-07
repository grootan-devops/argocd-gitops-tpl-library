# Getting started

Use two consumer charts with the same project-only name: the repository root chart manages
Helm child Applications and the `extras/` chart manages raw-manifest child Applications.
Do not append the cluster or environment to either chart name.

```text
.
├── .gitignore
├── .helmignore
├── Chart.yaml
├── README.md
├── values.yaml
├── templates/apps.yaml
├── values/.gitkeep
└── extras/
    ├── .helmignore
    ├── Chart.yaml
    ├── values.yaml
    ├── templates/apps.yaml
    └── manifests/
        └── <application-name>/
            └── <resource>.yaml
```

The root and `extras/Chart.yaml` both declare the same `name` and pin the same published
library release:

```yaml
apiVersion: v2
name: contoso
type: application
version: 1.0.0
appVersion: "1.0.0"
dependencies:
  - name: argocd-gitops-tpl-library
    version: 1.5.0 # replace with the latest stable published release
    repository: oci://registry-1.docker.io/grootantech
```

The one-line templates are:

```gotemplate
{{- include "tpl.argocd.applications" $ }}
```

```gotemplate
{{- include "tpl.argocd.application.extras" $ }}
```

Keep `.gitignore` entries for `charts/`, `Chart.lock`, and `.DS_Store`. Use a `.helmignore`
at the root and another under `extras/` to omit VCS and editor files from chart packages.
The root chart's `values.yaml` holds global cluster settings and `apps`; `extras/values.yaml`
has its own cluster settings, `extras` enable/sync defaults, and per-directory `apps`
overrides. See [Configuration](./configuration.md) for the exact fields.

The root chart's `renderExtrasManifests` value must stay `false`: raw manifests are not
rendered by the root chart. They are discovered by the separate `extras/` chart and managed
through generated Applications.

## Starter files

Fill the `<…>` values from the repository README and the user's answers. The root
`values.yaml` is the example in [Configuration](./configuration.md#root-chart-values), with
`apps: {}`; the root Application is the manifest in [Root Application](./root-application.md).
Pin `<version>` to the highest stable release published to the OCI registry.

`.gitignore`:

```text
.git
charts/
Chart.lock
.DS_Store
```

`.helmignore`, identical at the root and in `extras/`:

```text
.git/
.gitignore
.DS_Store
Chart.lock
README.md
README.gotmpl
docs/
.github/
.gitleaks.toml
.yamllint.yml
CODEOWNERS
CONTRIBUTING.md
LICENSE.md
Makefile
SECURITY.md
VERSION
*.swp
*.bak
*.tmp
*.orig
*~
.project
.idea/
.vscode/
```

`Chart.yaml` and `extras/Chart.yaml` differ only in their description:

```yaml
apiVersion: v2
name: <project>
description: GitOps application catalog for <project>.   # extras: Raw-manifest Application catalog for <project>.
type: application
version: 1.0.0
appVersion: "1.0.0"
dependencies:
  - name: argocd-gitops-tpl-library
    version: <version>
    repository: oci://registry-1.docker.io/grootantech
```

`extras/values.yaml`:

```yaml
enabled: true
cluster: <cluster>
environment: <environment>
project: developer
server: <argocd-cluster-name>
repoURL: <gitops-repository-url>
branch: ""
preserveResourcesOnDeletion: false
namespace: ""

sync:
  options:
    - Validate=true
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
    - PruneLast=true
    - RespectIgnoreDifferences=true
    - ApplyOutOfSyncOnly=true
  retry:
    limit: 5
    backoff:
      duration: 5s
      factor: 2
      maxDuration: 3m
  ignoreDifferences: []

notification: {}

extras:
  enabled: true
  sync:
    automated:
      prune: true
      selfHeal: true
    options: []
    retry: {}
    ignoreDifferences: []

apps: {}
```

`README.md`, with no credentials:

```markdown
# <project> GitOps Environment

- Environment: <environment>
- Argo CD URL: <argocd-url>
- GitOps repository: <gitops-repository-url>
- Target branch: <branch>
- Project: <project>
- Cluster: <cluster>
- Argo CD cluster name: <argocd-cluster-name>
- Root Application: <root-application-name>

The root chart manages Helm Applications. The `extras/` chart manages raw manifests placed
under `extras/manifests/<application-name>/`. Keep credentials out of this file.
```

With an empty environment, remove the `environment` key from both values files.
