{{/* Return the proper rtstreamer image */}}
{{- define "rtstreamer.image" -}}
{{- if .Values.rtstreamer.imageOverride -}}
{{- $imageOverride := .Values.rtstreamer.imageOverride -}}
{{- printf "%s" $imageOverride -}}
{{- else -}}
{{- $registryName := default .Values.global.registry .Values.global.localRegistry | toString -}}
{{- $repositoryName := .Values.global.repository | toString -}}
{{- $name := .Values.rtstreamer.imageName | toString -}}
{{- $tag := .Values.rtstreamer.imageTag | toString -}}
{{- printf "%s%s%s:%s" $registryName $repositoryName $name $tag -}}
{{- end -}}
{{- end -}}