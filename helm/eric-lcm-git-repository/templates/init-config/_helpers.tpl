{{/*
Init-config Prefix
*/}}
{{- define "eric-lcm-git-repository.init-config-prefix" -}}
{{- $name := include "eric-lcm-git-repository.name" . -}}
{{- printf "%s-%s" $name "init-config" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Init-config SVC Account Name
*/}}
{{- define "eric-lcm-git-repository.init-config-sa-name" -}}
{{- $name := include "eric-lcm-git-repository.init-config-prefix" . -}}
{{- printf "%s-sa" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
  Defines appArmor annotations for pod spec.
  Kubernetes resources Item for PodSpec
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.appArmorAnnotationsInitializer" -}}
{{- if ((.Values).appArmorProfile).type }}
{{- $appArmor := printf "container.apparmor.security.beta.kubernetes.io/initializer: %s" .Values.appArmorProfile.type -}}
  {{- if eq .Values.appArmorProfile.type "localhost" }}
{{- $appArmor = printf "%s/%s" $appArmor (required "appArmorProfile.localhostProfile is mandatory when appArmorProfile.type is localhost" ((.Values).appArmorProfile).localhostProfile ) -}}
  {{- end -}}
{{- print $appArmor }}
{{- end -}}
{{- end -}}

{{/*
Init-config Job name
*/}}
{{- define "eric-lcm-git-repository.init-config-job-name" -}}
{{- $name := include "eric-lcm-git-repository.init-config-prefix" . -}}
{{- printf "%s-%s" $name "job" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Expand the service's PG user's secret data
*/}}
{{- define "eric-lcm-git-repository.init-config-pg-serviceuser-secret" -}}
user: {{ .Values.gitea.config.database.NAME  | b64enc }}
password: {{ include "eric-lcm-git-repository.getHashFromRealeaseNameNamespace" .  | b64enc }}
{{- end -}}

{{/*
Expand the service's Redis user's secret data
*/}}
{{- define "eric-lcm-git-repository.init-config-redis-serviceuser-secret" -}}
user: {{ .Values.gitea.config.redis.serviceName  | b64enc }}
password: {{ include "eric-lcm-git-repository.getHashFromRealeaseNameNamespace" .  | b64enc }}
{{- end -}}


{{/*
Expand the service's gitea admin user's secret data
*/}}
{{- define "eric-lcm-git-repository.init-config-gitea-admincreds-secret" -}}
username: {{ printf "%s" "gitea_admin"  | b64enc }}
password: {{ printf "%.8s" (include "eric-lcm-git-repository.getHashFromRealeaseNameNamespace" .)  | b64enc }}
{{- end -}}
