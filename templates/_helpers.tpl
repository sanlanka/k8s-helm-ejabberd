{{/*
Expand the name of the chart.
*/}}
{{- define "ejabberd.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ejabberd.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "ejabberd.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ejabberd.labels" -}}
helm.sh/chart: {{ include "ejabberd.chart" . }}
{{ include "ejabberd.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ejabberd.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ejabberd.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "ejabberd.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ejabberd.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate ejabberd domain
*/}}
{{- define "ejabberd.domain" -}}
{{- .Values.ejabberd.domain | default "localhost" }}
{{- end }}

{{/*
Generate admin users list
*/}}
{{- define "ejabberd.admins" -}}
{{- range .Values.ejabberd.admins }}
- {{ . | quote }}
{{- end }}
{{- end }}

{{/*
Generate authentication methods configuration
*/}}
{{- define "ejabberd.authMethods" -}}
{{- $methods := list }}
{{- if .Values.ejabberd.auth.methods.jwt.enabled }}
{{- $methods = append $methods "jwt" }}
{{- end }}
{{- if .Values.ejabberd.auth.methods.internal.enabled }}
{{- $methods = append $methods "internal" }}
{{- end }}
{{- if .Values.ejabberd.auth.methods.ldap.enabled }}
{{- $methods = append $methods "ldap" }}
{{- end }}
{{- if .Values.ejabberd.auth.methods.sql.enabled }}
{{- $methods = append $methods "sql" }}
{{- end }}
{{- if .Values.ejabberd.auth.methods.external.enabled }}
{{- $methods = append $methods "external" }}
{{- end }}
{{- if .Values.ejabberd.auth.methods.anonymous.enabled }}
{{- $methods = append $methods "anonymous" }}
{{- end }}
{{- $methods | toYaml }}
{{- end }}

{{/*
Generate database type configuration
*/}}
{{- define "ejabberd.databaseType" -}}
{{- if eq .Values.ejabberd.database.type "sql" }}
{{- .Values.ejabberd.database.sql.type }}
{{- else }}
{{- .Values.ejabberd.database.type }}
{{- end }}
{{- end }}

{{/*
Generate JWT key secret name
*/}}
{{- define "ejabberd.jwtSecretName" -}}
{{- printf "%s-jwt" (include "ejabberd.fullname" .) }}
{{- end }}

{{/*
Generate TLS secret name
*/}}
{{- define "ejabberd.tlsSecretName" -}}
{{- printf "%s-tls" (include "ejabberd.fullname" .) }}
{{- end }}

{{/*
Generate config secret name
*/}}
{{- define "ejabberd.configSecretName" -}}
{{- printf "%s-config" (include "ejabberd.fullname" .) }}
{{- end }}

{{/*
Generate persistent volume claim name
*/}}
{{- define "ejabberd.pvcName" -}}
{{- printf "%s-data" (include "ejabberd.fullname" .) }}
{{- end }} 