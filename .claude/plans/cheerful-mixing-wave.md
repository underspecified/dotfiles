# Plan: Add ACM sigconf Template to HRI2026 Paper Build

## Goal
Incorporate ACM sigconf template in the simplest way possible using pandoc.

## Problem
When using `-V documentclass=acmart -V classoption=sigconf`, we get `\Bbbk already defined` error (conflict between pandoc's amssymb and acmart's newtx fonts).

## Solution: Minimal Template

Create a minimal template that just fixes the conflict and sets the document class.

**acm-sigconf.latex:**
```latex
\let\Bbbk\relax
\documentclass[sigconf,anonymous,review]{acmart}
\providecommand{\tightlist}{\setlength{\itemsep}{0pt}\setlength{\parskip}{0pt}}

$if(title)$\title{$title$}$endif$
$if(author)$\author{$for(author)$$author$$sep$ \and $endfor$}$endif$

\begin{document}
\maketitle
$body$
\end{document}
```

**build.sh:**
```bash
#!/bin/bash
cd "$(dirname "$0")"
pandoc HRI2026.md -o HRI2026.pdf --template=acm-sigconf.latex --citeproc --bibliography=references.bib
echo "Done"
```

## Files to Modify
1. `drafts/acm-sigconf.latex` - minimal template (fix conflict + set docclass)
2. `drafts/build.sh` - add `--template=acm-sigconf.latex`
