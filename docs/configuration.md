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
cluster: lab
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

## Helm Applications (`apps`)

Adding a service to an environment is two changes in the root chart: an entry under `apps`,
and — for a chart from a Helm repository — its values file under `values/`.

```yaml
apps:
  orders:                       # one release of a chart
    chart:
      repoURL: oci://registry.example.com/charts
      name: orders
      version: 1.4.0
    sync:
      automated:
        prune: true
        selfHeal: true
      options: []
      retry: {}
  billing:                      # a group: one chart, several releases
    namespace: billing
    api:
      chart: {repoURL: oci://registry.example.com/charts, name: billing, version: 2.0.1}
    worker:
      chart: {repoURL: oci://registry.example.com/charts, name: billing, version: 2.0.1}
      releaseName: billing-worker
```

| Entry | Values file | Application name |
| --- | --- | --- |
| `apps.<key>` with `chart` | `values/<key>.yaml` | `<Chart.Name>-<cluster>-<key>[-<environment>]` |
| `apps.<group>.<release>` | `values/<group>/<release>.yaml` | `<Chart.Name>-<cluster>-<group>-<release>[-<environment>]` |
| `apps.<group>.<a>.<b>` | `values/<group>/<a>/<b>.yaml` | `<Chart.Name>-<cluster>-<group>-<a>-<b>[-<environment>]` |

- **Keys.** A map without `chart` is a group. Keys and release names are converted to
  kebab-case in names and file paths; the group directory is used exactly as the group key is
  written, so keep every key lowercase kebab-case. `<Chart.Name>` is this root chart's name;
  the group segment is left out of the Application name when the group key equals it.
- **Chart.** `repoURL`, `name` and `version` (each rendered through `tpl`) select a published
  chart; pin a version that exists in the repository. `path` with optional `valuesFiles`
  selects a chart stored in this repository instead; it reads `values.yaml` and those files
  from its own directory, not from `values/`.
- **Release and namespace.** `releaseName` defaults to the chart name — to the key for a path
  chart — so releases of one chart that share a namespace need distinct values unless the
  chart derives distinct resource names itself. `namespace` falls back from the entry, to its
  group, to the global `namespace`, to `<Chart.Name>-<environment>` (or `<Chart.Name>`). With
  `CreateNamespace=false` in the sync options, the namespace must already exist.
- **Values file.** Looked up as `values/<path>.yaml` from the table, then
  `values/<group>/<name>.yaml`, then `values/<chart name>.yaml`; its content is copied into
  the Application's `helm.values`. A missing or misnamed file is not an error: the chart
  deploys with its defaults. The root Application must sync before a child sees a change.
- **Sync.** An entry's `sync.automated` map is rendered as written. `automated: {}` still
  enables automated sync — unlike an extras folder, where it disables it — so a manually
  synced Application omits `automated`. An entry's `sync.options` override the global list key
  by key; a non-empty `sync.retry` replaces the global retry, and `retry: {}` keeps it.
  `enabled: false` on an entry or a group omits its Applications.
- **Changes.** A version bump is a change to `chart.version`, usually made by a CI deploy job
  that updates the entry by its path (`.apps.orders`). Removing an entry deletes its
  Application and, with pruning, its workloads.

### Optional Helm–Kustomize plugin

Set `apps.<entry>.plugin.name` to select a registered CMP instead of native Helm, and
`plugin.kustomize` for inline transformations. Omit `plugin` to retain native Helm.
See [the plugin guide](./helm-kustomize.md) for the schema, environment contract and
supported source types.

### What a values file overrides

The chart's `values.yaml` holds the service's behaviour; an environment's values file holds
only what differs per environment:

| Category | Keys |
| --- | --- |
| Routing | `global.routes.*` (domain, ingress class, TLS secret, gateway); `routes.<r>.host` / `hosts`; the Ingress and HTTPRoute switches |
| Image and pull | `global.image.*` (registry, pull secrets, pull policy); `image.*` of any container, job and cronjob containers included |
| Resources and storage | `resources.*` of any container; `persistence.<p>.storageClass` and `size` |
| Application configuration | the chart's own top-level blocks (databases, identity, service URLs, keys) |
| Release shape — only for a release of a multi-release chart | `mode`, `component`, `subComponent`, the service shape, probes, `strategy`, `routes.<r>.enabled`, job and persistence `enabled` |

Carry each application block in full, default or not, so the file shows every setting the
environment depends on; keep everything else minimal and drop keys that equal the chart's.
Anything outside these categories — mounts, route paths and matches, container environment
(`configmapEnvs`, `secretEnvs`, `env`), probes or the service shape of a single-release chart,
`global.releaseNameLength` — belongs in the chart: when every environment needs it, it is a
chart change. Reference other services from the environment's own domain, including the
scheme and path the consumer expects, rather than hard-coding hosts, and keep credentials in
the environment's secret mechanism.

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
