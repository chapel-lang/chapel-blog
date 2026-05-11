{{- define "main" -}}
---
title: "{{ .Title }}"
date: {{ .Date | safeHTML }}
externalLink: https://chapel-lang.org/blog{{ .Page.Permalink | strings.TrimSuffix "index.md" }}
author: {{ with .Params.authors }}{{ delimit . "and" }}{{ end }}
{{- $site := .Site }}
authorimage: {{ with .Params.authors }}{{ range . }}{{ with $site.GetPage (printf "/authors/%s" (urlize .)) }}https://chapel-lang.org/blog{{ .Permalink }}{{ .Params.photo }}{{ end }}{{ end }}{{ end }}
disable: false
tags:
  - opensource
  - HPC
  - chapel
---
Placeholder
{{- end -}}
