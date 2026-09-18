# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.3.0] - 14-09-2026

### Fixed

- Fixed extras ArgoCD Application naming bug in `tpl.argocd.application.extras` where manifest applications omitted the `extras` constant and environment segment.
- Added automatic environment resolution fallback from `.Values.branch` when `.Values.environment` is omitted.
- Stripped legacy `-extras.*` suffixes from `.Chart.Name` to ensure zero regression when consumers migrate to clean `Chart.yaml` naming.

### Added

- Added `MIGRATION.md` outlining version upgrade procedures and breaking change migrations.
- Added `.yamllint.yml` and `.gitignore` configuration.
- Comprehensive `README.gotmpl` explaining GitOps folder structures, App-of-Apps naming conventions, root and extras `values.yaml` parameters, and stack enable/disable controls.

## [1.2.1] - 20-05-2026

### Fixed

- Increased Argo CD revisionHistoryLimit from 1 to 3 to prevent UI/API source version lookup errors caused by pruned application revision history.

## [1.2.0] - 21-04-2026

### Added

- Added support to delete apps without deleting resources. controlled via `.Values.preserveResourcesOnDeletion`

## [1.1.0] - 05-04-2026

### Changed

- Chart push repository path

## [1.0.0] - 03-04-2026

### Added

- Initial release
