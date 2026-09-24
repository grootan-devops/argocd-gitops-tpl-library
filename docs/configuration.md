# Configuration

## Shared identity and defaults

Set these fields in both root `values.yaml` and `extras/values.yaml`:

| Field | Required | Behavior |
| --- | --- | --- |
| `enabled` | No | Global switch for the root chart's generated Applications; defaults to `true`. |
| `cluster` | Yes | Cluster name segment in generated names. Rendering fails when it is empty. |
| `environment` | No | Optional suffix; an empty value removes it and is never inferred from the branch. |
| `project` | No | Argo CD Project for generated child Applications; the library default is `default`. |
| `server` | Yes for destinations | Argo CD destination cluster name (the `NAME` column in `argocd cluster list`). |
| `repoURL` | Yes | Git clone URL for the GitOps repository. |
| `branch` | No | Explicit Git revision; when empty, defaults to `<Chart.Name>/<environment>` or `<Chart.Name>`. |
| `namespace` | No | Workload namespace override; defaults to `<Chart.Name>-<environment>` or `<Chart.Name>`. It is not the `argo-cd` namespace. |
| `preserveResourcesOnDeletion` | No | `true` omits the resource finalizer; default `false` allows pruning on Application deletion. |

The root and extras charts must share the same project-only `Chart.Name`. Generated Helm app
names follow `<Chart.Name>-<cluster>-<app-path>[-<environment>]`; each raw-manifest folder
uses `<Chart.Name>-<cluster>-extras-<folder>[-<environment>]`.

## Root chart values

The root chart's `sync.options`, `sync.retry`, and `sync.ignoreDifferences` are defaults for
its Helm Applications and the parent Extras Application. `notification` is an optional map
of Argo CD notification subscriptions. `apps` is the Helm child-application registry.

```yaml
enabled: true
cluster: midgard
environment: dev
project: developer
server: in-cluster
repoURL: https://git.example.com/team/platform-gitops.git
branch: ""
preserveResourcesOnDeletion: false
renderExtrasManifests: false
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
apps: {}
```

`renderExtrasManifests` is deliberately constrained to `false`. Raw manifests are reconciled
through child Applications from the extras chart, never rendered directly by the root chart.

## Extras chart values

The extras chart needs the shared identity fields above. `extras.enabled` globally enables
or disables generated manifest-folder Applications. `extras.sync` supplies default automated
sync policy, sync options, ignore-difference rules, and retry settings; a per-folder
`.Values.apps.<directory>.sync` overrides these defaults. `sync` at the top level remains a
compatibility fallback for global options, ignore-difference rules, and retries.

```yaml
extras:
  enabled: true
  sync:
    automated:
      prune: true
      selfHeal: true
    options: []
    retry: {}
apps:
  clamav:
    enabled: true
    sync: {}
```

Each `apps.<directory>` key must match a directory under `extras/manifests/`. Set
`enabled: false` to omit one Application, or set `sync.automated: {}` to disable automated
sync for that folder.
