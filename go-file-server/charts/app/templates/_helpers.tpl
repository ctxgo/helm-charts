{{/* Return the proper image name */}}
{{- define "app.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}

{{/* Return the proper Docker Image Registry Secret Names */}}
{{- define "app.imagePullSecrets" -}}
{{ include "common.images.pullSecrets" (dict "images" (list .Values.image) "global" .Values.global) }}
{{- end -}}

{{/* Return the app configuration configmap */}}
{{- define "app.configMapName" -}}
{{- if .Values.existingConfigMap -}}
    {{- printf "%s" (tpl .Values.existingConfigMap $) -}}
{{- else -}}
    {{- printf "%s-configuration" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/* Return true if a app configmap object should be created */}}
{{- define "app.createConfigMap" -}}
{{/* false的情况不用返回，否则反而会永远返回true. */}}
{{- if and .Values.configMap (not .Values.existingConfigMap) }}
    {{- true -}}
{{- end -}}
{{- end -}}


{{/* Return true if persistence volumes should be enabled. */}}
{{- define "app.persistence.enabled" -}}
{{- if or .Values.persistence.enabled .Values.openrasp .Values.existingOpenraspConfigMap .Values.config .Values.existingConfigmap }}
  {{- true -}}
{{- end -}}
{{- end -}}

{{/* Return true if persistence volumes should be created. */}}
{{- define "app.persistence.createPVC" -}}
{{/* false的情况不用返回，否则反而会永远返回true. */}}
{{- if and .Values.persistence.enabled (not .Values.persistence.existingClaim) -}}
  {{- $pvc := (lookup "v1" "PersistentVolumeClaim" .Release.Namespace (include "common.names.name" .)) -}}
  {{- if not $pvc -}}
    {{- true -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/* Return the app persistence volume claim name. */}}
{{- define "app.persistence.pvcName" -}}
{{- if (include "app.persistence.createPVC" .) -}}
    {{- printf "%s" (include "common.names.fullname" .) -}}
{{- else if .Values.persistence.existingClaim -}}
    {{- printf "%s" .Values.persistence.existingClaim -}}
{{- end -}}
{{- end -}}



{{/*
Check if a given env var name exists in .Values.env
*/}}
{{- define "env.exists" -}}
  {{- $name := .name -}}
  {{- $exists := false -}}
  {{- range .context.Values.env -}}
    {{- if eq .name $name -}}
      {{- $exists = true -}}
      {{- break -}}
    {{- end -}}
  {{- end -}}
  {{- $exists -}}
{{- end -}}



{{/* Returns kubernetes spec template configuration */}}
{{- define "app.spec.template" -}}
{{- $persistence := .Values.persistence -}}
metadata:
  {{- if .Values.podAnnotations }}
  annotations:
    {{- include "common.tplvalues.render" (dict "value" .Values.podAnnotations "context" $) | nindent 4 }}
  {{- end }}
  labels:
    {{- include "common.labels.standard" . | nindent 4 }}
spec:
  {{- include "app.imagePullSecrets" . | nindent 2 }}
  {{- if .Values.hostAliases }}
  hostAliases:
    {{- include "common.tplvalues.render" (dict "value" .Values.hostAliases "context" $) | nindent 4 }}
  {{- end }}
  dnsPolicy: {{ .Values.dnsPolicy | default "ClusterFirst" }}
  restartPolicy: {{ .Values.restartPolicy | default "Always"}}
  terminationGracePeriodSeconds: {{ .Values.terminationGracePeriodSeconds | default 30 }}
  {{- with .Values.podSecurityContext }}
  securityContext:
    {{- include "common.tplvalues.render" (dict "value" . "context" $) | nindent 4 }}
  {{- end }}
  {{- if (include "app.persistence.enabled" .) }}
  volumes:
    {{- if or $persistence.enabled }}
    - name: data
      persistentVolumeClaim:
        claimName: {{ include "app.persistence.pvcName" . }}
    {{- end }}
    {{- if or .Values.configMap .Values.existingConfigMap }}
    - name: config
      configMap:
        name: {{ include "app.configMapName" . }}
        items:
          - key: config.yaml
            path: config.yaml
    {{- end }}
  {{- end }}
  containers:
    - name: {{ .Chart.Name }}
      {{- with .Values.securityContext }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      image: {{ include "app.image" . }}
      imagePullPolicy: {{ .Values.image.pullPolicy }}
      {{- if .Values.terminationLog.enabled }}
      terminationMessagePath: {{ .Values.persistence.mountPath }}/{{ include "common.names.fullname" . }}
      terminationMessagePolicy: File
      {{- end }}
      {{- if .Values.args }}
      args:
        {{- range .Values.args }}
        - {{ . }}
        {{- end }}
      {{- end }}
      env:
        {{- $defaultEnvVars := list
          (dict "name" "TZ" "type" "value" "data" "Asia/Shanghai")
          (dict "name" "MY_POD_NAME" "type" "valueFrom" "data" (dict "fieldRef" "metadata.name"))
          (dict "name" "MY_POD_IP" "type" "valueFrom" "data" (dict "fieldRef" "status.podIP"))
          (dict "name" "HOST_IP" "type" "valueFrom" "data" (dict "fieldRef" "status.hostIP"))
          (dict "name" "k8s_ns" "type" "valueFrom" "data" (dict "fieldRef" "metadata.namespace"))
          (dict "name" "project_name" "type" "valueFrom" "data" (dict "fieldRef" "metadata.labels['app.kubernetes.io/instance']"))
        -}}
        {{- $context := . -}}
        {{/* Iterate over the default env vars and add them if they are not defined */}}
        {{- range $envVar := $defaultEnvVars }}
        {{- if not (eq (include "env.exists" (dict "name" $envVar.name "context" $context)) "true") }}
        - name: {{ $envVar.name }}
          {{- if eq $envVar.type "value" }}
          value: {{ $envVar.data }}
          {{- else if eq $envVar.type "valueFrom" }}
          {{- if $envVar.data.fieldRef }}
          valueFrom:
            fieldRef:
              fieldPath: {{ $envVar.data.fieldRef }}
          {{- end }}
          {{- end }}
          {{- end }}
        {{- end -}}
        {{/* load .Values.env  */}}
        {{- if .Values.env }}
        {{- include "common.tplvalues.render" (dict "value" .Values.env "context" $) | nindent 8 }}
        {{- end }}
      ports:
        {{- range .Values.service.ports }}
        - name: {{ .name }}
          containerPort: {{ .containerPort }}
          protocol: {{ .protocol }}
        {{- end }}
      {{- if (include "app.persistence.enabled" .) }}
      volumeMounts:
        {{- if or $persistence.enabled }}
        - name: data
          mountPath: {{ .Values.persistence.mountPath }}
        {{- end }}
        {{- if or .Values.configMap .Values.existingConfigMap }}
        - name: config
          mountPath: /config.yaml
          subPath: config.yaml
        {{- end }}
      {{- end }}
      {{- if .Values.readinessProbe }}
      readinessProbe:
        {{- include "common.tplvalues.render" (dict "value" .Values.readinessProbe "context" $) | nindent 8 }}
      {{- end }}
      {{- if .Values.livenessProbe }}
      livenessProbe:
        {{- include "common.tplvalues.render" (dict "value" .Values.livenessProbe "context" $) | nindent 8 }}
      {{- end }}
      resources:
        {{- include "common.tplvalues.render" (dict "value" .Values.resources "context" $) | nindent 8 }}
  {{- with .Values.nodeSelector }}
  nodeSelector:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.tolerations }}
  tolerations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.affinity }}
  affinity:
    {{- if .nodeAffinity }}
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: {{ .nodeAffinity.matchExpressions.key }}
                operator: {{ .nodeAffinity.matchExpressions.operator }}
                values:
                {{- range .nodeAffinity.matchExpressions.values }}
                  {{- printf "%s \"%s\"" "-" . | nindent 18 }}
                {{- end }}
    {{- end }}
    {{- if .podAntiAffinity }}
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchExpressions:
              - key: {{ .podAntiAffinity.matchExpressions.key }}
                operator: {{ .podAntiAffinity.matchExpressions.operator }}
                values:
                {{- range .podAntiAffinity.matchExpressions.values }}
                  {{- printf "%s \"%s\"" "-" . | nindent 18 }}
                {{- end }}
          topologyKey: kubernetes.io/hostname
    {{- end }}
  {{- end }}
{{- end -}}

{{/* Returns kubernetes labels template configuration */}}
{{- define "app.labels.template" -}}
labels:
  {{- include "common.labels.standard" . | nindent 2 }}
  {{- if .Values.commonLabels }}
    {{- include "common.tplvalues.render" ( dict "value" .Values.commonLabels "context" $ ) | nindent 2 }}
  {{- end }}
{{- end -}}

{{/* Returns kubernetes annotations template configuration */}}
{{- define "app.annotations.template" -}}
{{- if .Values.commonAnnotations }}
annotations:
  {{- include "common.tplvalues.render" ( dict "value" .Values.commonAnnotations "context" $ ) | nindent 2 }}
{{- end }}
{{- end -}}

{{/* Returns kubernetes metadata template configuration */}}
{{- define "app.metadata.template" -}}
labels:
  {{- include "common.labels.standard" . | nindent 2 }}
  {{- if .Values.commonLabels }}
    {{- include "common.tplvalues.render" ( dict "value" .Values.commonLabels "context" $ ) | nindent 2 }}
  {{- end }}
{{- if .Values.commonAnnotations }}
annotations:
  {{- include "common.tplvalues.render" ( dict "value" .Values.commonAnnotations "context" $ ) | nindent 2 }}
{{- end }}
{{- end -}}

{{/* Returns kubernetes statefulset spec volumeClaimTemplates template configuration */}}
{{- define "app.statefulset.spec.volumeClaimTemplates" -}}
{{- $persistence := .Values.persistence -}}
volumeClaimTemplates:
- metadata:
    name: data
  spec:
    accessModes:
      {{- include "common.tplvalues.render" (dict "value" $persistence.accessModes "context" $) | nindent 4 }}
    resources:
      requests:
        storage: {{ $persistence.size }}
    {{- include "common.storage.class" (dict "persistence" $persistence "global" .Values.global) | nindent 2 }}
{{- end -}}
