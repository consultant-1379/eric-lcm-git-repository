{{/*
  Defines a list of values that, upon modification, triggers restart of the pod.
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.podRestartTriggerValues" -}}
{{/*{{- include "eric-lcm-git-repository.adpIamPodRestartTriggerContributor" .  -}}
{{- include "eric-lcm-git-repository.dstPodRestartTriggerContributor" .  -}} */}}
{{- end -}}


{{/*
  Defines security context.
  Kubernetes SecurityContext Item for PodSpec/[]Container
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.containerSecurityContextConfig" -}}
securityContext:
  allowPrivilegeEscalation: false
  privileged: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  capabilities:
    drop:
      - all
    {{/* # add:
    #   - SYS_CHROOT  */}}
  {{- include "eric-lcm-git-repository.seccomp-profile" (dict "Values" .Values "Scope" "eric-lcm-git-repository") | nindent 2 }}
{{- end -}}

{{/*
Return the fsgroup set via global parameter if it's set, otherwise 10000
*/}}
{{- define "eric-lcm-git-repository.fsGroup.coordinated" -}}
  {{- if .Values.global -}}
    {{- if .Values.global.fsGroup -}}
      {{- if .Values.global.fsGroup.manual -}}
        {{ .Values.global.fsGroup.manual }}
      {{- else -}}
        {{- if eq .Values.global.fsGroup.namespace true -}}
          # The 'default' defined in the Security Policy will be used.
        {{- else -}}
          1000
      {{- end -}}
    {{- end -}}
  {{- else -}}
    1000
  {{- end -}}
  {{- else -}}
    1000
  {{- end -}}
{{- end -}}

{{/*
  Defines container port.
  Kubernetes []ContainerPort Item for PodSpec/[]Container
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.containerPortsConfig" -}}
{{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
ports:
  {{/* }}- name: ssh
    containerPort: {{ .Values.gitea.config.server.SSH_LISTEN_PORT }}
  {{- if .Values.service.ssh.hostPort }}
    hostPort: {{ .Values.service.ssh.hostPort }}
  {{- end }} */}}
  - name: http
    containerPort: {{ .Values.gitea.config.server.HTTP_PORT }}
{{- end -}}


{{/*
  Defines container health probes.
  Kubernetes Lifecycle probes Items for PodSpec/[]Container
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.containerProbesConfig" -}}
{{- $ := index . 0 -}}{{- $context := index . 1 -}}{{- $dictParam := index . 2 -}}
{{- $probes := (list "livenessProbe" "readinessProbe" "startupProbe" ) -}}
{{- $probesKey := get $dictParam "probesKey" -}}
{{- $probeMap := (index $context.Values.probes $probesKey ) }}
  {{- range $probe := $probes }}
    {{- with $context }}
      {{- if hasKey $probeMap $probe }}
{{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) }}
{{ $probe }}:
  tcpSocket:
      port: http
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}


{{/*
  Create a merged set of nodeSelectors from global and service level.
*/}}
{{- define "eric-lcm-git-repository.nodeSelector" -}}
{{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
{{- $nodeSelector := dict -}}
  {{- if $global.nodeSelector -}}
    {{- $nodeSelector = $global.nodeSelector -}}
  {{- end -}}
  {{- if .Values.nodeSelector -}}
    {{- range $serviceLevelKey, $serviceLevelValue := .Values.nodeSelector  -}}
      {{- if and (hasKey $nodeSelector $serviceLevelKey) (ne (get $nodeSelector $serviceLevelKey) $serviceLevelValue ) -}}
        {{- fail ( printf "nodeSelector key \"%s\" is specified in both global.nodeSelector and nodeSelector with different values." $serviceLevelKey ) -}}
      {{- end -}}
    {{- end -}}
    {{- $nodeSelector = merge $nodeSelector .Values.nodeSelector -}}
  {{- end -}}
  {{- if not ( empty $nodeSelector ) -}}
{{- toYaml $nodeSelector | trim -}}
  {{- end -}}
{{- end -}}


{{- define "eric-lcm-git-repository.affinityPodAntiAffinity" -}}
{{- if eq .Values.affinity.podAntiAffinity "hard" }}
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchExpressions:
        - key: "app.kubernetes.io/name"
          operator: In
          values:
          - {{ include "eric-lcm-git-repository.name" . }}
      topologyKey: {{ .Values.affinity.topologyKey | quote }}
{{- else if eq .Values.affinity.podAntiAffinity "soft" }}
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: "app.kubernetes.io/name"
            operator: In
            values:
            - {{ include "eric-lcm-git-repository.name" . }}
        topologyKey: {{ .Values.affinity.topologyKey | quote }}
{{- end }}
{{- end -}}


{{/*
  Defines container spec pull secret.
  Kubernetes imagePullSecrets item for PodSpec/[]Container
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.pullSecret" -}}
{{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
{{- if .Values.imageCredentials.pullSecret }}
imagePullSecrets:
  - name: {{ .Values.imageCredentials.pullSecret | quote }}
{{- else if $global.pullSecret }}
imagePullSecrets:
  - name: {{ $global.pullSecret | quote }}
{{- end }}
{{- end -}}


{{/*
  Defines container resources.
  Kubernetes resources Item for PodSpec
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.containerResources" -}}
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


{{/*
  Container environment variables.
  Kubernetes []EnvVar for PodSpec/[]Container
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.commonContainerEnv" -}}
{{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
- name: GITEA_APP_INI
  value: /data/gitea/conf/app.ini
- name: GITEA_CUSTOM
  value: /data/gitea
- name: GITEA_WORK_DIR
  value: /data
- name: GITEA_TEMP
  value: /tmp/gitea
- name: HOME
  value: /data/gitea/git
- name: GITEA_ADMIN_USERNAME
  valueFrom:
    secretKeyRef:
      key:  username 
      name: {{ .Values.gitea.admin.secret }}
- name: GITEA_ADMIN_PASSWORD
  valueFrom:
    secretKeyRef:
      key:  password 
      name: {{ .Values.gitea.admin.secret }} 
{{- end -}}    

{{/*
  Container environment variables.
  Kubernetes []EnvVar for PodSpec/[]Container
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.giteaContainerEnv" -}}
{{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
env:
  {{- include "eric-lcm-git-repository.commonContainerEnv" . | nindent 2 }}
  - name: TMPDIR
    value: /tmp/gitea
{{- end -}}

{{/*
  Container environment variables.
  Kubernetes []EnvVar for PodSpec/[]Container
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.giteaConfigureContainerEnv" -}}
{{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
env:
  {{- include "eric-lcm-git-repository.commonContainerEnv" . | nindent 2 }}
  {{- if $global.security.tls.enabled }}
  - name: PGSSLKEY
    value: /run/secrets/pg/tls.key
  - name: PGSSLCERT
    value: /run/secrets/pg/tls.crt
  - name: PGSSLROOTCERT
    value: /run/secrets/root/ca.crt
  {{- end }}
{{- end -}}

{{/*
  Defines container spec.
  Kubernetes []Container Item for PodSpec
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.containerSpec" -}}
- name: git-repository
  {{- include "eric-lcm-git-repository.giteaContainerEnv" . | nindent 2 }}
  {{- include "eric-lcm-git-repository.containerSecurityContextConfig" . | nindent 2 }}
  image: {{ include "eric-lcm-git-repository.mainImageName" (dict "Values" .Values "Files" .Files "ContainerName" "eric-lcm-git-repository-gitea")  }}
  {{- include "eric-lcm-git-repository.mainImagePullPolicy" . | nindent 2 }}
  {{- include "eric-lcm-git-repository.containerPortsConfig" . | nindent 2 -}}
  {{- include "eric-lcm-git-repository.containerProbesConfig" (list $ . (dict "probesKey" "gitRepository" )) | nindent 2 }}
  resources: {{ include "eric-lcm-git-repository.containerResources" (list $ . "gitRepository" ) | nindent 4 }}
  volumeMounts: {{ include "eric-lcm-git-repository.volumeMounts" . | nindent 4 }}
{{- if le (int .Values.terminationGracePeriodSeconds) 10 }}
  {{- fail "value for .Values.terminationGracePeriodSeconds must be greater than 10" }}
{{- end }}
{{- end -}}


{{- define "eric-lcm-git-repository.initContainerSpec" -}}
- name: init-directories
  image: {{ include "eric-lcm-git-repository.mainImageName" (dict "Values" .Values "Files" .Files "ContainerName" "eric-lcm-git-repository-gitea")  }}
  {{- include "eric-lcm-git-repository.containerSecurityContextConfig" . | nindent 2 }}
  {{- include "eric-lcm-git-repository.mainImagePullPolicy" . | nindent 2 }}
  command: ["/usr/sbin/gitea/init_directory_structure.sh"]
  {{- include "eric-lcm-git-repository.giteaContainerEnv" . | nindent 2 }}
  volumeMounts: {{ include "eric-lcm-git-repository.initVolumeMounts" . | nindent 4 }}
  resources: {{ include "eric-lcm-git-repository.containerResources" (list $ . "gitRepositoryInit" ) | nindent 4 }}
{{- end -}}

{{- define "eric-lcm-git-repository.initAppIniContainerSpec" -}}
- name: init-app-ini
  image: {{ include "eric-lcm-git-repository.mainImageName" (dict "Values" .Values "Files" .Files "ContainerName" "eric-lcm-git-repository-gitea")  }}
  {{- include "eric-lcm-git-repository.containerSecurityContextConfig" . | nindent 2 }}
  {{- include "eric-lcm-git-repository.mainImagePullPolicy" . | nindent 2 }}
  command: ["/usr/sbin/gitea/config_environment.sh"]
  {{- include "eric-lcm-git-repository.giteaContainerEnv" . | nindent 2 }}
  volumeMounts: {{ include "eric-lcm-git-repository.initAppIniVolumeMounts" . | nindent 4 }}
  resources: {{ include "eric-lcm-git-repository.containerResources" (list $ . "gitRepositoryInitAppIni" ) | nindent 4 }}
{{- end -}}

{{- define "eric-lcm-git-repository.configureGiteaContainerSpec" -}}
- name: configure-gitea
  image: {{ include "eric-lcm-git-repository.mainImageName" (dict "Values" .Values "Files" .Files "ContainerName" "eric-lcm-git-repository-gitea")  }}
  {{- include "eric-lcm-git-repository.containerSecurityContextConfig" . | nindent 2 }}
  {{- include "eric-lcm-git-repository.mainImagePullPolicy" . | nindent 2 }}
  command: ["/usr/sbin/gitea/configure_gitea.sh"]
  {{- include "eric-lcm-git-repository.giteaConfigureContainerEnv" . | nindent 2 }}
  volumeMounts: {{ include "eric-lcm-git-repository.configureGiteaVolumeMounts" . | nindent 4 }}
  resources: {{ include "eric-lcm-git-repository.containerResources" (list $ . "gitRepositoryConfigureGitea" ) | nindent 4 }}

{{- end -}}

{{/*
Image name including image registry and tag for main container
*/}}
{{- define "eric-lcm-git-repository.mainImageName" -}}

    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $containerName := index . "ContainerName" -}}
    {{- $imagePath := index $productInfo "images" $containerName "repoPath" -}}
    {{- $imagePath := include "eric-lcm-git-repository.imagePath" (list . $containerName) -}}
    {{- $imageName := index $productInfo "images" $containerName "name" -}}
    {{- $imageTag := index $productInfo "images" $containerName "tag" -}}
    {{- printf "%s/%s:%s" $imagePath $imageName $imageTag }}
{{- end -}}

{{/*
  Defines container spec imagePullPolicy.
  Kubernetes imagePullPolicy item for PodSpec/[]Container
*/}}
{{- define "eric-lcm-git-repository.mainImagePullPolicy" -}}
  {{- $context := . -}}
  {{- $imageKey := "gitRepository" -}}
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


{{- define "eric-lcm-git-repository.podPriorityClass" -}}
{{- if (((.Values).podPriority).gitRepository).priorityClassName }}
priorityClassName: {{ .Values.podPriority.gitRepository.priorityClassName | quote }}
{{- end }}
{{- end -}}


{{/*
  Predefined Kubernetes and Helm deployment annotations
*/}}
{{- define "eric-lcm-git-repository.predefinedDeploymentAnnotations" -}}
checksum/config: {{ include "eric-lcm-git-repository.podRestartTriggerValues" . | sha256sum }}
{{- end -}}


{{/*
  Merged annotations for Default, which includes Pod Restart Trigger Values, Prometheus Metrics, Log Elastic and Config
*/}}
{{- define "eric-lcm-git-repository.podAnnotations" -}}
  {{- $podRestartTriggerValues := include "eric-lcm-git-repository.predefinedDeploymentAnnotations" . | fromYaml -}}
  {{/* {{- $metricsPrometheus := include "eric-lcm-git-repository.metricsPrometheusDeploymentAnnotations" . | fromYaml -}} => to be modified to suit us */}}
  {{- $config := include "eric-lcm-git-repository.annotations" . | fromYaml -}}
  {{- $appAmor := include "eric-lcm-git-repository.appArmorAnnotations" . | fromYaml -}}
  {{- $bandwidth := include "eric-lcm-git-repository.bandwidthAnnotations" . | fromYaml }}
  {{- $istioAnnotations := include "eric-lcm-git-repository.istio-sidecar-annotations" . | fromYaml -}}
  {{- include "eric-lcm-git-repository.mergeAnnotations" (dict "location" .Template.Name "sources" (list $podRestartTriggerValues $config $appAmor $bandwidth $istioAnnotations)) | trim }}
{{- end -}}


{{/*
  Defines appArmor annotations for pod spec.
  Kubernetes resources Item for PodSpec
  Required Scope: default chart context
*/}}
{{- define "eric-lcm-git-repository.appArmorAnnotations" -}}
{{- if ((.Values).appArmorProfile).type }}
{{- $appArmor := printf "container.apparmor.security.beta.kubernetes.io/git-repository: %s" .Values.appArmorProfile.type -}}
  {{- if eq .Values.appArmorProfile.type "localhost" }}
{{- $appArmor = printf "%s/%s" $appArmor (required "appArmorProfile.localhostProfile is mandatory when appArmorProfile.type is localhost" ((.Values).appArmorProfile).localhostProfile ) -}}
  {{- end -}}
{{- print $appArmor }}
{{- end -}}
{{- end -}}


{{/*
  Merged custom labels for pod.
  Define Service Mesh Admission Webhook labels according DR-D470217-001
*/}}
{{- define "eric-lcm-git-repository.podLabels" -}}
  {{- $labels := list -}}
  {{- $labels = append $labels (include "eric-lcm-git-repository.labels" . | fromYaml) -}}
  {{/* {{- $labels = append $labels (include "eric-lcm-git-repository.adpIamPodLabels" . | fromYaml) -}} 
  {{- $labels = append $labels (include "eric-lcm-git-repository.dstPodLabels" . | fromYaml) -}} */}}
  {{- $labels = append $labels (include "eric-lcm-git-repository.istio-sidecar-labels" .| fromYaml) -}}
  {{- include "eric-lcm-git-repository.mergeLabels" (dict "location" .Template.Name "sources" $labels) | trim }}
{{- end -}}


{{/*
Seccomp profile section (DR-1123-128)
*/}}
{{/*
DR-D1123-128 seccomp profile
Scope
*/}}
{{- define "eric-lcm-git-repository.seccomp-profile" -}}
{{- if .Values.seccompProfile -}}
{{- if eq .Scope "Pod" -}}
{{- if .Values.seccompProfile.type -}}
seccompProfile:
  type: {{ .Values.seccompProfile.type }}
  {{- if eq .Values.seccompProfile.type "Localhost" }}
  {{- if not .Values.seccompProfile.localhostProfile }}
  {{- fail "\n\nThe 'Localhost' seccomp Profile requires a profile name to be provided in localhostProfile parameter." }}
  {{- end }}
  localhostProfile: {{ .Values.seccompProfile.localhostProfile }}
  {{- end -}}
{{- end -}}
{{- else if (hasKey .Values.seccompProfile .Scope) -}}
{{- $container_setting := (get .Values.seccompProfile .Scope) -}}
{{- if $container_setting.type -}}
seccompProfile:
  type: {{ $container_setting.type }}
  {{- if eq $container_setting.type "Localhost" }}
  {{- if not $container_setting.localhostProfile }}
  {{- fail "\n\nThe 'Localhost' seccomp Profile requires a profile name to be provided in localhostProfile parameter." }}
  {{- end }}
  localhostProfile: {{ $container_setting.localhostProfile }}
  {{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}



{{/*
  Create traffic shapping annotations.
*/}}
{{- define "eric-lcm-git-repository.bandwidthAnnotations" -}}
{{- if .Values.bandwidth.maxEgressRate }}
kubernetes.io/egress-bandwidth: {{ .Values.bandwidth.maxEgressRate | quote }}
{{- end }}
{{- end -}}



{{- define "eric-lcm-git-repository.redisClusterURL" -}}
{{- if eq (index .Values "gitea" "config" "cache").ADAPTER "redis" -}}
{{ (index .Values "gitea" "config" "cache" "HOST")}}
{{- end -}}
{{- end -}}

{{- define "eric-lcm-git-repository.redisClusterPort" -}}
{{- if eq (index .Values "gitea" "config" "cache").ADAPTER "redis" -}}
{{ (index .Values "redis-cluster").port }}
{{- end -}}
{{- end -}}

{{- define "eric-lcm-git-repository.servicename" -}}
{{- if eq (index .Values "gitea" "config" "cache").ADAPTER "redis" -}}
{{ (index .Values "redis-cluster").serviceName }}
{{- end -}}
{{- end -}}