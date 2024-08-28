{{/*
Merge global tolerations with service tolerations (DR-D1120-061-AD).
*/}}
{{- define "eric-lcm-git-repository.merge-tolerations" -}}
  {{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) }}
  {{- if $global.tolerations }}
      {{- $globalTolerations := $global.tolerations -}}
      {{- $serviceTolerations := list -}}
      {{- if .Values.tolerations -}}
        {{- if eq (typeOf .Values.tolerations) ("[]interface {}") -}}
          {{- $serviceTolerations = .Values.tolerations -}}
        {{- else if eq (typeOf .Values.tolerations) ("map[string]interface {}") -}}
          {{- $serviceTolerations = index .Values.tolerations .podbasename -}}
        {{- end -}}
      {{- end -}}
      {{- $result := list -}}
      {{- $nonMatchingItems := list -}}
      {{- $matchingItems := list -}}
      {{- range $globalItem := $globalTolerations -}}
        {{- $globalItemId := include "eric-lcm-git-repository.merge-tolerations.get-identifier" $globalItem -}}
        {{- range $serviceItem := $serviceTolerations -}}
          {{- $serviceItemId := include "eric-lcm-git-repository.merge-tolerations.get-identifier" $serviceItem -}}
          {{- if eq $serviceItemId $globalItemId -}}
            {{- $matchingItems = append $matchingItems $serviceItem -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
      {{- range $globalItem := $globalTolerations -}}
        {{- $globalItemId := include "eric-lcm-git-repository.merge-tolerations.get-identifier" $globalItem -}}
        {{- $matchCount := 0 -}}
        {{- range $matchItem := $matchingItems -}}
          {{- $matchItemId := include "eric-lcm-git-repository.merge-tolerations.get-identifier" $matchItem -}}
          {{- if eq $matchItemId $globalItemId -}}
            {{- $matchCount = add1 $matchCount -}}
          {{- end -}}
        {{- end -}}
        {{- if eq $matchCount 0 -}}
          {{- $nonMatchingItems = append $nonMatchingItems $globalItem -}}
        {{- end -}}
      {{- end -}}
      {{- range $serviceItem := $serviceTolerations -}}
        {{- $serviceItemId := include "eric-lcm-git-repository.merge-tolerations.get-identifier" $serviceItem -}}
        {{- $matchCount := 0 -}}
        {{- range $matchItem := $matchingItems -}}
          {{- $matchItemId := include "eric-lcm-git-repository.merge-tolerations.get-identifier" $matchItem -}}
          {{- if eq $matchItemId $serviceItemId -}}
            {{- $matchCount = add1 $matchCount -}}
          {{- end -}}
        {{- end -}}
        {{- if eq $matchCount 0 -}}
          {{- $nonMatchingItems = append $nonMatchingItems $serviceItem -}}
        {{- end -}}
      {{- end -}}
      {{- toYaml (concat $result $matchingItems $nonMatchingItems) -}}
  {{- else -}}
      {{- if .Values.tolerations -}}
        {{- if eq (typeOf .Values.tolerations) ("[]interface {}") -}}
          {{- toYaml .Values.tolerations -}}
        {{- else if eq (typeOf .Values.tolerations) ("map[string]interface {}") -}}
          {{- toYaml (index .Values.tolerations .podbasename) -}}
        {{- end -}}
      {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Helper function to get the identifier of a tolerations array element.
Assumes all keys except tolerationSeconds are used to uniquely identify
a tolerations array element.
*/}}
{{ define "eric-lcm-git-repository.merge-tolerations.get-identifier" }}
  {{- $keyValues := list -}}
  {{- range $key := (keys . | sortAlpha) -}}
    {{- if eq $key "effect" -}}
      {{- $keyValues = append $keyValues (printf "%s=%s" $key (index $ $key)) -}}
    {{- else if eq $key "key" -}}
      {{- $keyValues = append $keyValues (printf "%s=%s" $key (index $ $key)) -}}
    {{- else if eq $key "operator" -}}
      {{- $keyValues = append $keyValues (printf "%s=%s" $key (index $ $key)) -}}
    {{- else if eq $key "value" -}}
      {{- $keyValues = append $keyValues (printf "%s=%s" $key (index $ $key)) -}}
    {{- end -}}
  {{- end -}}
  {{- printf "%s" (join "," $keyValues) -}}
{{ end }}
