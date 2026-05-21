" Vim syntax file
" Language: mynotes

if exists('b:current_syntax')
  finish
endif

" Reuse the standard Markdown syntax first, then add note-specific matches.
runtime! syntax/markdown.vim
unlet! b:current_syntax

syntax match mynotesDate "\v^\s*\d{4}-\d{2}-\d{2}"
syntax match mynotesTodo "\v^\s*todo:"
syntax match mynotesIdea "\v^\s*idea:"
syntax match mynotesDone "\v^\s*done:"
syntax match mynotesChannel "\(^\|\s\)\zs#[[:alnum:]_-]\+"
syntax match mynotesPseudo "\(^\|\s\)\zs@[[:alnum:]_-]\+"
syntax match mynotesTicket "\<PLAT-\d\+\>"

highlight default mynotesDate gui=bold guifg=Yellow cterm=bold ctermfg=Yellow
highlight default mynotesTodo gui=bold guifg=Red cterm=bold ctermfg=Red
highlight default mynotesIdea guifg=Cyan ctermfg=Cyan
highlight default mynotesDone gui=bold guifg=Green cterm=bold ctermfg=Green
highlight default mynotesChannel guifg=#2eff00 ctermfg=Green
highlight default mynotesPseudo guifg=#2eff00 ctermfg=Green
highlight default mynotesTicket guifg=Magenta ctermfg=Magenta

let b:current_syntax = 'mynotes'
