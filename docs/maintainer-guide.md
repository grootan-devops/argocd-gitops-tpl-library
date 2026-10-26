# Maintainer guide

## Releases

`Chart.yaml` holds the release: `version` and `appVersion` are the same, and a merge to `main`
tags that version, publishes a GitHub release and pushes the chart to
`oci://registry-1.docker.io/grootantech`. A pull request that ships a change:

1. bumps `version` and `appVersion` in `Chart.yaml`, and the library dependency of both mock
   consumers, `tests/Chart.yaml` and `tests/extras/Chart.yaml`;
2. adds a [`CHANGELOG.md`](../CHANGELOG.md) entry and a [`MIGRATION.md`](../MIGRATION.md)
   section split into Required, Recommended and Verify, even when nothing is required;
3. regenerates the README after any change to `README.gotmpl` or `Chart.yaml`, inside the
   repository root: `helm-docs --template-files README.gotmpl --sort-values-order file`;
4. runs `make verify` before pushing.

The pull request checks reject a git tag or chart version that already exists, a missing
changelog or migration section, an unpinned reusable workflow and an unresolvable chart
dependency, then lint the chart and run both helm-unittest suites. A pull request publishes a
candidate as `<version>-<run>.<pr>`; only the merge publishes `<version>` itself. A Renovate
pull request that only updates CI dependencies is a patch release. Example pins in the docs
are `<version>`: they show syntax and never need a release bump.

## Versioning

Releases follow semantic versioning for the public interface:

- the root and extras values: the `apps` entry fields, the shared identity fields, sync and
  extras settings, and their defaults;
- the include names `tpl.argocd.applications` and `tpl.argocd.application.extras`;
- every name, namespace, branch and values path the templates derive;
- [`docs/environment-map.json`](environment-map.json).

Patch and minor releases stay backward compatible within a major version. A breaking change
needs a new major version and a Required migration step. A change to a derived Application
name is breaking even when every value still renders: Argo CD deletes the old Application and,
with pruning, its workloads. A deprecated field keeps working for at least the next minor
release and is announced in the changelog and the migration guide before it goes. A page
describes the release it ships in: history belongs in the changelog and migration guide.

## Environment map

[`docs/environment-map.json`](environment-map.json) is the machine-readable form of
[Helm Applications](configuration.md#helm-applications-apps) and
[What a values file overrides](configuration.md#what-a-values-file-overrides). Tools read it
at the version an environment pins and refuse a version without it, so change it in the same
commit as those sections:

- `apps.valuesFile`: where an entry's values file is written; `{path}` is the entry's key, or
  `<group>/<release>` for a release of a group.
- `apps.syncPresets`: the `sync` block of an entry with automated (`auto`) or manual sync.
- `apps.releaseShapeKeys`: the keys a release of a multi-release chart sets in its values file.
- `overrides`: the value paths an environment values file may set, by category; the paths only
  a release of a multi-release chart may set; and the paths that belong in the chart, with
  the reason. `*` is one path segment, a trailing `**` any depth, and `{container}` each of the
  `overrides.containers` paths.

Names, namespaces and values paths are not in the map: tools render them with `helm template`
at the same version. The file ships inside the packaged chart, so an environment's resolved
dependency carries the map of exactly the version it renders with. `schema` is the version of
this contract. Raise it when a change to the file's shape would make an older reader misjudge
an environment: readers refuse a schema they do not know instead of guessing.

[Documentation index](../README.md)
