" Only apply to *.mynotes files; avoids any race with buffer flags
if expand('%:e') !=# 'mynotes'
  finish
endif

syntax match mynotesDate "\v^\s*\d{4}-\d{2}-\d{2}"
syntax match mynotesTodo "\v^\s*todo:"
syntax match mynotesIdea "\v^\s*idea:"
syntax match mynotesDone "\v^\s*done:"
syntax match mynotesChannel "\v((^| )\zs\#[^ .]+)"
syntax match mynotesPseudo "\v((^| )\zs\@[^ .]+)"
syntax match mynotesTicket "\vPLAT-\d+"

" Highlights (use hi def so colorschemes can override)
hi def mynotesDate    gui=bold    guifg=Yellow
hi def mynotesTodo    cterm=bold  ctermfg=Red    gui=bold guifg=Red
hi def mynotesDone    cterm=bold  ctermfg=Green  gui=bold guifg=Green
hi def mynotesTitle   ctermfg=Blue               guifg=#56c8ce
hi def mynotesPseudo  ctermfg=Yellow             guifg=#2eff00
hi def mynotesChannel ctermfg=Yellow             guifg=#2eff00
hi def mynotesTicket  ctermfg=Magenta            guifg=Magenta
hi def mynotesIdea    ctermfg=Cyan               guifg=Cyan
