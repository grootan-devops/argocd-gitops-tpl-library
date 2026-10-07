# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and
this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.6.0] - 2026-10-07

### Changed

- Updated [`grootan-devops/github-ci-library`](https://github.com/grootan-devops/github-ci-library) from [`1.4.0` to `1.5.0`](https://app.renovatebot.com/package-diff?name=grootan-devops%2Fgithub-ci-library&from=1.4.0&to=1.5.0)

## [1.5.0] - 2026-10-07

### Added

- Optional `apps.<entry>.plugin.name` and `plugin.kustomize` for Helm-repository Applications, including grouped and nested entries. The CMP replaces native `source.helm` while retaining chart identity, values-file lookup, destination and sync settings.
- Inline Kustomize patches, images, labels, common annotations and replicas. The library supplies `resources: [all.yaml]` and rejects unsupported source types and file-based patches.
- A three-variable CMP contract: `HELM_RELEASE_NAME`, `HELM_VALUES` and `KUSTOMIZATION_YAML`, with literal-dollar escaping for Argo CD environment interpolation.
- Plugin contract tests and an opt-in migration guide. Existing native Helm Applications, extras manifest handling and disabled states remain unchanged.

## [1.4.0] - 2026-10-01

### Added

- Documented the `apps` registry in `docs/configuration.md`: entry and group shapes, values-file paths and lookup, Application names, release and namespace defaults, sync behaviour, and what an environment values file overrides. Linked it from both documentation indexes.
- `docs/getting-started.md`: starter files for a new environment (`.gitignore`, `.helmignore`, both `Chart.yaml` files, `extras/values.yaml`, the environment README).
- `docs/root-application.md`: how the GitOps repository README records the cluster label and the Argo CD cluster name.

### Changed

- Both documentation indexes link `MIGRATION.md` and `CHANGELOG.md` for upgrading an existing environment, and state the same-ref reading rule for AI-assisted work.

### Fixed

- `README.gotmpl` pinned the quick-start dependency at 1.2.0 while `README.md` showed 1.3.0; both pin the current release.
- The configuration and root Application examples use the example cluster name `lab`.

## [1.3.0] - 2026-09-26

### Changed

- Bumped container image in `.github/workflows/pr.yml` to `grootantech/toolkit:1.1.0`.
- Pinned repository CI reusable workflow callers to `github-ci-library` `@1.4.0`.
- Enabled candidate chart publishing in CI (`publish-candidate: true`).
- Added manual workflow dispatch and enabled push-triggered chart release on `main`.
- Bumped chart release version to `1.3.0` across Chart.yaml, tests, and documentation.

## [1.2.0] - 2026-09-24

### Changed

- Rename the root and extras mock consumer charts to `tests/`, update the PR paths, and run
  each chart's suites against only that chart.
- Include the configured cluster in generated Argo CD Application names and standardize extras naming.
- Default Git target revisions and workload namespaces from the consumer chart name and optional environment.
- Ignore root-level extras manifests; create one extras Application per named manifest directory.
- Refactor consumer contract tests to model separate root and extras charts with the same project name.
- Apply `extras.enabled` and `extras.sync` defaults in the extras chart while preserving per-directory overrides and top-level sync compatibility.
- Reject `renderExtrasManifests: true`; raw manifests are managed only through named-directory Extras Applications.
- Document the cluster-first root Application naming convention and two-chart consumer layout in focused guides.

## [1.1.0] - 2026-09-22

### Changed

- Pinned GitHub Actions reusable workflows to `github-ci-library` 1.0.0.
- Updated chart metadata, release documentation, and Helm package exclusions.

## [1.0.0] - 2026-09-19

### Added

- Initial public release.
