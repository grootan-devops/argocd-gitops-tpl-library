# Helm–Kustomize plugin

`plugin` is optional on a Helm application entry. Omit it to use native Helm. When
present, it selects one registered Argo CD Config Management Plugin (CMP) and supplies
Helm values followed by inline Kustomize options. Standalone, grouped and nested
Helm-repository entries use the same contract.

## Configuration

```yaml
apps:
  semaphore:
    enabled: false
    namespace: semaphore
    chart:
      repoURL: https://semaphoreui.github.io/charts/
      name: semaphore
      version: 16.2.2
    plugin:
      name: kustomized-helm
      kustomize:
        patches:
          - target:
              group: apps
              version: v1
              kind: Deployment
              name: semaphore
            patch: |-
              - op: add
                path: /spec/revisionHistoryLimit
                value: 0
    ignoreDifferences: []
    sync:
      automated:
        prune: true
        selfHeal: true
      options: []
      retry: {}
```

The example stays disabled. If enabled, Helm renders the pinned chart and Kustomize
sets the Deployment's revision history to zero. Workload history applies to
Deployments, StatefulSets and DaemonSets; it differs from the Application's own history.

`plugin.name` is a required non-empty string when the block is present. It is not
hardcoded: use `helm-kustomize`, `kustomized-helm`, a future version, or another
registration implementing this environment contract. For a CMP with `metadata.name:
helm-kustomize` and `spec.version: v2`, select `helm-kustomize-v2`. Each source selects
one CMP; that CMP can run multiple tools internally.

`plugin.kustomize` is optional. Its supported keys are `patches`, `images`, `labels`,
`commonAnnotations` and `replicas`. Each patch must contain an inline `patch` string
and an explicit `target`. The library always supplies `apiVersion`, `kind` and
`resources: [all.yaml]`; attempts to override those keys fail rendering.

Use `labels.includeSelectors: false` for informational labels so selectors remain
stable. Kustomize accepts a patch matching no objects, so verify the intended target
after rendering; success alone does not establish compliance.

## Generated source and environment

The library retains `repoURL`, chart name and pinned chart version. It emits
`source.plugin` instead of `source.helm`, with exactly these environment variables:

| Variable | Content |
| --- | --- |
| `HELM_RELEASE_NAME` | The existing resolved release name, defaulting to chart name. |
| `HELM_VALUES` | The existing values-file selection, including grouped/nested lookup and chart-name fallback. |
| `KUSTOMIZATION_YAML` | A complete Kustomization referring to Helm's `all.yaml` output. |

The existing missing-values-file behavior remains: empty values use chart defaults.
Argo CD exposes these as `ARGOCD_ENV_HELM_RELEASE_NAME`, `ARGOCD_ENV_HELM_VALUES` and
`ARGOCD_ENV_KUSTOMIZATION_YAML`. The destination namespace is available as
`ARGOCD_APP_NAMESPACE`.

The library escapes literal dollar signs in values and Kustomize content as `$$`
for Argo CD interpolation. The CMP must write the resulting strings literally.
Inline patch content is not evaluated with Helm `tpl`.

## CMP prerequisites and source limitations

Register the CMP separately before opting an Application in. Its generation flow is:

```text
helm template -> all.yaml -> kustomize build -> final manifests
```

The CMP must use the selected release and destination namespace, apply `HELM_VALUES`,
write `KUSTOMIZATION_YAML`, propagate failures, and emit only complete manifests on
stdout. It must contain compatible Helm and Kustomize binaries. Dependency building
needs its own access to any unpackaged chart dependencies.

This initial contract supports Helm-repository chart sources. Git charts using
`chart.path`, the parent Extras Application and raw-manifest extras reject plugin
opt-in. Patch files from the GitOps repository are unavailable in the downloaded
chart workspace, so file-based patches and additional resource files are unsupported.
Patches modify existing objects; missing PDBs, policies and monitors still need their
own resource definitions or chart options.

Argo CD v3.3.8's repository-server implementation extracts a Helm-repository chart
before invoking the selected CMP. Verify that behavior with your Argo CD version;
the library's tests do not exercise a running Argo CD installation.

## Diff and rollout checks

Render the actual pinned chart through both stages, including hooks and tests.
Compare resource identities, selectors, PVC templates and application configuration;
check any intended security, token, memory, pull-policy and history changes explicitly.
Keep disabled entries disabled and preserve existing sync and ignore-difference rules.

Resolve chart-generated randomness through supported chart configuration or its
owning controller. Scope any controller-owned-field diff exceptions narrowly.
Operator-generated and admission-injected Pods require separate runtime verification.

For rollback, remove `plugin` and rerender to restore native `source.helm`, then review
the desired manifests before syncing.

See [Argo CD CMP configuration](https://argo-cd.readthedocs.io/en/stable/operator-manual/config-management-plugins/),
[environment interpolation](https://argo-cd.readthedocs.io/en/stable/user-guide/build-environment/),
and [Kustomize options](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/).
