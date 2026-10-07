{{/* Helm-repository CMP contract: Helm values followed by inline Kustomize options. */}}
{{- define "tpl.argocd.application.plugin" -}}
{{- $plugin := .plugin -}}
{{- if not (kindIs "map" $plugin) -}}
  {{- fail "app.plugin must be an object with a non-empty name" -}}
{{- end -}}
{{- range $key, $_ := $plugin -}}
  {{- if not (has $key (list "name" "kustomize")) -}}
    {{- fail (printf "app.plugin.%s is unsupported; use name and kustomize" $key) -}}
  {{- end -}}
{{- end -}}
{{- if not (kindIs "string" $plugin.name) -}}
  {{- fail "app.plugin.name must be a non-empty string" -}}
{{- end -}}
{{- $name := required "app.plugin.name must be a non-empty string" (trim $plugin.name) -}}
{{- $kustomize := dict -}}
{{- if hasKey $plugin "kustomize" -}}
  {{- if not (kindIs "map" $plugin.kustomize) -}}
    {{- fail "app.plugin.kustomize must be an object" -}}
  {{- end -}}
  {{- $kustomize = deepCopy $plugin.kustomize -}}
{{- end -}}
{{- range $key, $_ := $kustomize -}}
  {{- if not (has $key (list "patches" "images" "labels" "commonAnnotations" "replicas")) -}}
    {{- fail (printf "app.plugin.kustomize.%s is unsupported; use inline patches, images, labels, commonAnnotations or replicas" $key) -}}
  {{- end -}}
{{- end -}}
{{- if hasKey $kustomize "patches" -}}
  {{- if not (kindIs "slice" $kustomize.patches) -}}
    {{- fail "app.plugin.kustomize.patches must be a list of inline patches with targets" -}}
  {{- end -}}
  {{- range $patch := $kustomize.patches -}}
    {{- if not (kindIs "map" $patch) -}}
      {{- fail "app.plugin.kustomize.patches entries must be objects" -}}
    {{- end -}}
    {{- if hasKey $patch "path" -}}
      {{- fail "app.plugin.kustomize.patches must be inline; patch files are unavailable in downloaded charts" -}}
    {{- end -}}
    {{- if or (not (kindIs "string" $patch.patch)) (empty $patch.patch) -}}
      {{- fail "app.plugin.kustomize.patches entries require a non-empty patch string" -}}
    {{- end -}}
    {{- if or (not (kindIs "map" $patch.target)) (empty $patch.target) -}}
      {{- fail "app.plugin.kustomize.patches entries require an explicit target" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- $_ := set $kustomize "apiVersion" "kustomize.config.k8s.io/v1beta1" -}}
{{- $_ := set $kustomize "kind" "Kustomization" -}}
{{- $_ := set $kustomize "resources" (list "all.yaml") -}}
plugin:
  name: {{ $name | quote }}
  env:
    - name: HELM_RELEASE_NAME
      value: {{ .releaseName | quote }}
    - name: HELM_VALUES
      {{/* Argo CD interpolates plugin env values; $$ preserves a literal $. */}}
      value: {{ .valuesText | replace "$" "$$" | quote }}
    - name: KUSTOMIZATION_YAML
      value: {{ toYaml $kustomize | replace "$" "$$" | quote }}
{{- end -}}
