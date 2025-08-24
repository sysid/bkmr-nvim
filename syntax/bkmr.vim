" Syntax highlighting for bkmr snippet editing buffers

if exists("b:current_syntax")
  finish
endif

" Template comments
syn match bkmrComment "^#.*$"

" Section markers
syn match bkmrSection "^=== .* ===$"

" Section names for highlighting
syn match bkmrSectionID "^=== ID ===$"
syn match bkmrSectionContent "^=== CONTENT ===$"
syn match bkmrSectionTitle "^=== TITLE ===$"
syn match bkmrSectionTags "^=== TAGS ===$"
syn match bkmrSectionComments "^=== COMMENTS ===$"
syn match bkmrSectionEnd "^=== END ===$"

" Content within CONTENT section
syn region bkmrContentArea start="^=== CONTENT ===$" end="^=== TITLE ===$" contains=bkmrPlaceholder,bkmrTemplate,bkmrCodeComment

" Snippet placeholders in content
syn match bkmrPlaceholder "\$\d\+"
syn match bkmrPlaceholder "\${\d\+}"
syn match bkmrPlaceholder "\${\d\+:[^}]*}"

" Template variables in content
syn match bkmrTemplate "{{[^}]*}}"

" Comments within code content
syn match bkmrCodeComment "//.*$" contained
syn match bkmrCodeComment "#\s.*$" contained

" Define highlight groups
hi def link bkmrComment Comment
hi def link bkmrSection Statement
hi def link bkmrSectionID Identifier
hi def link bkmrSectionContent Type
hi def link bkmrSectionTitle Function
hi def link bkmrSectionTags Keyword
hi def link bkmrSectionComments PreProc
hi def link bkmrSectionEnd Special
hi def link bkmrPlaceholder Identifier
hi def link bkmrTemplate Function
hi def link bkmrCodeComment Comment

let b:current_syntax = "bkmr"