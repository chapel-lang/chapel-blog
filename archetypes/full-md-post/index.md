---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
draft: true
tags: []
series: []
summary: "summary"
authors: []
---

{{< file_download fname="test.chpl" lang="chapel" >}}

produces:

{{< console fname="test.good" >}}
