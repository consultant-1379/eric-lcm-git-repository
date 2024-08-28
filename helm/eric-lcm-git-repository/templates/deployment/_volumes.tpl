{{/*
  Defines Pod Deployment Volumes.
  Kubernetes []Volume Items in PodSpec.
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.volumes" -}}
{{ include "eric-lcm-git-repository.tmpDirVolume" . }}
{{ include "eric-lcm-git-repository.dataDirVolume" . }}
{{ include "eric-lcm-git-repository.initDirVolume" . }}
{{ include "eric-lcm-git-repository.inlineConfigDirVolume" . }}
{{ include "eric-lcm-git-repository.configDirVolume" . }}
{{ include "eric-lcm-git-repository.ericSecSipTlsTrustedRootCertVolume" .}}
{{ include "eric-lcm-git-repository.ericSecSipTlsPgCertVolume" .}}
{{- end -}}


{{/*
  Defines Pod Container Volumes Mounts.
  Kubernetes []VolumeMount Items in PodSpec/[]Container.
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.volumeMounts" -}}
{{ include "eric-lcm-git-repository.tmpDirVolumeMount" . }}
{{ include "eric-lcm-git-repository.dataDirVolumeMount" . }}
{{- end -}}

{{/*
  Defines Pod Container Volumes Mounts.
  Kubernetes []VolumeMount Items in PodSpec/[]Container.
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.initVolumeMounts" -}}
{{ include "eric-lcm-git-repository.tmpDirVolumeMount" . }}
{{ include "eric-lcm-git-repository.dataDirVolumeMount" . }}
{{ include "eric-lcm-git-repository.initDirVolumeMount" . }}
{{- end -}}


{{/*
  Defines Pod Container Volumes Mounts.
  Kubernetes []VolumeMount Items in PodSpec/[]Container.
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.initAppIniVolumeMounts" -}}
{{ include "eric-lcm-git-repository.tmpDirVolumeMount" . }}
{{ include "eric-lcm-git-repository.dataDirVolumeMount" . }}
{{ include "eric-lcm-git-repository.inlineConfigDirVolumeMount" . }}
{{ include "eric-lcm-git-repository.configDirVolumeMount" . }}
{{- end -}}

{{/*
  Defines Pod Container Volumes Mounts.
  Kubernetes []VolumeMount Items in PodSpec/[]Container.
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.configureGiteaVolumeMounts" -}}
{{ include "eric-lcm-git-repository.initDirVolumeMount" . }}
{{ include "eric-lcm-git-repository.tmpDirVolumeMount" . }}
{{ include "eric-lcm-git-repository.dataDirVolumeMount" . }}
{{ include "eric-lcm-git-repository.ericSecSipTlsPgCertVolumeMount" . }}
{{ include "eric-lcm-git-repository.ericSecSipTlsTrustedRootCertVolumeMount" . }}
{{- end -}}

{{/*
  Defines SIP-TLS trusted root ca volume.
  Kubernetes []Volume item in PodSpec.
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.ericSecSipTlsTrustedRootCertVolume" -}}
{{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
  {{- if $global.security.tls.enabled -}}
- name: sip-tls-trusted-root-cert
  secret:
    secretName: {{ $global.security.tls.trustedInternalRootCa.secret }}
    defaultMode: 0600
  {{- end -}}
{{- end -}}

{{- define "eric-lcm-git-repository.ericSecSipTlsTrustedRootCertVolumeMount" -}}
{{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
  {{- if $global.security.tls.enabled -}}
- mountPath: /run/secrets/root
  name: sip-tls-trusted-root-cert
  {{- end -}}
{{- end -}}

{{- define "eric-lcm-git-repository.ericSecSipTlsInitPgCertVolume" -}}
{{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
  {{- if $global.security.tls.enabled -}}
- name: pg-certs
  secret:
    secretName: {{ include "eric-lcm-git-repository.name" . }}-init-su-pg-cert
  {{- end -}}
{{- end -}}

{{- define "eric-lcm-git-repository.ericSecSipTlsInitPgCertVolumeMount" -}}
{{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
  {{- if $global.security.tls.enabled -}}
- mountPath: /run/secrets/pg
  name: pg-certs
  {{- end -}}
{{- end -}}

{{- define "eric-lcm-git-repository.ericSecSipTlsPgCertVolume" -}}
{{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
  {{- if $global.security.tls.enabled -}}
- name: pg-certs
  secret:
    secretName: {{ .Values.serviceMesh.egress.documentdatabasepg.genSecretName }}
    defaultMode: 0600
  {{- end -}}
{{- end -}}

{{- define "eric-lcm-git-repository.ericSecSipTlsPgCertVolumeMount" -}}
{{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
  {{- if $global.security.tls.enabled -}}
- mountPath: /run/secrets/pg
  name: pg-certs
  {{- end -}}
{{- end -}}

{{/*
  Defines an in-memory EmptyDir volume item to store sensitive data.
  Kubernetes []Volume item in PodSpec.
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.memFsVolume" -}}
- name: memfsdir
  emptyDir:
    medium: Memory
    sizeLimit: 1Mi
{{- end -}}

{{/*
  Defines an in-memory EmptyDir volume mount item to store sensitive data.
  Kubernetes []VolumeMount item in PodSpec/[]Container.
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.memFsVolumeMount" -}}
- name: memfsdir
  mountPath: /opt/application/memfs
{{- end -}}


{{/*
  Defines EmptyDir volume for temp directory.
  Kubernetes []Volume Items in PodSpec.
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.tmpDirVolume" -}}
- name: tmpdir
  emptyDir:
    sizeLimit: 16Mi
{{- end -}}


{{/*
  Defines EmptyDir volume mount for temp directory.
  Kubernetes []VolumeMount Items in PodSpec/[]Container.
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.tmpDirVolumeMount" -}}
- name: tmpdir
  mountPath: /tmp
{{- end -}}

{{/*
  Defines the datadir volume for gitea storage
*/}}
{{- define "eric-lcm-git-repository.dataDirVolume" -}}
- name: data
  persistentVolumeClaim:
    claimName: {{ include "eric-lcm-git-repository.name" . }}-shared-volume
{{- end -}}

{{/*
  Defines the datadir volume mount for gitea storage
*/}}
{{- define "eric-lcm-git-repository.dataDirVolumeMount" -}}
- name: data
  mountPath: /data
{{- end -}}

{{/*
  Defines the initdir volume for gitea storage
*/}}
{{- define "eric-lcm-git-repository.initDirVolumeMount" -}}
- name: init
  mountPath: /usr/sbin/gitea
{{- end -}}

{{/*
  Defines the initdir volume mount for gitea storage
*/}}
{{- define "eric-lcm-git-repository.initDirVolume" -}}
- name: init
  secret:
    secretName: {{ include "eric-lcm-git-repository.name" . }}-init
    defaultMode: 110
{{- end -}}

{{/*
  Defines the configdir volume mount for gitea storage
*/}}
{{- define "eric-lcm-git-repository.configDirVolume" -}}
- name: init-config
  secret:
    secretName: {{ include "eric-lcm-git-repository.name" . }}
    defaultMode: 110
{{- end -}}

{{/*
  Defines the configdir volume for gitea storage
*/}}
{{- define "eric-lcm-git-repository.configDirVolumeMount" -}}
- name: init-config
  mountPath: /usr/sbin/gitea
{{- end -}}


{{/*
  Defines the configdir volume mount for gitea storage
*/}}
{{- define "eric-lcm-git-repository.inlineConfigDirVolume" -}}
- name: inline-config-sources
  secret:
    secretName: {{ include "eric-lcm-git-repository.name" . }}-inline-config
    defaultMode: 110
{{- end -}}

{{/*
  Defines the configdir volume for gitea storage
*/}}
{{- define "eric-lcm-git-repository.inlineConfigDirVolumeMount" -}}
- name: inline-config-sources
  mountPath: /env-to-ini-mounts/inlines/
{{- end -}}
