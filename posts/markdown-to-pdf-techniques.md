---
title: "PDF's from markdown, pandoc and more"
description: "A collection of strategies to quickly produce pdf's from markdown files"
date: "2023-10-09T16:56:47+06:00"
featured: false
postOfTheMonth: false
author: "Tim Schupp"
categories: ["Tools"]
tags: ["pandoc", "grip", "linux", "markdown"]
---

Different command I've used over the year to quickly create pdfs from local note files.

## Raw Pandoc

```bash
pandoc -V geometry:margin=1cm <mardown-file> -o <pdf-file>
```

## Pandoc + `wkhtmltopdf`-engine

- html support, e.g.: tables etc
- dynmaic margin

```bash
pandoc --pdf-engine=wkhtmltopdf -V papersize=a4 -V margin-top=0.1 -V margin-left=0.1 -V margin-right=0.1 -V margin-bottom=0.1 --from markdown-markdown_in_html_blocks+raw_html <markdown-file> -o <pdf-file>
```

## Quick TXT file to dense readable pdf

```bash
pandoc --wrap=preserve $1 -V geometry:margin=1cm -V fontsize=8pt -o $1.pdf -f markdown+hard_line_breaks
```

## Github markdown using `grip`

```bash
sudo snap install grip
grip <markdown-file>
```

then visit the browser page and export the page as pdf.
Or `curl -X <page> > rendered.html`.

## HTML to pdf with

```bash
pandoc --pdf-engine=wkhtmltopdf rendered.html -o <pdf-file>
```

## TXT to pdf with `enscript` and `ps2pdf`

```bash
find . -type f -name $1 | while read ONELINE; do enscript "$ONELINE" -p "$(echo "$ONELINE" | sed 's/.txt/.ps/g')"; done
find . -type f -name "$(echo "$1" | sed 's/.txt/.ps/g')" | while read ONELINE; do ps2pdf "$ONELINE" "$(echo "$ONELINE" | sed 's/.ps/.pdf/g')"; done
```