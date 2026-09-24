{{- define "tpl.argocd.application" }}
---
{{- if $.Values.enabled }}
{{- $cluster := required "values.cluster is required to generate Argo CD application names" $.Values.cluster }}
{{- $isEnabled := true }}
{{- if hasKey .appName "enabled" }}
  {{- $isEnabled = .appName.enabled }}
{{- end }}
{{- if $isEnabled }}
{{- $nameSegments := list }}
{{- if .extras }}
  {{- $nameSegments = append $nameSegments "extras" }}
{{- else }}
  {{- if and .rootApp (ne .rootApp .Chart.Name) }}
    {{- $nameSegments = append $nameSegments (include "util.kebabcase" .rootApp) }}
  {{- end }}
  {{- $nameSegments = append $nameSegments (include "util.displayName" .) }}
{{- end }}
{{- $appName := include "tpl.argocd.applicationName" (dict "chartName" .Chart.Name "cluster" $cluster "segments" $nameSegments "environment" .Values.environment) }}
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
    {{- $appSync := (.appName).sync | default dict }}
    {{- if hasKey $appSync "automated" }}
    {{- if $appSync.automated }}
    automated: {{- $appSync.automated | toYaml | nindent 6 }}
    {{- else }}
    automated: {}
    {{- end }}
    {{- end }}
    {{- $appOptions := $appSync.options | default list }}
    {{- $globalOptions := $.Values.sync.options | default list }}
    syncOptions:
    {{- include "util.mergeSyncOptions" (dict "global" $globalOptions "app" $appOptions) | nindent 6 }}
    retry: {{ $appSync.retry | default .Values.sync.retry | toYaml | nindent 6 }}
  revisionHistoryLimit: 3
  {{- $globalIgnoreDifferences := $.Values.sync.ignoreDifferences | default list }}
  {{- $appIgnoreDifferences := (.appName).ignoreDifferences | default list }}
  {{- $ignoreDifferences := concat $globalIgnoreDifferences $appIgnoreDifferences }}
  {{- if $ignoreDifferences }}
  ignoreDifferences: {{ $ignoreDifferences | toYaml | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- define "tpl.argocd.application.extras.app" }}
source:
  repoURL: {{ $.Values.repoURL }}
  targetRevision: {{ include "tpl.argocd.targetRevision" $ }}
  path: extras
destination:
  name: {{ $.Values.server }}
  namespace: argo-cd
{{- end }}

{{- define "tpl.argocd.application.helm.app" -}}
{{- $rootApp := .rootApp }}
{{- $name := .name }}
{{- $displayName := include "util.displayName" . }}
{{- $targetRevision := include "tpl.argocd.targetRevision" $ }}
{{- $defaultNamespace := include "tpl.argocd.defaultNamespace" $ }}

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
  targetRevision: {{ $targetRevision }}
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
  namespace: {{ (.appName).namespace | default .groupNamespace | default .Values.namespace | default $defaultNamespace }}
  {{- else }}
  namespace: {{ (.appName).namespace | default .groupNamespace | default .Values.namespace | default $defaultNamespace }}
  {{- end }}
{{- end }}

{{- define "tpl.argocd.application.extras" }}
---
{{- $base := "manifests" }}
{{- $cluster := required "values.cluster is required to generate Argo CD application names" $.Values.cluster }}
{{- $targetRevision := include "tpl.argocd.targetRevision" $ }}
{{- $defaultNamespace := include "tpl.argocd.defaultNamespace" $ }}
{{- $seen := dict }}
{{- $extrasConfig := $.Values.extras | default dict }}
{{- $extrasEnabled := true }}
{{- if hasKey $extrasConfig "enabled" }}
  {{- $extrasEnabled = $extrasConfig.enabled }}
{{- end }}

{{/* Root-level manifests have no directory identity and intentionally create no Application. */}}
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

      {{- if and $isEnabled $extrasEnabled }}
{{- $extrasSync := $extrasConfig.sync | default dict }}
{{- $extraSync := $extraValues.sync | default dict }}
{{- $globalSync := $.Values.sync | default dict }}
{{- $ignoreDifferences := concat ($globalSync.ignoreDifferences | default list) ($extrasSync.ignoreDifferences | default list) ($extraValues.ignoreDifferences | default list) ($extraSync.ignoreDifferences | default list) }}
{{- $applicationName := include "tpl.argocd.applicationName" (dict "chartName" $.Chart.Name "cluster" $cluster "segments" (list "extras" $appNameSuffix) "environment" $.Values.environment) }}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {{ $applicationName }}
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
    targetRevision: {{ $targetRevision }}
    path: {{ printf "extras/%s/%s" $base $relDir }}
  destination:
    name: {{ $.Values.server }}
    namespace: {{ $.Values.namespace | default $defaultNamespace }}
  revisionHistoryLimit: 3
  syncPolicy:
    {{- $autoConfig := dict "prune" true "selfHeal" true }}
    {{- if hasKey $extrasSync "automated" }}
      {{- $autoConfig = $extrasSync.automated }}
    {{- end }}
    {{- if and (hasKey $extraValues "sync") (hasKey $extraValues.sync "automated") }}
      {{- $autoConfig = $extraValues.sync.automated }}
    {{- end }}
    {{- if $autoConfig }}
    automated: {{- toYaml $autoConfig | nindent 6 }}
    {{- end }}

    {{- $appOptions := $extraSync.options | default list }}
    {{- $globalOptions := concat ($globalSync.options | default list) ($extrasSync.options | default list) }}
    syncOptions:
    {{- include "util.mergeSyncOptions" (dict "global" $globalOptions "app" $appOptions) | nindent 6 }}

    {{- $retry := $globalSync.retry | default dict }}
    {{- if $extrasSync.retry }}
      {{- $retry = $extrasSync.retry }}
    {{- end }}
    {{- $retry = $extraSync.retry | default $retry }}
    retry: {{ $retry | toYaml | nindent 6 }}
  {{- if $ignoreDifferences }}
  ignoreDifferences: {{ $ignoreDifferences | toYaml | nindent 4 }}
  {{- end }}
---
      {{- end }}
    {{- end }}
{{- end }}
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
