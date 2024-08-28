{{- define "eric-lcm-git-repository.inline_configuration" -}}
  {{- include "eric-lcm-git-repository.inline_configuration.init" . -}}
  {{- include "eric-lcm-git-repository.inline_configuration.defaults" . -}}
   
  {{- $generals := list -}}
  {{- $inlines := dict -}}
  {{- $root := . -}}
  {{ $giteadatabasecredentials := include "eric-lcm-git-repository.giteaDbCredentials" . }}

  {{- range $key, $value := .Values.gitea.config  }}
    {{- if kindIs "map" $value }}
      {{- if gt (len $value) 0 }}
        {{- $section := default list (get $inlines $key) -}}
        {{- range $n_key, $n_value := $value }}
            {{- if eq $key "database" }}
              {{- if ne $n_key "serviceUser" }}
                {{- $section = append $section (printf "%s=%v" $n_key $n_value) -}}
              {{- else }}
                {{- $section = append $section (trim $giteadatabasecredentials) -}}
              {{ end }}
            {{- else }}
              {{- $section = append $section (printf "%s=%v" $n_key $n_value) -}}
            {{- end }}
        {{- end }}
        {{- if ne $key "redis" -}}
        {{- $_ := set $inlines $key (join "\n" $section) -}}
        {{- end -}}
      {{- end -}}
    {{- else }}
      {{- if or (eq $key "APP_NAME") (eq $key "RUN_USER") (eq $key "RUN_MODE") -}}
        {{- $generals = append $generals (printf "%s=%s" $key $value) -}}
      {{- else -}}
        {{- (printf "Key %s cannot be on top level of configuration" $key) | fail -}}
      {{- end -}}
    {{- end }}
  {{- end }}
  {{- $_ := set $inlines "_generals_" (join "\n" $generals) -}} 
    {{- if $.Values.gitea.config.redis.cache.enabled -}}
      {{- $cache_section := default (list) (get $inlines "cache") -}}
      {{- $cache_section = append $cache_section (printf "%s=%v" "ENABLED" "true") -}}
      {{- $cache_section = append $cache_section (printf "%s=%v" "ADAPTER" "redis") -}}
      {{- $cache_section = append $cache_section (printf "%s=%v" "HOST" (include "eric-lcm-git-repository.redisUriString" $root)) -}}
      {{- $_ := set $inlines "cache" (join "\n" $cache_section) -}}
  {{- end -}}
  {{- $session_section := default (list) (get $inlines "session") -}}
  {{- $session_section = append $session_section (printf "%s=%v" "PROVIDER" "redis") -}}
  {{- $session_section = append $session_section (printf "%s=%v" "PROVIDER_CONFIG" (include "eric-lcm-git-repository.redisUriString" $root)) -}}
  {{- $_ := set $inlines "session" (join "\n" $session_section) -}}
  {{- toYaml $inlines -}}
{{- end -}}

{{- define "eric-lcm-git-repository.inline_configuration.init" -}}
  {{- if not (hasKey .Values.gitea.config "cache") -}}
    {{- $_ := set .Values.gitea.config "cache" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config "server") -}}
    {{- $_ := set .Values.gitea.config "server" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config "metrics") -}}
    {{- $_ := set .Values.gitea.config "metrics" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config "database") -}}
    {{- $_ := set .Values.gitea.config "database" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config "security") -}}
    {{- $_ := set .Values.gitea.config "security" dict -}}
  {{- end -}}
  {{- if not .Values.gitea.config.repository -}}
    {{- $_ := set .Values.gitea.config "repository" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config "oauth2") -}}
    {{- $_ := set .Values.gitea.config "oauth2" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config "session") -}}
    {{- $_ := set .Values.gitea.config "session" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config "queue") -}}
    {{- $_ := set .Values.gitea.config "queue" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config "queue.issue_indexer") -}}
    {{- $_ := set .Values.gitea.config "queue.issue_indexer" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config "indexer") -}}
    {{- $_ := set .Values.gitea.config "indexer" dict -}}
  {{- end -}}
{{- end -}}


{{- define "eric-lcm-git-repository.inline_configuration.defaults" -}}
  {{- include "eric-lcm-git-repository.inline_configuration.defaults.server" . -}}
  

  {{- if not .Values.gitea.config.repository.ROOT -}}
    {{- $_ := set .Values.gitea.config.repository "ROOT" "/data/git/gitea-repositories" -}}
  {{- end -}}
  {{- if not .Values.gitea.config.security.INSTALL_LOCK -}}
    {{- $_ := set .Values.gitea.config.security "INSTALL_LOCK" "true" -}}
  {{- end -}}

  {{- if not .Values.gitea.config.indexer.ISSUE_INDEXER_TYPE -}}
     {{- $_ := set .Values.gitea.config.indexer "ISSUE_INDEXER_TYPE" "db" -}}
  {{- end -}}
{{- end -}}

{{- define "eric-lcm-git-repository.default_domain" -}}
{{- printf "%s-http.%s.svc.%s" ( include "eric-lcm-git-repository.name" . ) .Release.Namespace  "cluster.local" -}} // should be have clusterDomain in values.
{{- end -}}


{{- define "eric-lcm-git-repository.public_protocol" -}}
{{- if and .Values.ingress.enabled .Values.ingress.tls.enabled -}}
https
{{- else -}}
http
{{- end -}}
{{- end -}}

{{- define "eric-lcm-git-repository.inline_configuration.defaults.server" -}}
  {{- if not (hasKey .Values.gitea.config.server "HTTP_PORT") -}}
    {{- $_ := set .Values.gitea.config.server "HTTP_PORT" .Values.service.http.port -}}
  {{- end -}}
  {{- if not .Values.gitea.config.server.PROTOCOL -}}
    {{- $_ := set .Values.gitea.config.server "PROTOCOL" "http" -}}
  {{- end -}}
  {{- if not .Values.gitea.config.server.DISABLE_SSH -}}
    {{- $_ := set .Values.gitea.config.server "DISABLE_SSH" "true" -}}
  {{- end -}}
  {{- if not (.Values.gitea.config.server.DOMAIN) -}}
    {{- if .Values.ingress.hostname -}}
      {{- $_ := set .Values.gitea.config.server "DOMAIN" .Values.ingress.hostname  -}}
    {{- else -}}
      {{- $_ := set .Values.gitea.config.server "DOMAIN" (include "eric-lcm-git-repository.default_domain" .) -}}
    {{- end -}}
  {{- end -}}
  {{- if not .Values.gitea.config.server.ROOT_URL -}}
    {{- $_ := set .Values.gitea.config.server "ROOT_URL" (printf "%s://%s" (include "eric-lcm-git-repository.public_protocol" .) .Values.gitea.config.server.DOMAIN) -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config.server "APP_DATA_PATH") -}}
    {{- $_ := set .Values.gitea.config.server "APP_DATA_PATH" "/data" -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config.server "ENABLE_PPROF") -}}
    {{- $_ := set .Values.gitea.config.server "ENABLE_PPROF" false -}}
  {{- end -}}
{{- end -}}

{{/*
Generate credentials for Gitea database from password already set
*/}}
{{- define "eric-lcm-git-repository.giteaDbCredentials" -}}
{{- $serviceUserSecretName := .Values.gitea.config.database.serviceUser.secret.name -}}
{{- $serviceUserSecret := lookup "v1" "Secret" .Release.Namespace $serviceUserSecretName -}}
{{- if $serviceUserSecret }}
USER={{ toString (b64dec (index $serviceUserSecret.data .Values.gitea.config.database.serviceUser.secret.userKey)) }}
PASSWD={{ toString (b64dec (index $serviceUserSecret.data .Values.gitea.config.database.serviceUser.secret.passwordKey)) }}
{{/*
Executed only when initConfig is enabled
*/}}
{{- else if .Values.initConfig.enabled }}
USER={{ .Values.gitea.config.database.NAME }}
PASSWD={{ include "eric-lcm-git-repository.getHashFromRealeaseNameNamespace" . }}
{{- else }}
{{- (printf "Service User Secret %s not found" $serviceUserSecretName) | fail -}}
{{- end }}
{{- end }}

{{- define "eric-lcm-git-repository.getUserSecretValues" -}}
{{- $secretName := index . "secretName" -}}
{{- $serviceUserSecret := lookup "v1" "Secret" .nameSpace $secretName -}}
{{- if not $serviceUserSecret }}
{{- $return := dict "username" "0" "password" "0" -}}
{{- else }}
  {{- $username := $serviceUserSecret.data | get .usernameKey | b64dec -}}
  {{- $password := $serviceUserSecret.data | get .passwordKey | b64dec -}}
{{- $return := dict "username" $username "password" $password -}}
{{- end -}}
{{- end -}}

{{- define "eric-lcm-git-repository.redisUriString" -}}
{{- $serviceUserSecretName := .Values.gitea.config.redis.serviceUser.secret.name  -}}
{{- $userKey := .Values.gitea.config.redis.serviceUser.secret.userKey -}}
{{- $passwordKey := .Values.gitea.config.redis.serviceUser.secret.passwordKey -}}
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
{{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
{{- $port := .Values.gitea.config.redis.port -}}
{{- if $global.security.tls.enabled -}}
{{- $port = .Values.gitea.config.redis.tlsPort -}}
{{- end -}}
{{- printf "redis+cluster://%s:%s@%s:%g?pool_size=100&idle_timeout=180s" $username $password .Values.gitea.config.redis.serviceName $port  -}}
{{- end -}}

{{- define "eric-lcm-git-repository.getHashFromRealeaseNameNamespace" -}}
{{- $releaseString := printf "%s%s" .Release.Name .Release.Namespace -}}
{{- $releaseStringHash := sha256sum $releaseString -}}
{{- $releaseStringHash -}}
{{- end -}}

{{- define "eric-lcm-git-repository.getDatabasePort" -}}
{{- $databaseHostString := .Values.gitea.config.database.HOST |toString  -}}
{{- $parts := split ":" $databaseHostString -}}
{{- index $parts "_1" -}}
{{- end -}}