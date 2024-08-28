{{/*
  Expand the name of the chart.
*/}}
{{- define "eric-lcm-git-repository.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
  Create a default fully qualified app name.
  We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
  If release name contains chart name it will be used as a full name.
*/}}
{{- define "eric-lcm-git-repository.fullname" -}}
  {{- if .Values.fullnameOverride -}}
    {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- $name := default .Chart.Name .Values.nameOverride -}}
    {{- if contains $name .Release.Name -}}
      {{- .Release.Name | trunc 63 | trimSuffix "-" -}}
    {{- else -}}
      {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}


{{/*
  Create chart name and version as used by the chart label.
*/}}
{{- define "eric-lcm-git-repository.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
  Standard labels
*/}}
{{- define "eric-lcm-git-repository.standardLabels" -}}
app.kubernetes.io/name: {{ include "eric-lcm-git-repository.name" . }}
app: {{ include "eric-lcm-git-repository.name" .}}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
helm.sh/chart: {{ include "eric-lcm-git-repository.chart" . }}
{{- end -}}


{{/*
  Create a user defined label
*/}}
{{ define "eric-lcm-git-repository.configLabels" }}
  {{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
  {{- $globalLabels:= $global.labels -}}
  {{- $service := .Values.labels -}}
  {{- include "eric-lcm-git-repository.mergeLabels" (dict "location" .Template.Name "sources" (list $globalLabels $service)) }}
{{- end }}


{{/*
  Merged labels for Default, which includes Standard and Config
*/}}
{{- define "eric-lcm-git-repository.labels" -}}
  {{- $standard := include "eric-lcm-git-repository.standardLabels" . | fromYaml -}}
  {{- $config := include "eric-lcm-git-repository.configLabels" . | fromYaml -}}
  {{- include "eric-lcm-git-repository.mergeLabels" (dict "location" .Template.Name "sources" (list $standard $config)) | trim }}
{{- end -}}


{{/*
  Create the name of the service account to use
*/}}
{{- define "eric-lcm-git-repository.serviceAccountName" -}}
  {{- if .Values.serviceAccount.create -}}
    {{ default ( include "eric-lcm-git-repository.name" . ) .Values.serviceAccount.name }}-sa
  {{- else -}}
    {{ required "serviceAccount.name is mandatory if serviceAccount.create is false" .Values.serviceAccount.name }}
  {{- end -}}
{{- end -}}


{{/*
  Create a user defined annotation
*/}}
{{ define "eric-lcm-git-repository.configAnnotations" }}
  {{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
  {{- $globalAnnotations:= $global.annotations -}}
  {{- $service := .Values.annotations -}}
  {{- include "eric-lcm-git-repository.mergeAnnotations" (dict "location" .Template.Name "sources" (list $globalAnnotations $service)) }}
{{- end }}


{{/*
  Merged annotations for Default, which includes productInfo and config
*/}}
{{- define "eric-lcm-git-repository.annotations" -}}
  {{- $productInfo := include "eric-lcm-git-repository.product-info" . | fromYaml -}}
  {{- $config := include "eric-lcm-git-repository.configAnnotations" . | fromYaml -}}
  {{- include "eric-lcm-git-repository.mergeAnnotations" (dict "location" .Template.Name "sources" (list $productInfo $config)) | trim }}
{{- end -}}


{{/*
Image registry URL and repository path. The priority of both parameters is as follows from highest to lowest: image, service, global
*/}}
{{- define "eric-lcm-git-repository.imagePath" -}}
  {{- $context := index . 0 -}}
  {{- $imageKey := index . 1 -}}
  {{- $imageLevelRepoPath := printf "imageCredentials.%s.repoPath" $imageKey -}}
  {{- $contextValues := deepCopy $context.Values -}}
  {{- $global := include "eric-lcm-git-repository.global" $context | fromYaml -}}
  {{- $_ := set $contextValues "global" $global }}
  {{- $repoPath := include "eric-lcm-git-repository.firstOptionalWithEmpty" (list $contextValues $imageLevelRepoPath "imageCredentials.repoPath" "global.registry.repoPath") -}}
  {{- $imageLevelUrl := printf "imageCredentials.%s.registry.url" $imageKey -}}
  {{- $defaultUrl := index (fromYaml ($context.Files.Get "eric-product-info.yaml")) "images" $imageKey "registry" -}}
    {{- $url := include "eric-lcm-git-repository.firstOptional" (list $contextValues $imageLevelUrl "imageCredentials.registry.url" "global.registry.url") | default $defaultUrl -}}
    {{- if $repoPath | eq "_invalid_" -}}
        {{- $defaultRepoPath := index (fromYaml ($context.Files.Get "eric-product-info.yaml")) "images" $imageKey "repoPath" -}}
        {{- printf "%s/%s" $url $defaultRepoPath -}}
    {{- else if $repoPath -}}
        {{- printf "%s/%s" $url $repoPath -}}
    {{- else -}}
        {{- $url -}}
    {{- end -}}
{{- end -}}


{{/*
  Defines if the network policy will be rendered in Helm chart using 'networkPolicy'
  parameter as a global parameter and as per service-level parameter (DR-D1125-059).
*/}}
{{- define "eric-lcm-git-repository.networkPolicies.enabled" -}}
  {{- $global := fromYaml ( include "eric-lcm-git-repository.global" . ) -}}
  {{- if and $global.networkPolicy.enabled .Values.networkPolicy.enabled -}}
    true
  {{- end -}}
{{- end -}}


{{/*
  Prints a value with quotes if its kind is "string". If its kind is anything else, tries to
  to convert its string representation to integer and prints it.
*/}}
{{- define "eric-lcm-git-repository.printStringOrIntegerValue" -}}
  {{- if kindIs "string" . -}}
    {{- print . | quote -}}
  {{- else -}}
    {{- print . | atoi -}}
  {{- end -}}
{{- end -}}


{{/*
Storage Class
*/}}
{{- define "eric-lcm-git-repository.persistence.storageClass" -}}
{{- $storageClass := .Values.persistence.persistentVolumeClaim.storageClass }}
{{- if $storageClass }}
storageClassName: {{ $storageClass | quote }}
{{- end }}
{{- end -}}
