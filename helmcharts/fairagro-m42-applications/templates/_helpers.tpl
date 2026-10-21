{{/*
Child Application targetRevision: optional lock_children_to_revision overrides
the per-app *_revision string while still using that key for enable/disable
(null/empty disables the Application).
*/}}
{{- define "fairagro-m42-applications.childRevision" -}}
{{- $lock := .root.Values.lock_children_to_revision -}}
{{- $rev := index .root.Values .key -}}
{{- if $lock -}}
{{- $lock -}}
{{- else -}}
{{- $rev -}}
{{- end -}}
{{- end -}}
