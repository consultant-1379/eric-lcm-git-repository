{{/*
  Defines security context for Initializer Container
*/}}
{{- define "eric-lcm-git-repository.initializerContainerSecurityContextConfig" -}}
securityContext:
  {{- include "eric-lcm-git-repository.seccomp-profile" (dict "Values" .Values "Scope" "gitRepositoryInitInitializer") | nindent 2 }}
  allowPrivilegeEscalation: false
  privileged: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  capabilities:
    drop:
      - all
{{- end -}}

{{/*
  Defines Container Resources for Initializer Container
*/}}
{{- define "eric-lcm-git-repository.initializerContainerResources" -}}
{{- $ := index . 0 -}}{{- $ctx := index . 1 -}}{{- $containerName := index . 2 -}}
{{- $resourcesType := (list "limits" "requests" ) -}}
{{- range $resourcesKey := $resourcesType }}
  {{- with $ctx }}
{{ $resourcesKey }}:
    {{- if (index .Values "resources" $containerName $resourcesKey "cpu") }}
  cpu: {{ (index .Values "resources" $containerName $resourcesKey "cpu" | quote ) }}
    {{- end }}
    {{- if (index .Values "resources" $containerName $resourcesKey "memory") }}
  memory: {{ (index .Values "resources" $containerName $resourcesKey "memory" | quote ) }}
    {{- end }}
    {{- if (index .Values "resources" $containerName $resourcesKey "ephemeral-storage") }}
  ephemeral-storage: {{  (index .Values "resources" $containerName $resourcesKey "ephemeral-storage" | quote ) }}
    {{- end }}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "eric-lcm-git-repository.podPriorityClass" -}}
{{- if (((.Values).podPriority).ggitRepositoryInitInitializeritRepository).priorityClassName }}
priorityClassName: {{ .Values.podPriority.gitRepositoryInitInitializer.priorityClassName | quote }}
{{- end }}
{{- end -}}

{{/*
  Defines Environment Variables for Initializer Container
*/}}
{{- define "eric-lcm-git-repository.initializerContainerEnv" -}}
{{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
env:
  - name: INIT_CONFIG
    value: /home/init/config/config.properties
  - name: POSTGRESQL_SUPER_USER_NAME
    value: "postgres"
  {{- if not $global.security.tls.enabled }}
  - name: POSTGRESQL_SUPER_USER_PWD
    valueFrom:
      secretKeyRef:
        name: {{ .Values.initConfig.db.pg.superUser.secret.name }}
        key: {{ .Values.initConfig.db.pg.superUser.secret.pwdKey }}
  {{- end }}
  - name: POSTGRESQL_SERVICE_USER_NAME
    valueFrom:
      secretKeyRef:
        name: {{ .Values.gitea.config.database.serviceUser.secret.name }}
        key: {{ .Values.gitea.config.database.serviceUser.secret.userKey }}
  - name: POSTGRESQL_SERVICE_USER_PWD
    valueFrom:
      secretKeyRef:
        name: {{ .Values.gitea.config.database.serviceUser.secret.name }}
        key: {{ .Values.gitea.config.database.serviceUser.secret.passwordKey }}
{{- end -}}


{{/*
  Defines Pod Spec for Initializer Container
*/}}
{{- define "eric-lcm-git-repository.initializerContainerSpec" -}}
- name: initializer
  image: {{ include "eric-lcm-git-repository.initializerImageName" (dict "Values" .Values "Files" .Files "ContainerName" "eric-aiml-initializer") }}
  {{ include "eric-lcm-git-repository.initializerImagePullPolicy" . }}
  volumeMounts: {{ include "eric-lcm-git-repository.initializerVolumeMounts" . | nindent 4 }}
  {{- include "eric-lcm-git-repository.initializerContainerEnv" . | nindent 2 }}
  {{- include "eric-lcm-git-repository.initializerContainerSecurityContextConfig" . | nindent 2 }}
  resources: {{ include "eric-lcm-git-repository.initializerContainerResources" (list $ . "gitRepositoryInitInitializer" ) | nindent 4 }}
{{- end -}}

{{/*
  Defines Image Registry for Initializer Container
*/}}
{{/*
Image name including image registry and tag for initializer container
*/}}
{{- define "eric-lcm-git-repository.initializerImageName" -}}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $containerName := index . "ContainerName" -}}
    {{- $registryUrl := index $productInfo "images" $containerName "registry" -}}
    {{- $imagePath := index $productInfo "images" $containerName "repoPath" -}}
    {{- $imageName := index $productInfo "images" $containerName "name" -}}
    {{- $imageTag := index $productInfo "images" $containerName "tag" -}}
    {{- printf "%s/%s/%s:%s" $registryUrl $imagePath $imageName $imageTag }}
{{- end -}}

{{/*
  Defines Image Pull Policy for Initializer Container
*/}}
{{/*
  Defines container spec imagePullPolicy.
  Kubernetes imagePullPolicy item for PodSpec/[]Container
*/}}
{{- define "eric-lcm-git-repository.initializerImagePullPolicy" -}}
  {{- $context := . -}}
  {{- $imageKey := "eric-aiml-initializer" -}}
  {{- $imageLevelPullPolicy := printf "imageCredentials.%s.registry.imagePullPolicy" $imageKey -}}
  {{- $contextValues := deepCopy $context.Values -}}
  {{- $global := include "eric-lcm-git-repository.global" $context | fromYaml -}}
  {{- $_ := set $contextValues "global" $global }}
  {{- $imagePullPolicy := include "eric-lcm-git-repository.firstOptionalWithEmpty" (list $contextValues $imageLevelPullPolicy "global.registry.imagePullPolicy") -}}
  {{- if $imagePullPolicy | eq "_invalid_" -}}
    {{- $imagePullPolicy = "IfNotPresent" -}}
  {{- end -}}
imagePullPolicy: {{ $imagePullPolicy | quote }}
{{- end -}}

