{{/* vim: set filetype=mustache: */}}

{{/*
SM Design Rule DR-D470217-007-AD 
Sidecar proxy should be injected and service mesh related configuration should be created only if
serviceMesh is enabled globally and at service level
*/}}
{{- define "eric-lcm-git-repository.serviceMesh.enabled" -}}
{{- $gitrepositorySM := false -}}
{{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
{{- if $global.serviceMesh.enabled -}}
    {{- if .Values.serviceMesh -}}
        {{- if .Values.serviceMesh.enabled -}}
            {{- $gitrepositorySM = true -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- $gitrepositorySM -}}
{{- end -}}


{{- define "eric-lcm-git-repository.sidecar-volumes" -}}
{{- $type:= index . "Type" -}}
{{ $annotations:= dict -}}
    {{- if (.Values).serviceMesh }}
        {{- if hasKey (.Values).serviceMesh $type }}
            {{- range $k, $v := index .Values "serviceMesh" $type -}}
                {{- if kindIs "map" $v -}}
                    {{- if (hasKey $v "genSecretName") -}}
                        {{- $enabled := $v.enabled -}}
                        {{- $secretName := printf "%s-%s-secret" $type $k -}}
                        {{- $genSecretName := $v.genSecretName -}}
                        {{- $optional := $v.optional -}}

                        {{$secretDict:= dict}}
                        {{- if eq $k "ca" -}}
                            {{- $secretDict := merge $secretDict (dict "secretName" $genSecretName) -}}
                            {{- $annotations := merge $annotations (dict $secretName (dict "secret" $secretDict)) -}}
                        {{- else if $enabled -}}
                            {{- $secretDict := merge $secretDict (dict "secretName" $genSecretName) -}}
                            {{- if $optional -}}
                            {{- $secretDict := merge $secretDict (dict "optional" ($optional | toString )) -}}
                            {{- end -}}
                            {{- $annotations := merge $annotations (dict $secretName (dict "secret" $secretDict)) -}}
                        {{- end -}}
                    {{- end -}}
                {{- end -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- $annotations | toJson -}}
{{- end -}}

{{- define "eric-lcm-git-repository.sidecar-volumeMounts" -}}
{{- $type:= index . "Type" -}}
{{ $annotations:= dict -}}
    {{- if (.Values).serviceMesh }}
        {{- if hasKey (.Values).serviceMesh $type }}
            {{- range $k, $v := index .Values "serviceMesh" $type -}}
                {{- if kindIs "map" $v -}}
                        {{- if (hasKey $v "genSecretName") -}}
                            {{- $enabled := $v.enabled -}}
                            {{- $secretName := printf "%s-%s-secret" $type $k -}}
                            {{- $readOnly := $v.readOnly -}}
                            {{$secretDict:= dict}}
                            {{- if eq $k "ca" -}}
                                {{- if ( kindIs "invalid" $v.caCertsPath ) }}
                                    {{ fail (printf "caCertsPath is required for mounting %s secret %s" $type $k) }}
                                {{- end -}}
                                {{- $secretDict := merge $secretDict (dict "mountPath" $v.caCertsPath) -}}
                            {{- else if $enabled -}}
                                {{- if ( kindIs "invalid" $v.certsPath ) }}
                                    {{ fail (printf "certsPath is required for mounting %s secret %s" $type $k) }}
                                {{- end -}}
                                {{- $secretDict := merge $secretDict (dict "mountPath" $v.certsPath) -}}
                                {{- if $readOnly -}}
                                {{- $secretDict := merge $secretDict (dict "readOnly" ($readOnly | toString )) -}}
                                {{- end -}}
                            {{- end -}}
                            {{- if ne (len $secretDict) 0 -}}
                            {{- $annotations := merge $annotations (dict $secretName $secretDict) -}}
                            {{- end -}}
                        {{- end -}}
                {{- end -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- $annotations | toJson -}}
{{- end -}}


{{/* 
SM DR-D470217-001 SM DR-D470217-011 Control sidecar injection
*/}}
{{- define "eric-lcm-git-repository.istio-sidecar-annotations" -}}
{{ $gitrepositorySM := include "eric-lcm-git-repository.serviceMesh.enabled" . }}
{{ $global := fromYaml (include "eric-lcm-git-repository.global" .) }}
proxy.istio.io/config: '{ "holdApplicationUntilProxyStarts": true }'
sidecar.istio.io/rewriteAppHTTPProbers: {{ $gitrepositorySM | quote }}
{{- if $global.security.tls.enabled }}
{{ $egressVolumes := include "eric-lcm-git-repository.sidecar-volumes" (dict "Values" .Values "Type" "egress" ) | fromJson -}}
{{- $ingressVolumes := include "eric-lcm-git-repository.sidecar-volumes" (dict "Values" .Values "Type" "ingress" ) | fromJson -}}
{{- $volumes := merge $egressVolumes $ingressVolumes -}}
{{- if hasKey ((.Values).serviceMesh) "sidecarAnnotations" -}}
    {{- if hasKey ((.Values).serviceMesh).sidecarAnnotations "userVolumes" -}}
        {{- if (((.Values).serviceMesh).sidecarAnnotations).userVolumes -}}
            {{- $sanitizedExtraVolumes := (((.Values).serviceMesh).sidecarAnnotations).userVolumes | trimAll "'" | fromJson }}
            {{- $volumes = mergeOverwrite $volumes $sanitizedExtraVolumes -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- if $volumes -}}
sidecar.istio.io/userVolume: {{$volumes | toJson | squote}}
{{- end -}}
{{ $egressVolumeMounts := include "eric-lcm-git-repository.sidecar-volumeMounts" (dict "Values" .Values "Type" "egress" ) | fromJson }}
{{ $ingressVolumeMounts := include "eric-lcm-git-repository.sidecar-volumeMounts" (dict "Values" .Values "Type" "ingress" ) | fromJson }}
{{- $volumeMounts := merge $egressVolumeMounts $ingressVolumeMounts -}}
{{- if hasKey ((.Values).serviceMesh) "sidecarAnnotations" -}}
    {{- if hasKey ((.Values).serviceMesh).sidecarAnnotations "userVolumeMounts" -}}
        {{- if (((.Values).serviceMesh).sidecarAnnotations).userVolumeMounts -}}
            {{- $sanitizedExtraVolumeMounts := (((.Values).serviceMesh).sidecarAnnotations).userVolumeMounts | trimAll "'" | fromJson }}
            {{- $volumeMounts = mergeOverwrite $volumeMounts $sanitizedExtraVolumeMounts -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- if $volumeMounts -}}
sidecar.istio.io/userVolumeMount: {{$volumeMounts | toJson | squote}}
{{- end -}}
{{- end -}}
{{- with (((.Values).global).serviceMesh).annotations }}
{{  toYaml . }}
{{- end }}
{{- end -}}

{{/* 
SM DR-D470217-011 Control sidecar injection
*/}}
{{- define "eric-lcm-git-repository.istio-sidecar-inject" -}}
{{ $gitrepositorySM := include "eric-lcm-git-repository.serviceMesh.enabled" . }}
sidecar.istio.io/inject: {{ $gitrepositorySM | quote }}
{{- end -}}

{{/*
Istio Labels
*/}}
{{- define "eric-lcm-git-repository.istio-sidecar-labels" -}}
{{ $gitrepositorySM := include "eric-lcm-git-repository.serviceMesh.enabled" . }}
{{ $istioLabels := include "eric-lcm-git-repository.istio-sidecar-inject" . | fromYaml }}
{{- if $gitrepositorySM }}
{{- if .Values.serviceMesh.labels }}
{{ $istioLabels := merge $istioLabels .Values.serviceMesh.labels }}
{{- end -}}
{{- end -}}
{{- $istioLabels | toYaml }}
{{- end -}}


{{/*
  TLS Cert secret pg
*/}}
{{- define "eric-lcm-git-repository.tls-certificate-secret" -}}
{{- printf "file-cert:%stls.crt~%stls.key" (.Values.serviceMesh.egress.documentdatabasepg.certsPath) (.Values.serviceMesh.egress.documentdatabasepg.certsPath) -}}
{{- end -}}


{{/*
  TLS Validation secret
*/}}
{{- define "eric-lcm-git-repository.tls-validation-secret" -}}
{{- printf "file-root:%s" (include "eric-lcm-git-repository.egress-ca-cert" .) -}}
{{- end -}}


{{/*
Service mesh Database configurations
*/}}
{{/*
 Database - Egress client certificate
*/}}
{{- define "eric-lcm-git-repository.egress-db-client-cert" -}}
{{- printf "%stls.crt" (.Values.serviceMesh.egress.documentdatabasepg.certsPath) -}}
{{- end -}}

{{/*
 Database - Egress private key
*/}}
{{- define "eric-lcm-git-repository.egress-db-private-key" -}}
{{- printf "%stls.key" (.Values.serviceMesh.egress.documentdatabasepg.certsPath) -}}
{{- end -}}

{{/*
  Egress CA certs
*/}}
{{- define "eric-lcm-git-repository.egress-ca-cert" -}}
{{- printf "%sca.crt" (.Values.serviceMesh.egress.ca.caCertsPath) -}}
{{- end -}}


{{/*
Service mesh Redis configurations
*/}}
{{/*
 Redis - Egress client certificate
*/}}
{{- define "eric-lcm-git-repository.egress-redis-client-cert" -}}
{{- printf "%stls.crt" (.Values.serviceMesh.egress.keyvaluedatabaserd.certsPath) -}}
{{- end -}}

{{/*
 Redis - Egress private key
*/}}
{{- define "eric-lcm-git-repository.egress-redis-private-key" -}}
{{- printf "%stls.key" (.Values.serviceMesh.egress.keyvaluedatabaserd.certsPath) -}}
{{- end -}}