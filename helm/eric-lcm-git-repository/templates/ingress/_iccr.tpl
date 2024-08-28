{{/*
  Predefined ICCR Service Annotations.
*/}}
{{- define "eric-lcm-git-repository.iccrPredefinedServiceAnnotations" -}}
{{- if .Values.service.maxConnections }}
projectcontour.io/max-connections: {{ .Values.service.maxConnections | quote }}
{{- end -}}
{{- if .Values.service.maxPendingRequests }}
projectcontour.io/max-pending-requests: {{ .Values.service.maxPendingRequests | quote }}
{{- end -}}
{{- if .Values.service.maxRequests }}
projectcontour.io/max-requests: {{ .Values.service.maxRequests | quote }}
{{- end }}
{{- end -}}


{{/*
  Predefined ICCR HTTPProxy Annotations.
*/}}
{{- define "eric-lcm-git-repository.iccrPredefinedHttpProxyAnnotations" -}}
{{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
{{- if .Values.ingress.ingressClass }}
    kubernetes.io/ingress.class: {{ .Values.ingress.ingressClass | quote }}
{{- else if $global.ingress.ingressClass }}
    kubernetes.io/ingress.class: {{ $global.ingress.ingressClass | quote }}
{{- end }}
{{- end -}}


{{/*
  Effective ICCR HTTPProxy annotations.
*/}}
{{- define "eric-lcm-git-repository.iccrHttpProxyAnnotations" -}}
  {{- $httpProxyValues := include "eric-lcm-git-repository.iccrPredefinedHttpProxyAnnotations" . | fromYaml -}}
  {{- $annotationsFromValues := .Values.ingress.annotations -}}
  {{- $config := include "eric-lcm-git-repository.annotations" . | fromYaml -}}
  {{- include "eric-lcm-git-repository.mergeAnnotations" (dict "location" .Template.Name "sources" (list $httpProxyValues $annotationsFromValues $config)) | trim }}
{{- end -}}


{{/*
  Defines Ingress CA certificate secret contributor for webserver.
  Item of the Certificate Context truststore.items to be included in the webserver truststore.
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.iccrWebWebServerTrustCACertContributor" -}}
{{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
  {{- if .Values.ingress.enabled -}}
ingress:
  secretName: {{ .Values.ingress.serviceReference }}-client-ca
  {{- else if $global.ingress.ingressClass -}}
ingress:
  secretName: {{ $global.ingress.serviceReference }}-client-ca
  {{- end -}}
{{- end -}}


{{/*
  Defines ICCR Ingress network policy rule.
  Kubernetes []NetworkPolicyIngressRule Item in NetworkPolicySpec.
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.networkPolicyIngressIccrRule" -}}
ingress:
  - from:
      - podSelector:
          matchLabels:
            {{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
            {{- if .Values.ingress.ingressClass }}
            app.kubernetes.io/name: {{ .Values.ingress.serviceReference | quote }}
            {{- else if $global.ingress.ingressClass }}
            app.kubernetes.io/name: {{ $global.ingress.serviceReference | quote }}
            {{- else if .Values.ingress.serviceReference }}
            app.kubernetes.io/name: {{ .Values.ingress.serviceReference | quote }}
            {{- else }}
            app.kubernetes.io/name: {{ $global.ingress.serviceReference | quote }}
            {{- end }}
    ports:
      - protocol: TCP
        port: 8443
{{- end -}}


{{/*
  Defines ICCR Ingress network policy.
  Kubernetes NetworkPolicy.
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.networkPolicyIngressIccr" -}}
{{- $args := dict "rules" (include "eric-lcm-git-repository.networkPolicyIngressIccrRule" . | fromYaml) -}}
{{- $_ := set $args "suffix" "iccr-access" -}}
{{- $_ := set $args "policyType" "Ingress" -}}
{{- include "eric-lcm-git-repository.networkPolicyBaseSpec"  (list $ $args) -}}
{{- end -}}
