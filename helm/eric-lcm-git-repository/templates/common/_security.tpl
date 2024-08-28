{{/*
  Define the role reference for security policy
*/}}
{{- define "eric-lcm-git-repository.securityPolicy.reference" -}}
{{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
{{- index $global.security.policyReferenceMap "default-restricted-security-policy" | default "default-restricted-security-policy" | quote }}
{{- end -}}
