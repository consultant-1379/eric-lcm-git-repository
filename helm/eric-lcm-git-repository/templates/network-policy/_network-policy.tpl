{{- define "eric-lcm-git-repository.networkPolicyBaseSpec" -}}
{{- $ := index . 0 -}}{{- $args := index . 1 -}}
{{- with $ -}}
{{- if (include "eric-lcm-git-repository.networkPolicies.enabled" .) -}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "eric-lcm-git-repository.name" . }}-{{ $args.suffix }}
  labels: {{ include "eric-lcm-git-repository.labels" . | nindent 4 }}
  annotations: {{- include "eric-lcm-git-repository.annotations" . | nindent 4 }}
spec:
  podSelector:
    matchLabels:
        app.kubernetes.io/name: {{ include "eric-lcm-git-repository.name" . }}
  policyTypes:
  - {{ $args.policyType }}
  {{- $args.rules | toYaml | nindent 2 }}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
  Defines Unknown Peers Ingress network policy rule.
  Kubernetes []NetworkPolicyIngressRule Item in NetworkPolicySpec.
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.networkPolicyIngressDefaultAccessRule" -}}
ingress:
  - from:
      - podSelector:
          matchLabels:
            {{ include "eric-lcm-git-repository.name" . }}-access: "true"
{{- end -}}


{{/*
  Defines Unknown Peers Ingress network policy.
  Kubernetes NetworkPolicy.
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.networkPolicyIngressDefaultAccess" -}}
{{- $args := dict "rules" (include "eric-lcm-git-repository.networkPolicyIngressDefaultAccessRule" . | fromYaml) -}}
{{- $_ := set $args "suffix" "default-access" -}}
{{- $_ := set $args "policyType" "Ingress" -}}
{{- include "eric-lcm-git-repository.networkPolicyBaseSpec"  (list $ $args) -}}
{{- end -}}
