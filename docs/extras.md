# Raw-manifest Extras

The extras chart scans `extras/manifests/**/*.yaml` and creates one Argo CD Application per
named directory. Root-level YAML files directly under `extras/manifests/` are ignored because
they have no application identity. Put every real manifest under a directory such as:

```text
extras/manifests/
├── clamav/
│   ├── configmap.yaml
│   └── deployment.yaml
└── certificate/
    └── issuer.yaml
```

The generated Application points to `extras/manifests/<directory>` and uses
`<Chart.Name>-<cluster>-extras-<directory>[-<environment>]`. Use `.yaml` filenames, because
the library's discovery glob is `**/*.yaml`.

The extras chart must have the same `Chart.Name` as the root chart and its own
`extras/values.yaml`. `extras.enabled` controls the whole extras stack. Per-folder values in
`apps.<directory>` can disable a folder or override its sync policy. The library merges
top-level `sync.options`, `extras.sync.options`, and folder options in that precedence order;
folder retry/automated settings override extras-wide defaults. Ignore-difference rules are
combined from root, Extras-wide, legacy folder-level, and folder `sync.ignoreDifferences`
settings, in that order.

Application CRs are stored in namespace `argo-cd`; `destination.name` and
`destination.namespace` identify the destination cluster and workload namespace. The workload
namespace defaults to `<Chart.Name>-<environment>` or `<Chart.Name>`.
