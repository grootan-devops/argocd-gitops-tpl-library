{{- define "tpl.findPath" -}}
  {{- $ := .root -}}
  {{- $current := .current -}}
  {{- $target := .target -}}
  {{- $prefix := .prefix | default (list) -}}
  {{- range $k, $v := $current }}
    {{- if eq $k $target }}
      {{- $path := join "/" $prefix }}
      {{- if $path }}
        {{- if hasPrefix "apps/" $path }}
          {{- printf "%s/" (trimPrefix "apps/" $path) }}
        {{- else }}
          {{- printf "%s/" $path }}
        {{- end }}
      {{- end }}
    {{- else if kindIs "map" $v }}
      {{- $res := include "tpl.findPath" (dict "current" $v "target" $target "prefix" (append $prefix $k) "root" $) }}
      {{- if $res }}{{ $res }}{{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "tpl.getAppKey" -}}
  {{- $ := .root | default . -}}
  {{- $current := .current -}}
  {{- $target := .target -}}

  {{- range $k, $v := $current }}
    {{- if eq (toYaml $v | trim) (toYaml $target | trim) }}
      {{- printf "%s" $k }}
    {{- else if kindIs "map" $v }}
      {{- $res := include "tpl.getAppKey" (dict "current" $v "target" $target "root" $) }}
      {{- if $res }}{{ $res }}{{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "util.displayName" -}}
  {{- if .displayName }}
    {{- .displayName }}
  {{- else }}
    {{- $appKey := include "tpl.getAppKey" (dict "current" .Values "target" .appName) }}
    {{- include "util.kebabcase" $appKey }}
  {{- end }}
{{- end }}

{{- define "util.kebabcase" -}}
{{- $str := . -}}
{{- $step1 := regexReplaceAll "([a-z0-9])([A-Z])" $str "${1}-${2}" -}}
{{- $step2 := regexReplaceAll "([A-Z])([A-Z][a-z])" $step1 "${1}-${2}" -}}
{{- lower $step2 -}}
{{- end -}}

{{- define "util.mergeSyncOptions" -}}
{{- $globalList := .global | default list -}}
{{- $appList := .app | default list -}}

{{- $mergedMap := dict -}}
{{- range $item := $globalList -}}
  {{- $pair := splitList "=" $item -}}
  {{- if (eq (len $pair) 2) -}}
    {{- $_ := set $mergedMap (index $pair 0) (index $pair 1) -}}
  {{- end -}}
{{- end -}}

{{- range $item := $appList -}}
  {{- $pair := splitList "=" $item -}}
  {{- if (eq (len $pair) 2) -}}
    {{- $_ := set $mergedMap (index $pair 0) (index $pair 1) -}}
  {{- end -}}
{{- end -}}

{{- $finalList := list -}}
{{- range $key, $val := $mergedMap -}}
  {{- $finalList = append $finalList (printf "%s=%s" $key $val) -}}
{{- end -}}

{{- $finalList | toYaml -}}
{{- end -}}
