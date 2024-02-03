if exists("b:current_syntax")
    finish
end

syntax match mynotesDate "\v\d{4}-\d{2}-\d{2}"

syntax match mynotesTodo "\vtodo:"
syntax match mynotesIdea "\videa:"
syntax match mynotesDone "\vdone:"
syntax match mynotesChannel "\v((^| )\zs\#[^ .]+)"
syntax match mynotesTitle "\v^\#.*$"
syntax match mynotesPseudo "\v((^| )\zs\@[^ .]+)"
syntax match mynotesTicket "\vPLAT-\d+"

"syntax region mynotesCode start=/\v```/ end=/\v```/


highlight mynotesDate gui=bold guifg=yellow
highlight mynotesTodo ctermfg=red guifg=red
highlight mynotesDone ctermfg=green guifg=green
highlight mynotesTitle ctermfg=blue guifg=#56c8ce
highlight mynotesPseudo ctermfg=yellow guifg=#2eff00
highlight mynotesChannel ctermfg=yellow guifg=#2eff00
highlight mynotesTicket ctermfg=magenta guifg=magenta
highlight mynotesIdea ctermfg=cyan guifg=cyan
"highlight mynotesCode ctermfg=red guifg=red

let b:current_syntax = "mynotes"


":highlight NearColLimit term=italic,bold cterm=italic ctermbg=yellow ctermfg=darkblue gui=bold,italic guibg=yellow guifg=darkblue
":highlight OverColLimit term=inverse,bold cterm=bold ctermbg=red ctermfg=white gui=bold guibg=red guifg=white
":syntax match NearColLimit /\%<81v.\%>77v/
":syntax match OverColLimit /\%>80v.\+/
