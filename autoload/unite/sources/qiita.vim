let s:save_cpo = &cpo
set cpo&vim

function! unite#sources#qiita#define()
  return s:source
endfunction

let s:source = {
\  "name" : "qiita",
\  "description" : "manipulate your qiitas",
\  "default_action" : "open",
\  "action_table" : {
\    "open" : {
\      "description" : "open with vim",
\      "is_selectable" : 0,
\    },
\    "browser" : {
\      "description" : "open with browser",
\      "is_selectable" : 0,
\    },
\  }
\}

function! s:source.gather_candidates(args, context)
  let api = qiita#login()
  let items = api.user(api.url_name).items()
  return map(items, '{
        \ "abbr": v:val.title,
        \ "word": v:val["id"],
        \ "action__config": v:val["id"],
        \ "action__qiita": v:val["id"],
        \ }')
endfunction

function! s:source.action_table.open.func(candidate)
  exe "Qiita" a:candidate.action__qiita
endfunction

function! s:source.action_table.browser.func(candidate)
  call OpenBrowser(printf("https://qiita.com/items/%s", a:candidate.action__qiita))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
