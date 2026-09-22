# contoso-platform

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)

Mock consumer chart for argocd-gitops-tpl-library contract tests.

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| file://.. | argocd-gitops-tpl-library | 1.0.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| enabled | bool | `true` |  |
| environment | string | `"dev"` |  |
| project | string | `"contoso"` |  |
| server | string | `"in-cluster"` |  |
| repoURL | string | `"https://github.com/contoso/platform-gitops.git"` |  |
| branch | string | `"payments/dev"` |  |
| preserveResourcesOnDeletion | bool | `false` |  |
| renderExtrasManifests | bool | `false` |  |
| sync.options[0] | string | `"Validate=true"` |  |
| sync.options[1] | string | `"CreateNamespace=true"` |  |
| sync.retry.limit | int | `5` |  |
| sync.retry.backoff.duration | string | `"5s"` |  |
| sync.retry.backoff.factor | int | `2` |  |
| sync.retry.backoff.maxDuration | string | `"3m"` |  |
| notification | object | `{}` |  |
| extras.enabled | bool | `true` |  |
| extras.sync.automated.prune | bool | `true` |  |
| extras.sync.automated.selfHeal | bool | `true` |  |
| apps.api.enabled | bool | `true` |  |
| apps.api.namespace | string | `"payments"` |  |
| apps.api.chart.repoURL | string | `"oci://registry.contoso.com/helm"` |  |
| apps.api.chart.name | string | `"payment-api"` |  |
| apps.api.chart.version | string | `"1.0.0"` |  |
| apps.api.sync.automated.prune | bool | `true` |  |
| apps.api.sync.automated.selfHeal | bool | `true` |  |
| apps.admin.enabled | bool | `true` |  |
| apps.admin.namespace | string | `"administration"` |  |
| apps.admin.frontend.enabled | bool | `true` |  |
| apps.admin.frontend.chart.repoURL | string | `"oci://registry.contoso.com/helm"` |  |
| apps.admin.frontend.chart.name | string | `"admin-frontend"` |  |
| apps.admin.frontend.chart.version | string | `"1.0.0"` |  |
| apps.admin.frontend.sync.automated | object | `{}` |  |
| argocd-gitops-tpl-library.enabled | bool | `true` |  |
| argocd-gitops-tpl-library.environment | string | `"sample"` |  |
| argocd-gitops-tpl-library.project | string | `"default"` |  |
| argocd-gitops-tpl-library.server | string | `"in-cluster"` |  |
| argocd-gitops-tpl-library.repoURL | string | `"https://gitlab.com/gitops.git"` |  |
| argocd-gitops-tpl-library.branch | string | `"sample"` |  |
| argocd-gitops-tpl-library.preserveResourcesOnDeletion | bool | `false` |  |
| argocd-gitops-tpl-library.sync.options[0] | string | `"Validate=true"` |  |
| argocd-gitops-tpl-library.sync.options[1] | string | `"CreateNamespace=true"` |  |
| argocd-gitops-tpl-library.sync.options[2] | string | `"PrunePropagationPolicy=foreground"` |  |
| argocd-gitops-tpl-library.sync.options[3] | string | `"PruneLast=true"` |  |
| argocd-gitops-tpl-library.sync.options[4] | string | `"RespectIgnoreDifferences=true"` |  |
| argocd-gitops-tpl-library.sync.options[5] | string | `"ApplyOutOfSyncOnly=true"` |  |
| argocd-gitops-tpl-library.sync.retry.limit | int | `5` |  |
| argocd-gitops-tpl-library.sync.retry.backoff.duration | string | `"5s"` |  |
| argocd-gitops-tpl-library.sync.retry.backoff.factor | int | `2` |  |
| argocd-gitops-tpl-library.sync.retry.backoff.maxDuration | string | `"3m"` |  |
| argocd-gitops-tpl-library.sync.ignoreDifferences | list | `[]` |  |
| argocd-gitops-tpl-library.notification.notification1.template | string | `"teams-template"` |  |
| argocd-gitops-tpl-library.notification.notification1.channel[0] | string | `"team-channel"` |  |
| argocd-gitops-tpl-library.extras.enabled | bool | `true` |  |
| argocd-gitops-tpl-library.extras.sync.automated.prune | bool | `true` |  |
| argocd-gitops-tpl-library.extras.sync.automated.selfHeal | bool | `true` |  |
| argocd-gitops-tpl-library.extras.sync.options | list | `[]` |  |
| argocd-gitops-tpl-library.extras.sync.retry | object | `{}` |  |
| argocd-gitops-tpl-library.apps.sample.enabled | bool | `true` |  |
| argocd-gitops-tpl-library.apps.sample.chart.repoURL | string | `"chart.cr.io/helm"` |  |
| argocd-gitops-tpl-library.apps.sample.chart.version | string | `"0.1.0"` |  |
| argocd-gitops-tpl-library.apps.sample.chart.name | string | `"test"` |  |
| argocd-gitops-tpl-library.apps.sample.sync.automated.prune | bool | `true` |  |
| argocd-gitops-tpl-library.apps.sample.sync.automated.selfHeal | bool | `true` |  |
| argocd-gitops-tpl-library.apps.sample.sync.options | list | `[]` |  |
| argocd-gitops-tpl-library.apps.sample.sync.retry | object | `{}` |  |
| argocd-gitops-tpl-library.apps.groupa.enabled | bool | `true` |  |
| argocd-gitops-tpl-library.apps.groupa.namespace | string | `"group-namespace"` |  |
| argocd-gitops-tpl-library.apps.groupa.sample1.enabled | bool | `true` |  |
| argocd-gitops-tpl-library.apps.groupa.sample1.releaseName | string | `"sample1-override"` |  |
| argocd-gitops-tpl-library.apps.groupa.sample1.namespace | string | `"namespace-override"` |  |
| argocd-gitops-tpl-library.apps.groupa.sample1.chart.repoURL | string | `"chart.cr.io/helm"` |  |
| argocd-gitops-tpl-library.apps.groupa.sample1.chart.version | string | `"0.1.0"` |  |
| argocd-gitops-tpl-library.apps.groupa.sample1.chart.name | string | `"acme-core"` |  |
| argocd-gitops-tpl-library.apps.groupa.sample1.sync.automated.prune | bool | `true` |  |
| argocd-gitops-tpl-library.apps.groupa.sample1.sync.automated.selfHeal | bool | `true` |  |
| argocd-gitops-tpl-library.apps.groupa.sample1.sync.options | list | `[]` |  |
| argocd-gitops-tpl-library.apps.groupa.sample1.sync.retry | object | `{}` |  |
| argocd-gitops-tpl-library.apps.groupa.sample2.enabled | bool | `true` |  |
| argocd-gitops-tpl-library.apps.groupa.sample2.releaseName | string | `"sample2-override"` |  |
| argocd-gitops-tpl-library.apps.groupa.sample2.chart.repoURL | string | `"chart.cr.io/helm"` |  |
| argocd-gitops-tpl-library.apps.groupa.sample2.chart.version | string | `"0.1.0"` |  |
| argocd-gitops-tpl-library.apps.groupa.sample2.chart.name | string | `"sample2"` |  |
| argocd-gitops-tpl-library.apps.groupa.sample2.sync.automated | object | `{}` |  |
| argocd-gitops-tpl-library.apps.groupa.sample2.sync.options | list | `[]` |  |
| argocd-gitops-tpl-library.apps.groupa.sample2.sync.retry | object | `{}` |  |
| argocd-gitops-tpl-library.apps.groupa.sample3.enabled | bool | `true` |  |
| argocd-gitops-tpl-library.apps.groupa.sample3.namespace | string | `"sample3"` |  |
| argocd-gitops-tpl-library.apps.groupa.sample3.releaseName | string | `"sample3"` |  |
| argocd-gitops-tpl-library.apps.groupa.sample3.chart.path | string | `"sample3"` |  |
| argocd-gitops-tpl-library.apps.groupa.sample3.chart.valuesFiles[0] | string | `"values1.yaml"` |  |
| argocd-gitops-tpl-library.apps.groupa.sample3.sync.automated.prune | bool | `true` |  |
| argocd-gitops-tpl-library.apps.groupa.sample3.sync.automated.selfHeal | bool | `true` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
