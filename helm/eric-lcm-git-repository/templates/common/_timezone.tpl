{{/*
  Configure timezone.
*/}}
{{- define "eric-lcm-git-repository.timezone" -}}
  {{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
  {{- $location := "UTC" -}}
  {{- $utcFormats := (list "Etc/UCT" "Etc/Universal" "Etc/UTC" "Etc/Zulu" "UCT" "Universal" "UTC" "Zulu") -}}
  {{- if $global.timezone -}}
    {{- $location = dateInZone "MST" (now) $global.timezone -}}
    {{- if or (ne $location "UTC") (has $global.timezone $utcFormats) -}}
      {{- $location = $global.timezone -}}
    {{- end -}}
  {{- end -}}
  {{- print $location -}}
{{- end -}}


{{/*
  Check if timezone value is invalid.
*/}}
{{- define "eric-lcm-git-repository.isTimezoneInvalid" -}}
  {{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
  {{- $location := include "eric-lcm-git-repository.timezone" . -}}
  {{- if and $global.timezone (eq $location "UTC") (ne $global.timezone "UTC") -}}
    true
  {{- end -}}
{{- end -}}


{{/*
  Log an invalid timezone warning message.
*/}}
{{- define "eric-lcm-git-repository.invalidTimezoneWarning" -}}
  {{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
  {{- if include "eric-lcm-git-repository.isTimezoneInvalid" . }}
{{ printf "WARNING: The configured timezone %s is invalid, set the correct value in the global.timezone parameter." $global.timezone }}
  {{- end }}
{{- end -}}
