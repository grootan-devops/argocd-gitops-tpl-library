# Root Argo CD Application

The bootstrap Application watches the GitOps repository's root chart. Its name is separate
from the generated child names:

```text
<cluster>-<project>-<environment>-root
<cluster>-<project>-root                 # if no environment is configured
```

For example, cluster `midgard`, project/chart `contoso`, and environment `dev` produce
`midgard-contoso-dev-root`. Put the environment, Argo CD URL, project name, GitOps repository,
target branch, cluster/server names, and derived root Application name in the consumer README.
Do not put credentials there.

The server name recorded in the GitOps repository's master `README.md` is the Argo CD cluster
name. In an Application spec, use `destination.name`, not `destination.server`; the latter
expects a cluster API server URL.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: midgard-contoso-dev-root
  namespace: argo-cd
spec:
  project: cluster-admin
  source:
    repoURL: https://github.com/contoso/platform-gitops.git
    path: .
    targetRevision: contoso/dev
  destination:
    name: in-cluster
    namespace: argo-cd
  syncPolicy:
    automated:
      enabled: true
      prune: true
      selfHeal: true
    syncOptions:
      - Validate=true
      - CreateNamespace=false
      - PrunePropagationPolicy=foreground
      - PruneLast=true
      - RespectIgnoreDifferences=true
      - ApplyOutOfSyncOnly=true
    retry:
      limit: 2
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m0s
```

When environment is empty, omit `environment` from both values files and remove its name
segment from the root Application. The target revision remains the selected branch (default
`<project>`).
