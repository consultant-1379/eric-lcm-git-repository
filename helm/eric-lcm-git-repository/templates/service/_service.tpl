{{/*
  Merged annotations for Default, which includes Project Contour and Config
*/}}
{{- define "eric-lcm-git-repository.serviceAnnotations" -}}
  {{- $contour := include "eric-lcm-git-repository.iccrPredefinedServiceAnnotations" . | fromYaml -}}
  {{- $config := include "eric-lcm-git-repository.annotations" . | fromYaml -}}
  {{- include "eric-lcm-git-repository.mergeAnnotations" (dict "location" .Template.Name "sources" (list $contour $config)) | trim }}
{{- end -}}
