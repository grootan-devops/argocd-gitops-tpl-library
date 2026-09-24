# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and
this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
