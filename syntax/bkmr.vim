" Syntax highlighting for bkmr snippet editing buffers

if exists("b:current_syntax")
  finish
endif

" Template header highlighting
syn match bkmrHeader "^# \w\+:.*$"
syn match bkmrSeparator "^---$"

" Comments in the content area (after ---)
syn region bkmrContent start="^---$" end="\%$" contains=bkmrComment
syn match bkmrComment "//.*$" contained
syn match bkmrComment "#.*$" contained

" Snippet placeholders
syn match bkmrPlaceholder "\$\d\+" contained
syn match bkmrPlaceholder "\${\d\+}" contained
syn match bkmrPlaceholder "\${\d\+:[^}]*}" contained

" Template variables
syn match bkmrTemplate "{{[^}]*}}" contained

" Define highlight groups
hi def link bkmrHeader PreProc
hi def link bkmrSeparator Special
hi def link bkmrComment Comment
hi def link bkmrPlaceholder Identifier
hi def link bkmrTemplate Function

let b:current_syntax = "bkmr"