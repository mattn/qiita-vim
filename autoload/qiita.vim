let s:api = {}
let s:user = {}
let s:tag = {}
let s:item = {}

function! s:api.rate_limit()
  let res = webapi#http#get('https://qiita.com/api/v2/authenticated_user', {}, {'Authorization': 'Bearer ' . self.token})
  if has_key(json_decode(res.content), 'type')
    throw res.content.type
  endif
  let rate_limit = filter(deepcopy(res.header), 'v:val =~ "rate-limit: *"')
  let rate_remain = filter(deepcopy(res.header), 'v:val =~ "rate-remaining: *"')
  let res = {'rate-limit': substitute(rate_limit[0], 'rate-limit: ', '', ''), 'rate-remaining': substitute(rate_remain[0], 'rate-remaining: ', '', '')}
  return res
endfunction

function! s:api.tag(id)
  let res = json_decode(webapi#http#get(printf('https://qiita.com/api/v2/tags/%s', a:id), {}, {'Authorization': 'Bearer ' . self.token}).content)
  if has_key(res, 'type')
    throw res.type
  endif
  let tag = deepcopy(s:tag)
  let tag['token'] = self.token
  for [k, v] in items(res)
    if !has_key(tag, k)
      let tag[k] =v
    endif
    unlet v
  endfor
  return tag
endfunction

function! s:api.tags()
  let res = json_decode(webapi#http#get('https://qiita.com/api/v2/tags', {}, {'Authorization': 'Bearer ' . self.token}).content)
  if type(res) == 4 && has_key(res, 'type')
    throw res.type
  endif
  if type(res) != 3
    throw 'invalid response'
  endif
  let ret = []
  for i in res
    let tag = deepcopy(s:tag)
    let tag['token'] = self.token
    for [k, v] in items(i)
      if !has_key(tag, k)
        let tag[k] = v
      endif
      unlet v
    endfor
    call add(ret, tag)
  endfor
  return ret
endfunction

function! s:api.post_item(params)
  let params = deepcopy(a:params)
  if has_key(params, 'id')
    let res = json_decode(webapi#http#post(printf('https://qiita.com/api/v2/items/%s', params['id']), json_encode(params),
                                                \ {'Content-Type': 'application/json', 'Authorization': 'Bearer ' . self.token}).content)
  else
    let res = json_decode(webapi#http#post('https://qiita.com/api/v2/items', json_encode(params),
                                         \ {'Content-Type': 'application/json', 'Authorization': 'Bearer ' . self.token}).content)
  endif
  if has_key(res, 'type')
    throw res.type
  endif
  let item = deepcopy(s:item)
  for [k, v] in items(res)
    if !has_key(item, k)
      let item[k] = v
    endif
    unlet v
  endfor
  return item
endfunction

function! s:api.item(id)
  let res = json_decode(webapi#http#get(printf('https://qiita.com/api/v2/items/%s', a:id)).content)
  if has_key(res, 'type')
    throw res.type
  endif
  let item = deepcopy(s:item)
  let item['token'] = self.token
  for [k, v] in items(res)
    if !has_key(item, k)
      let item[k] = v
    endif
    unlet v
  endfor
  return item
endfunction

function! s:api.user(user)
  let res = json_decode(webapi#http#get(printf('https://qiita.com/api/v2/users/%s', a:user), {}, {'Authorization': 'Bearer ' . self.token}).content)
  if has_key(res, 'type')
    throw res.type
  endif
  let user = deepcopy(s:user)
  let user['token'] = self.token
  let user['url_name'] = res['id']
  for [k, v] in items(res)
    if !has_key(user, k)
      let user[k] = v
    endif
    unlet v
  endfor
  return user
endfunction

function! s:user.item(id)
  let items = self.items()
  let items = filter(items, 'v:val.id == a:id')
  return items[0]
endfunction

function! s:user.items()
  let res = json_decode(webapi#http#get(printf('https://qiita.com/api/v2/users/%s/items', self.url_name), {}, {'Authorization': 'Bearer ' . self.token}).content)
  if type(res) == 4 && has_key(res, 'type')
    throw res.type
  endif
  if type(res) != 3
    throw 'invalid response'
  endif
  let ret = []
  for i in res
    let item = deepcopy(s:item)
    let item['token'] = self.token
    for [k, v] in items(i)
      if !has_key(item, k)
        let item[k] = v
      endif
      unlet v
    endfor
    call add(ret, item)
  endfor
  return ret
endfunction

function! s:user.stocks()
  return json_decode(webapi#http#get(printf('https://qiita.com/api/v2/users/%s/stocks', self.url_name), {}, {'Authorization': 'Bearer ' . self.token}).content)
endfunction

function! s:tag.items()
  let res = json_decode(webapi#http#get(printf('https://qiita.com/api/v2/tags/%s/items', self.id), {}, {'Authorization': 'Bearer ' . self.token}).content)
  if type(res) == 4 && has_key(res, 'type')
    throw res.type
  endif
  if type(res) != 3
    throw 'invalid response'
  endif
  let ret = []
  for i in res
    let item = deepcopy(s:item)
    let item['token'] = self.token
    for [k, v] in items(i)
      if !has_key(item, k)
        let item[k] = v
      endif
      unlet v
    endfor
    call add(ret, item)
  endfor
  return ret
endfunction

function! s:item.update()
  let content = {'body': self['body'],
               \ 'id': self['id'],
               \ 'title': self['title'],
               \ 'tags': self['tags'],
               \ 'private': v:false,
               \}
  let res = json_decode(webapi#http#post(printf('https://qiita.com/api/v2/items/%s', self['id']), json_encode(content), {'Content-Type': 'application/json', 'X-HTTP-Method-Override': 'PATCH', 'Authorization': 'Bearer ' . self.token}).content)
  if has_key(res, 'type')
    throw res.type
  endif
  for [k, v] in items(res)
    if !has_key(self, k)
      let self[k] = v
    endif
    unlet v
  endfor
  return 1
endfunction

function! s:item.delete()
  let res = webapi#http#post(printf('https://qiita.com/api/v2/items/%s', self['id']), {}, {'Authorization': 'Bearer ' . self.token}, 'DELETE')
  if res.status !~ '20[0-9]'
    throw res.content
  endif
  return 1
endfunction

function! qiita#login()
  let token = ''
  if filereadable(s:configfile) && len(readfile(s:configfile)) != 0
    let lines = readfile(s:configfile)
    let url_name = lines[0]
    let token = lines[1]
  endif
  if len(token) == 0
    let url_name = input("Qiita name: ")
    redraw
    echomsg 'Please make token at https://qiita.com/settings/applications:'
    let token = input("token: ")
    try
      call writefile([url_name, token], s:configfile)
    catch
      redraw
      echohl ErrorMsg | echomsg 'qiita#login: ' . v:exception | echohl None
      throw "couldn't write to config"
    endtry
  endif
  return qiita#createApi(url_name, token)
endfunction

function! qiita#createApi(url_name, token)
  let api = deepcopy(s:api)
  let api['url_name'] = a:url_name
  let api['token'] = a:token
  return api
endfunction

function! s:shellwords(str)
  let words = split(a:str, '\%(\([^ \t\''"]\+\)\|''\([^\'']*\)''\|"\(\%([^\"\\]\|\\.\)*\)"\)\zs\s*\ze')
  let words = map(words, 'substitute(v:val, ''\\\([\\ ]\)'', ''\1'', "g")')
  let words = map(words, 'matchstr(v:val, ''^\%\("\zs\(.*\)\ze"\|''''\zs\(.*\)\ze''''\|.*\)$'')')
  return words
endfunction

function! s:delete_item(api, id)
  redraw | echon 'Deleting item... '
  let item = a:api.item(a:id)
  try
    call item.delete()
  catch
    redraw
    echohl ErrorMsg | echomsg 'delete_item> item.delete: ' . v:exception | echohl None
    return
  endtry
  redraw | echomsg 'Done'
endfunction

function! s:fix_tags(tags)
  for tag in a:tags
    if tag.name == ''
      let ext = expand('%:e')
      if len(ext) == 0
        let ext = &ft
      endif
      if len(ext) == 0
        let ext = 'text'
      endif
      let tag['name'] = ext
    endif
  endfor
endfunction


function! s:gettags(tags_string)
  if len(a:tags_string) == 0
    return []
  endif

  let tags_list = split(a:tags_string, '\s')
  let ret = []
  " generate tags list.
  for id in tags_list
    if id == ''
      continue
    endif

    if match(id, ":") > 0
      call add(ret, {'name': matchstr(id, "\\zs[^:]*\\ze:"),
                   \ 'versions': [matchstr(id, ":\\zs.*\\ze")]})
    else
      call add(ret, {'name': id})
    endif
  endfor

  return ret
endfunction


function! s:write_item(api, id, title, tags, content)
  if len(a:id)
    redraw | echon 'Updating item... '
    let item = a:api.item(a:id)
    let item.title = a:title
    let item.body = a:content
    let item.tags = a:tags
    call s:fix_tags(item.tags)
    try
      call item.update()
    catch
      redraw
      echohl ErrorMsg | echomsg 'write_item: updating item: ' . v:exception | echohl None
      return
    endtry
  else
    redraw | echon 'Posting item... '
    if len(a:tags) == 0
      if len(&ft) == 0
        let l:tags = [{'name': 'text'}]
      else
        let l:tags = [{'name': &ft}]
      endif
    else
      let l:tags = a:tags
    endif
    try
      let item = a:api.post_item({
      \ 'title': a:title,
      \ 'body': a:content,
      \ 'tags': l:tags,
      \ 'private': v:false,
      \})
    catch
      redraw
      echohl ErrorMsg | echomsg 'write_item: ' . v:exception | echohl None
      return
    endtry
  endif
  redraw | echomsg 'Done: ' . item.url
  setlocal nomodified
endfunction

function! s:write_action(fname)
  if substitute(a:fname, '\\', '/', 'g') == expand("%:p:gs@\\@/@")
    Qiita -e
  else
    exe "w".(v:cmdbang ? "!" : "") fnameescape(v:cmdarg) fnameescape(a:fname)
    silent! exe "file" fnameescape(a:fname)
    silent! au! BufWriteCmd <buffer>
  endif
endfunction

function! s:open_item(api, id)
  let winnum = bufwinnr(bufnr('qiita:'.a:id))
  if winnum != -1
    if winnum != bufwinnr('%')
      exe winnum 'wincmd w'
    endif
    setlocal modifiable
  else
    exec 'silent noautocmd new'
    setlocal noswapfile
    exec 'noautocmd file qiita:'.a:id
  endif
  filetype detect
  silent %d _
  echon 'Getting item... '
  redraw

  let item = a:api.item(a:id)
  let l:tag_line = ''
  for tag in item.tags
    if tag['versions'] == []
      let tag_line.=tag['name'] . ' '
    else
      let tag_line.=tag['name'] . ':' . tag['versions'][0] . ' '
    endif
    " [{'name': '', 'versions': ''}, ...]
  endfor
  call setline(1, [webapi#html#decodeEntityReference(item.title), tag_line]+split(item.body, "\n"))
  setlocal buftype=acwrite bufhidden=delete noswapfile
  setlocal nomodified
  setlocal ft=markdown
  au! BufWriteCmd <buffer> call s:write_action(expand("<amatch>"))
endfunction

function! s:list_action()
  let line = getline('.')
  let mx = '^\([a-z0-9]\+\)\ze:'
  let id = matchstr(line, mx)
  if len(id)
    let api = qiita#createApi(b:qiita_url_name, b:qiita_token)
    call s:open_item(api, id)
  endif
endfunction

function! s:list_user_items(api, user)
  let winnum = bufwinnr(bufnr('qiita-list'))
  if winnum != -1
    if winnum != bufwinnr('%')
      exe winnum 'wincmd w'
    endif
    setlocal modifiable
  else
    exec 'silent noautocmd split qiita-list'
  endif

  setlocal modifiable
  try
    let old_undolevels = &undolevels
    silent %d _
    redraw | echon 'Listing items... '
    let items = a:api.user(a:user).items()
    call setline(1, split(join(map(items, 'v:val.id . ": " . webapi#html#decodeEntityReference(v:val.title)'), "\n"), "\n"))
  catch
    bw!
    redraw
    echohl ErrorMsg | echomsg 'list_user_items: ' . v:exception | echohl None
    return
  finally
    let &undolevels = old_undolevels
  endtry

  setlocal buftype=nofile bufhidden=hide noswapfile
  setlocal nomodified
  setlocal nomodifiable
  syntax match SpecialKey /^[a-z0-9]\+:/he=e-1
  let b:qiita_url_name = a:api.url_name 
  let b:qiita_token = a:api.token 
  nnoremap <silent> <buffer> <cr> :call <SID>list_action()<cr>

  nohlsearch
  redraw | echo ''
endfunction

let s:configfile = expand('~/.qiita-vim')

function! qiita#Qiita(...)
  redraw

  let ls = ''
  let id = ''
  let editpost = 0
  let deletepost = 0
  try
    let api = qiita#login()
  catch
    redraw
    echohl ErrorMsg | echomsg "qiita#Qiita: " . v:exception | echohl None
    return
  endtry

  let args = (a:0 > 0) ? s:shellwords(a:1) : []
  for arg in args
    if arg =~ '^\(-h\|--help\)$\C'
      help :Qiita
      return
    elseif arg =~ '^\(-l\|--list\)$\C'
      let ls = api.url_name
    elseif arg =~ '^\(-e\|--edit\)$\C'
      let fname = expand("%:p")
      let id = matchstr(fname, '.*qiita:\zs[a-z0-9]\+\ze$')
      let editpost = 1
    elseif arg =~ '^\(-d\|--delete\)$\C'
      let fname = expand("%:p")
      let id = matchstr(fname, '.*qiita:\zs[a-z0-9]\+\ze$')
      let deletepost = 1
    elseif arg !~ '^-'
      if len(ls) > 0
        let ls = arg
      elseif arg =~ '^[0-9a-z]\+$\C'
        let id = arg
      else
        echohl ErrorMsg | echomsg 'Invalid arguments: '.arg | echohl None
        unlet args
        return 0
      endif
    elseif len(arg) > 0
      echohl ErrorMsg | echomsg 'Invalid arguments: '.arg | echohl None
      unlet args
      return 0
    endif
  endfor
  unlet args

  if len(ls) > 0
    call s:list_user_items(api, ls)
  else
    if editpost
      let title = getline(1)
      let tags = s:gettags(getline(2))
      let content = join(getline(3, '$'), "\n")
      call s:write_item(api, id, title, tags, content)
    elseif deletepost
      call s:delete_item(api, id)
    elseif len(id) > 0
      call s:open_item(api, id)
    else
      let title = getline(1)
      let tags = s:gettags(getline(2))
      let content = join(getline(3, '$'), "\n")
      call s:write_item(api, '', title, tags, content)
    endif
  endif
  return 1
endfunction
