if exists('g:loaded_ctrlp_qiita') && g:loaded_ctrlp_qiita
  finish
endif
let g:loaded_ctrlp_qiita = 1
let s:system = function(get(g:, 'webapi#system_function', 'system'))

let s:qiita_var = {
\  'init':   'ctrlp#qiita#init()',
\  'exit':   'ctrlp#qiita#exit()',
\  'accept': 'ctrlp#qiita#accept',
\  'lname':  'qiita',
\  'sname':  'qiita',
\  'type':   'path',
\  'sort':   0,
\}

if exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
  let g:ctrlp_ext_vars = add(g:ctrlp_ext_vars, s:qiita_var)
else
  let g:ctrlp_ext_vars = [s:qiita_var]
endif

function! ctrlp#qiita#init()
  let api = qiita#login()
  let s:list = api.user(api.url_name).items()
  return map(s:list, 'v:val.title . "\t" . v:val.id')
endfunc

function! ctrlp#qiita#accept(mode, str)
  let id = matchstr(filter(copy(s:list), 'v:val ==# a:str')[0], '\t\([a-z0-9]\+\)$')
  call ctrlp#exit()
  redraw!
  if len(id)
    exe "Qiita" id
  endif
endfunction

function! ctrlp#qiita#exit()
  if exists('s:list')
    unlet! s:list
  endif
endfunction

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
function! ctrlp#qiita#id()
  return s:id
endfunction

" vim:fen:fdl=0:ts=2:sw=2:sts=2
