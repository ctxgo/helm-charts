{{- define "subchart.fullname" -}}
{{- $context := .context -}}
{{- $subchartName := .subchartName -}}
{{- $subchart := index $context.Subcharts $subchartName -}}
{{- $chart := $subchart.Chart -}}
{{- $release := $subchart.Release -}}
{{- $values := $subchart.Values -}}
{{- include "common.names.fullname" (dict "Chart" $chart "Release" $release "Values" $values) -}}
{{- end -}}
