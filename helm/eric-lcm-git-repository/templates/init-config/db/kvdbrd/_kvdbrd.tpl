{{- define "eric-lcm-git-repository.userPermissions" -}}
{{- $serviceUserSecretName := .Values.gitea.config.redis.serviceUser.secret.name  -}}
{{- $userKey := .Values.gitea.config.redis.serviceUser.secret.userKey |toString -}}
{{- $passwordKey := .Values.gitea.config.redis.serviceUser.secret.passwordKey | toString -}}
{{- $serviceUserSecret := lookup "v1" "Secret" .Release.Namespace $serviceUserSecretName -}}
{{- $username := "" }}
{{- $password := "" }}
{{- if $serviceUserSecret }}
      {{- $username = toString (b64dec (index $serviceUserSecret.data $userKey)) -}}
      {{- $password = toString (b64dec (index $serviceUserSecret.data $passwordKey)) -}}
{{- else if .Values.initConfig.enabled }}
    {{- $username = .Values.gitea.config.redis.serviceName -}}
    {{- $password = include "eric-lcm-git-repository.getHashFromRealeaseNameNamespace" . -}}
{{- else }}
{{- (printf "Service User Secret %s not found" $serviceUserSecretName) | fail -}}
{{- end -}}
 {{ printf "~* &* +@all >%s" $password }} 
{{- end }}

{{- define "eric-lcm-git-repository.userName" -}}
{{- $serviceUserSecretName := .Values.gitea.config.redis.serviceUser.secret.name  -}}
{{- $userKey := .Values.gitea.config.redis.serviceUser.secret.userKey |toString -}}
{{- $passwordKey := .Values.gitea.config.redis.serviceUser.secret.passwordKey |toString -}}
{{- $serviceUserSecret := lookup "v1" "Secret" .Release.Namespace $serviceUserSecretName -}}
{{- $username := "" }}
{{- $password := "" }}
{{- if $serviceUserSecret }}
      {{- $username = toString (b64dec (index $serviceUserSecret.data $userKey)) -}}
      {{- $password = toString (b64dec (index $serviceUserSecret.data $passwordKey)) -}}
{{- else if .Values.initConfig.enabled }}
    {{- $username = .Values.gitea.config.redis.serviceName -}}
    {{- $password = include "eric-lcm-git-repository.getHashFromRealeaseNameNamespace" . -}}
{{- else }}
{{- (printf "Service User Secret %s not found" $serviceUserSecretName) | fail -}}
{{- end -}}

{{  printf "%v" $username|toString  }} 
{{- end }}