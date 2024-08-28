{{/*
  Defines Volumes for Initializer Container
*/}}
{{- define "eric-lcm-git-repository.initializerVolumes" -}}
{{ include "eric-lcm-git-repository.initializerConfigDirVolume" . }}
{{ include "eric-lcm-git-repository.ericSecSipTlsTrustedRootCertVolume" .}}
{{ include "eric-lcm-git-repository.ericSecSipTlsInitPgCertVolume" .}}
{{- end -}}

{{/*
  Defines Volume Mounts for Initializer Container
*/}}
{{/*
  Defines Initliazer Volumes Mounts.
  Kubernetes []VolumeMount Items in PodSpec/[]Container.
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.initializerVolumeMounts" -}}
{{ include "eric-lcm-git-repository.initializerConfigVolumeMount" . }}
{{ include "eric-lcm-git-repository.ericSecSipTlsInitPgCertVolumeMount" . }}
{{ include "eric-lcm-git-repository.ericSecSipTlsTrustedRootCertVolumeMount" . }}
{{- end -}}

{{/*
  Defines init-config Volume for Initializer Container
*/}}
{{- define "eric-lcm-git-repository.initializerConfigDirVolume" -}}
- name: init-config
  configMap:
    name: {{ include "eric-lcm-git-repository.name" . }}-initializer-cm
{{- end -}}

{{/*
  Defines init-config Volume Mount for Initializer Container
*/}}
{{- define "eric-lcm-git-repository.initializerConfigVolumeMount" -}}
- mountPath: /home/init/config
  name: init-config
{{- end -}}