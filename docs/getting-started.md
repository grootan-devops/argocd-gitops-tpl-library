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
    version: 1.2.0 # replace with the latest stable published release
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
