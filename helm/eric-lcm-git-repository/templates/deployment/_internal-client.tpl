{{/*
  Defines Internal Client Deployment Volumes.
  Kubernetes []Volume Items in PodSpec.
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.internalClientVolumes" -}}
{{- $internalClientCertContext := include "eric-lcm-git-repository.internalClientCertContext" . | fromYaml -}}
{{- include "eric-lcm-git-repository.certificateVolumes" (list $ . $internalClientCertContext) }}
{{- end -}}


{{/*
  Defines Internal Client Container Volumes Mounts.
  Kubernetes []VolumeMount Items in PodSpec/[]Container.
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.internalClientVolumeMounts" -}}
{{- $internalClientCertContext := include "eric-lcm-git-repository.internalClientCertContext" . | fromYaml -}}
{{- include "eric-lcm-git-repository.certificateVolumeMounts" (list $ . $internalClientCertContext) }}
{{- end -}}


{{/*
  Defines Internal Client Certificate Context.
  As indicated at _cert.tpl Certificate Context Structure.
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.internalClientCertContext" -}}
{{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
id: internal-client
type: client
enabled: {{ $global.security.tls.enabled }}
keystore:
  secretName: {{ include "eric-lcm-git-repository.internalClientCertSecretName" . }}
  optional: {{ ne .Values.service.endpoints.gitRepository.tls.verifyClientCertificate "required" }}
truststore:
  items:
    sip-tls-trusted-root-cert:
      existingVolumeName: sip-tls-trusted-root-cert
{{- end -}}


{{/*
  Defines Internal Client Client Certificate Secret Name.
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.internalClientCertSecretName" -}}
{{ include "eric-lcm-git-repository.name" . }}-internal-client-cert
{{- end -}}
