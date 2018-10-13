let s:api = {}
let s:user = {}
let s:tag = {}
let s:item = {}

function! s:api.rate_limit()
  return webapi#json#decode(webapi#http#get('https://qiita.com/api/v2/rate_limit', {'token': self.token}).content)
endfunction

function! s:api.tag(name)
  let tags = self.tags()
  let tags = filter(tags, 'v:val.name == a:name')
  return tags[0]
endfunction

function! s:api.tags()
  let res = webapi#json#decode(webapi#http#get('https://qiita.com/api/v2/tags', {'token': self.token}).content)
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
  let params['token'] = self.token
  if has_key(params, 'id')
    let res = webapi#json#decode(webapi#http#post(printf('https://qiita.com/api/v2/items/%s', params['id']), webapi#json#encode(params), {'Content-Type': 'application/json'}).content)
  else
    let res = webapi#json#decode(webapi#http#post('https://qiita.com/api/v2/items', webapi#json#encode(params), {'Content-Type': 'application/json'}).content)
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
  let res = webapi#json#decode(webapi#http#get(printf('https://qiita.com/api/v2/items/%s', a:id)).content)
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
  let res = webapi#json#decode(webapi#http#get(printf('https://qiita.com/api/v2/users/%s', a:user), {'token': self.token}).content)
  if has_key(res, 'type')
    throw res.type
  endif
  let user = deepcopy(s:user)
  let user['token'] = self.token
  let user['item_count'] = res['items']
  let user['url_name'] = self.url_name
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
  let res = webapi#json#decode(webapi#http#get(printf('https://qiita.com/api/v2/users/%s/items', self.url_name), {'token': self.token}).content)
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
  return webapi#json#decode(webapi#http#get(printf('https://qiita.com/api/v2/users/%s/stocks', self.url_name), {'token': self.token}).content)
endfunction

function! s:tag.items()
  let res = webapi#json#decode(webapi#http#get(printf('https://qiita.com/api/v2/tags/%s/items', self.name), {'token': self.token}).content)
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
  let res = webapi#json#decode(webapi#http#post(printf('https://qiita.com/api/v2/items/%s', self['id']), webapi#json#encode(self), {'Content-Type': 'application/json', 'X-HTTP-Method-Override': 'PUT'}).content)
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
  let res = webapi#http#post(printf('https://qiita.com/api/v2/items/%s', self['id']), {'token': self.token}, {'X-HTTP-Method-Override': 'DELETE'})
  if res.header[0] !~ ' 20[0-9] '
    throw res.header[0]
  endif
  return 1
endfunction

function! qiita#login()
  let token = ''
  if filereadable(s:configfile)
    let lines = readfile(s:configfile)
    let url_name = lines[0]
    let token = lines[1]
  endif
  if len(token) == 0
    let url_name = input("Qiita Username: ")
    let passqword = inputsecret("Qiita Password: ")
    try
      let api = qiita#createApiWithAuth(url_name, passqword)
      let token = api.token
      call writefile([url_name, token], s:configfile)
    catch
      redraw
      echohl ErrorMsg | echomsg v:exception | echohl None
      throw "couldn't authorize"
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

function! qiita#createApiWithAuth(url_name, password)
  let res = webapi#json#decode(webapi#http#post('https://qiita.com/api/v2/auth', {'url_name': a:url_name, 'password': a:password}).content)
  if has_key(res, 'type')
    throw res.type
  endif
  let api = deepcopy(s:api)
  let api['url_name'] = a:url_name
  let api['token'] = res.token
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
  call item.delete()
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

function! s:write_item(api, id, title, content)
  if len(a:id)
    redraw | echon 'Updating item... '
    let item = a:api.item(a:id)
    let item.title = a:title
    let item.body = a:content
    call s:fix_tags(item.tags)
    call item.update()
  else
    redraw | echon 'Posting item... '
    let tag = expand('%:e')
    if len(tag) == 0
      let tag = &ft
    endif
    if len(tag) == 0
      let tag = 'text'
    endif
    try
      let item = a:api.post_item({
      \ 'title': a:title,
      \ 'body': a:content,
      \ 'tags': [{'name': tag}],
      \ 'private': 0,
      \})
    catch
      redraw
      echohl ErrorMsg | echomsg v:exception | echohl None
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
  call setline(1, [webapi#html#decodeEntityReference(item.title)]+split(item.body, "\n"))
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
    echohl ErrorMsg | echomsg v:exception | echohl None
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
    echohl ErrorMsg | echomsg v:exception | echohl None
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
      let content = join(getline(2, line('$')), "\n")
      call s:write_item(api, id, title, content)
    elseif deletepost
      call s:delete_item(api, id)
    elseif len(id) > 0
      call s:open_item(api, id)
    else
      let title = getline(1)
      let content = join(getline(2, line('$')), "\n")
      call s:write_item(api, '', title, content)
    endif
  endif
  return 1
endfunction
