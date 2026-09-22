{{- define "tpl.argocd.applications" }}
  {{- $ctx := . }}
  {{- if .Values.apps }}
    {{- range $rootName, $rootApp := .Values.apps }}

      {{- $rootEnabled := true }}
      {{- $rootNamespace := "" }}
      {{- if kindIs "map" $rootApp }}
        {{- if hasKey $rootApp "enabled" }}{{ $rootEnabled = $rootApp.enabled }}{{ end }}
        {{- if hasKey $rootApp "namespace" }}{{ $rootNamespace = $rootApp.namespace }}{{ end }}
      {{- end }}

      {{- if $rootEnabled }}
        {{- if hasKey $rootApp "chart" }}
          {{- $path := printf "values/%s.yaml" (include "util.kebabcase" $rootName) }}
          {{- include "tpl.argocd.application" (merge (dict "name" $rootName "appName" $rootApp "displayName" (include "util.kebabcase" $rootName) "rootApp" "" "valuesPath" $path) $ctx) }}
        {{- else }}
          {{- range $childName, $childApp := $rootApp }}

            {{- if kindIs "map" $childApp }}
              {{- $childEnabled := true }}
              {{- $childNamespace := $rootNamespace }}

              {{- if hasKey $childApp "enabled" }}{{ $childEnabled = $childApp.enabled }}{{ end }}
              {{- if hasKey $childApp "namespace" }}{{ $childNamespace = $childApp.namespace }}{{ end }}

              {{- if $childEnabled }}
                {{- if hasKey $childApp "chart" }}
                  {{- $path := printf "values/%s/%s.yaml" $rootName (include "util.kebabcase" $childName) }}
                  {{- include "tpl.argocd.application" (merge (dict "name" $childName "appName" $childApp "displayName" (include "util.kebabcase" $childName) "rootApp" $rootName "valuesPath" $path "groupNamespace" $rootNamespace) $ctx) }}
                {{- else }}
                    {{- range $grandChildName, $grandChildApp := $childApp }}
                      {{- if kindIs "map" $grandChildApp }}
                        {{- $grandChildEnabled := true }}
                        {{- if hasKey $grandChildApp "enabled" }}{{ $grandChildEnabled = $grandChildApp.enabled }}{{ end }}
                        
                        {{- if $grandChildEnabled }}
                            {{- if hasKey $grandChildApp "chart" }}
                              {{- $compositeName := printf "%s-%s" (include "util.kebabcase" $childName) (include "util.kebabcase" $grandChildName) }}
                              {{- $path := printf "values/%s/%s/%s.yaml" $rootName (include "util.kebabcase" $childName) (include "util.kebabcase" $grandChildName) }}
                              {{- include "tpl.argocd.application" (merge (dict "name" $grandChildName "appName" $grandChildApp "displayName" $compositeName "rootApp" $rootName "valuesPath" $path "groupNamespace" $childNamespace) $ctx) }}
                           {{- end }}
                        {{- end }}
                      {{- end }}
                    {{- end }}
                {{- end }}
              {{- end }}
            {{- end }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- $renderExtras := true }}
  {{- if and .Values.extras (hasKey .Values.extras "enabled") }}
    {{- $renderExtras = .Values.extras.enabled }}
  {{- end }}

  {{- if and .Values.extras $renderExtras }}
    {{- include "tpl.argocd.application" (merge (dict "appName" .Values.extras "extras" true "name" "extras") $) }}
  {{- end }}
{{- end }}
