{{- define "tpl.argocd.application" }}
---
{{- if $.Values.enabled }}
{{- $isEnabled := true }}
{{- if hasKey .appName "enabled" }}
  {{- $isEnabled = .appName.enabled }}
{{- end }}
{{- if $isEnabled }}
{{- $display := "" }}
{{- if (.extras) }}
{{- $display = "extras" }}
{{- else }}
{{- $display = include "util.displayName" . }}
{{- end }}
{{- $appName := "" }}
{{- if or (eq .rootApp .Chart.Name) (.extras) (not .rootApp) (eq .rootApp "") }}
  {{- if .Values.environment }}
  {{- $appName = printf "%s-%s-%s" .Chart.Name $display .Values.environment }}
  {{- else }}
  {{- $appName = printf "%s-%s" .Chart.Name $display }}
  {{- end }}
{{- else }}
  {{- if .Values.environment }}
  {{- $appName = printf "%s-%s-%s-%s" .Chart.Name .rootApp $display .Values.environment }}
  {{- else }}
  {{- $appName = printf "%s-%s-%s" .Chart.Name .rootApp $display }}
  {{- end }}
{{- end }}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {{ $appName }}
  namespace: argo-cd
  {{- if not (default false $.Values.preserveResourcesOnDeletion) }}
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  {{- end }}
  {{- include "tpl.argocd.application.annotations" $ | nindent 2 }}
spec:
  project: {{ .Values.project }}
  {{- if (.extras) }}
  {{- include "tpl.argocd.application.extras.app" $ | indent 2 }}
  {{- else }}
  {{- include "tpl.argocd.application.helm.app" $ | indent 2 }}
  {{- end }}
  syncPolicy:
    {{- if (hasKey (.appName).sync "automated") }}
    {{- if (.appName).sync.automated }}
    automated: {{- (.appName).sync.automated | toYaml | nindent 6 }}
    {{- else }}
    automated: {}
    {{- end }}
    {{- end }}
    {{- $appOptions := (.appName).sync.options | default list }}
    {{- $globalOptions := $.Values.sync.options | default list }}
    syncOptions:
    {{- include "util.mergeSyncOptions" (dict "global" $globalOptions "app" $appOptions) | nindent 6 }}
    retry: {{ (.appName).sync.retry | default .Values.sync.retry | toYaml | nindent 6 }}
  revisionHistoryLimit: 3
  {{- if (.appName).ignoreDifferences }}
  ignoreDifferences: {{ (.appName).ignoreDifferences | toYaml | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- define "tpl.argocd.application.extras.app" }}
source:
  repoURL: {{ $.Values.repoURL }}
  targetRevision: {{ $.Values.branch }}
  path: extras
destination:
  name: in-cluster
  namespace: argo-cd
{{- end }}

{{- define "tpl.argocd.application.helm.app" -}}
{{- $rootApp := .rootApp }}
{{- $name := .name }}
{{- $displayName := include "util.displayName" . }}

{{- $chartRaw := (.appName).chart }}
{{- $chart := $chartRaw }}
{{- if kindIs "string" $chartRaw }}
  {{- $chart = tpl $chartRaw $ | fromYaml }}
{{- end }}

{{- $chartName := "" }}

{{- if $chart.path }}
{{- $releaseName := (.appName).releaseName | default .name | toString }}
source:
  repoURL: {{ $.Values.repoURL }}
  targetRevision: {{ $.Values.branch }}
  path: {{ $chart.path }}
  helm:
    valueFiles:
      {{- if $chart.valuesFiles }}
      - values.yaml
        {{- range $index, $valueFile := $chart.valuesFiles }}
      - {{ $valueFile }}
        {{- end }}
      {{- else }}
      - values.yaml
      {{- end }}
    releaseName: {{ $releaseName }}
{{- else }}
{{- $chartName := tpl ($chart.name | toString) $ }}

{{- $fileWithDisplayName := printf "values/%s/%s.yaml" $rootApp (include "util.kebabcase" $name) | replace "//" "/" }}
{{- $fileWithChartName := printf "values/%s.yaml" $chartName | replace "//" "/" }}
{{- $valuesFile := "" }}

{{- if and .valuesPath (.Files.Get .valuesPath) }}
  {{- $valuesFile = .valuesPath }}
{{- else if (.Files.Get $fileWithDisplayName) }}
  {{- $valuesFile = $fileWithDisplayName }}
{{- else }}
  {{- $valuesFile = $fileWithChartName }}
{{- end }}

source:
  repoURL: {{ tpl ($chart.repoURL | toString) $ }}
  targetRevision: {{ tpl ($chart.version | toString) $ }}
  chart: {{ $chartName }}
  helm:
    releaseName: {{ tpl ((.appName).releaseName | default $chartName | toString) $ }}
    values: |
      {{- .Files.Get $valuesFile | nindent 6 }}
    ignoreMissingValueFiles: true
{{- end }}

destination:
  name: {{ .Values.server }}
  {{- if .Values.environment }}
  namespace: {{ (.appName).namespace | default .groupNamespace | default .Values.namespace | default (.Values.branch | replace "/" "-") }}
  {{- else }}
  namespace: {{ (.appName).namespace | default .groupNamespace | default .Values.namespace | default $chartName | default (.Values.branch | replace "/" "-") }}
  {{- end }}
{{- end }}

{{- define "tpl.argocd.application.extras" }}
---
{{- $base := "manifests" }}
{{- $seen := dict }}
{{- $rootFilesExist := .Files.Glob (printf "%s/*.yaml" $base) }}
{{- $chartBase := regexReplaceAll "-extras(-.*)?$" $.Chart.Name "" }}
{{- $env := $.Values.environment | default (splitList "/" ($.Values.branch | default "") | last) }}

{{- range $file, $_ := .Files.Glob (printf "%s/**/*.yaml" $base) }}
  {{- $dir := dir $file }}
  {{- if ne $dir $base }}
    {{- $relDir := trimPrefix (printf "%s/" $base) $dir }}
    {{- if not (hasKey $seen $relDir) }}
      {{- $_ := set $seen $relDir true }}
      {{- $appNameSuffix := include "util.kebabcase" (replace "/" "-" $relDir) }}

      {{- $extraValues := dict }}
      {{- if $.Values.apps }}
        {{- $extraValues = get $.Values.apps $appNameSuffix | default dict }}
      {{- end }}

      {{- $isEnabled := true }}
      {{- if hasKey $extraValues "enabled" }}
        {{- $isEnabled = $extraValues.enabled }}
      {{- end }}

      {{- if $isEnabled }}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  {{- if $env }}
  name: {{ printf "%s-extras-%s-%s" $chartBase $env $appNameSuffix }}
  {{- else }}
  name: {{ printf "%s-extras-%s" $chartBase $appNameSuffix }}
  {{- end }}
  namespace: argo-cd
  {{- if not (default false $.Values.preserveResourcesOnDeletion) }}
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  {{- end }}
  {{- include "tpl.argocd.application.annotations" $ | nindent 2 }}
spec:
  project: {{ $.Values.project }}
  source:
    repoURL: {{ $.Values.repoURL }}
    targetRevision: {{ $.Values.branch }}
    path: {{ printf "extras/%s/%s" $base $relDir }}
  destination:
    name: {{ $.Values.server }}
    namespace: {{ $.Values.namespace | default ($.Values.branch | replace "/" "-") }}
  revisionHistoryLimit: 3
  syncPolicy:
    {{- $autoConfig := dict "prune" true "selfHeal" true }}
    {{- if and (hasKey $extraValues "sync") (hasKey $extraValues.sync "automated") }}
      {{- $autoConfig = $extraValues.sync.automated }}
    {{- end }}
    {{- if $autoConfig }}
    automated: {{- toYaml $autoConfig | nindent 6 }}
    {{- end }}

    {{- $appOptions := ($extraValues.sync | default dict).options | default list }}
    {{- $globalOptions := $.Values.sync.options | default list }}
    syncOptions:
    {{- include "util.mergeSyncOptions" (dict "global" $globalOptions "app" $appOptions) | nindent 6 }}

    retry: {{ ($extraValues.sync | default dict).retry | default $.Values.sync.retry | toYaml | nindent 6 }}
---
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- if $rootFilesExist }}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  {{- if $env }}
  name: {{ printf "%s-extras-%s-root" $chartBase $env }}
  {{- else }}
  name: {{ printf "%s-extras-root" $chartBase }}
  {{- end }}
  namespace: argo-cd
  {{- if not (default false $.Values.preserveResourcesOnDeletion) }}
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  {{- end }}
  {{- include "tpl.argocd.application.annotations" $ | nindent 2 }}
spec:
  project: {{ $.Values.project }}
  source:
    repoURL: {{ $.Values.repoURL }}
    targetRevision: {{ $.Values.branch }}
    path: {{ printf "extras/%s" $base }}
    directory:
      recurse: false
      include: "*.yaml"
  destination:
    name: {{ $.Values.server }}
    namespace: {{ $.Values.namespace | default ($.Values.branch | replace "/" "-") }}
  revisionHistoryLimit: 3
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    {{- $.Values.sync.options | toYaml | nindent 6 }}
    retry: {{ $.Values.sync.retry | toYaml | nindent 6 }}
---
{{- end }}
{{- end }}

{{- define "tpl.argocd.application.annotations" }}
{{- if .Values.notification }}
annotations:
  {{- range $notifKey, $notifVal := .Values.notification }}
  {{- $channels := join "," $notifVal.channel }}
  {{- $t := $notifVal.template }}
  notifications.argoproj.io/subscribe.on-sync-succeeded.{{ $t }}: {{ $channels }}
  notifications.argoproj.io/subscribe.on-sync-failed.{{ $t }}: {{ $channels }}
  notifications.argoproj.io/subscribe.on-sync-running.{{ $t }}: {{ $channels }}
  notifications.argoproj.io/subscribe.on-health-degraded.{{ $t }}: {{ $channels }}
  notifications.argoproj.io/subscribe.on-health-unknown.{{ $t }}: {{ $channels }}
  notifications.argoproj.io/subscribe.on-sync-status-unknown.{{ $t }}: {{ $channels }}
  notifications.argoproj.io/subscribe.on-out-of-sync.{{ $t }}: {{ $channels }}
  notifications.argoproj.io/subscribe.on-deployed.{{ $t }}: {{ $channels }}
  {{- end }}
{{- end }}
{{- end }}
