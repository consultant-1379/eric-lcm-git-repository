{{/*
Create the name for the configMap of backup and restore in CO
*/}}
{{- define "eric-lcm-git-repository.dataDocumentPG.coBrAgent" -}}
  {{ include "eric-lcm-git-repository.fullname" . }}-co-br-agent
{{- end -}}