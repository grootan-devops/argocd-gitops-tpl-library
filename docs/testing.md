# Testing and verification

Run `make verify` from the library repository. It builds both mock consumer charts, lints
them in strict mode, renders them, and runs the Helm unit suites.

The root chart suite covers standalone/grouped/nested Helm Applications, app disabling,
optional cluster naming (empty and omitted), branch and namespace defaults, sync overrides, and the hard failure
when direct extras-manifest rendering is enabled. The extras chart suite covers named-folder
discovery, ignored root-level YAML, environment omission, branch/namespace defaults, global
`extras.enabled` and sync defaults, folder overrides, and retry/options precedence.

The plugin suite covers the native/plugin generator choice, the four-variable environment
contract, CRD include/skip defaults and boolean validation, literal-dollar escaping, values-file fallback for grouped and nested apps, disabled
definitions and rejection of unsupported plugin sources and patch files. Render a pinned
service chart through the actual CMP separately before rollout; these unit tests generate
Applications and do not contact a running Argo CD installation.

For a consumer repository, build dependencies and validate both charts:

```sh
helm dependency update .
helm dependency update extras/
helm lint --strict .
helm lint --strict extras/
helm template <project> .
helm template <project>-extras extras/
```

Do not treat an ignored root-level fixture as a workload. All actual YAML under
`extras/manifests/` belongs inside a named directory.
