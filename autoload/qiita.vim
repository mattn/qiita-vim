let s:api = {}
let s:user = {}
let s:tag = {}
let s:item = {}

function! s:api.rate_limit()
  return webapi#json#decode(webapi#http#get('https://qiita.com/api/v1/rate_limit', {'token': self.token}).content)
endfunction

function! s:api.tag(name)
  let tags = self.tags()
  let tags = filter(tags, 'v:val.name == a:name')
  return tags[0]
endfunction

function! s:api.tags()
  let res = webapi#json#decode(webapi#http#get('https://qiita.com/api/v1/tags', {'token': self.token}).content)
  if type(res) == 4 && has_key(res, 'error')
    throw res.error
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
  if has_keys(param, 'uuid')
    let res = webapi#json#decode(webapi#http#post(printf('https://qiita.com/api/v1/items/%s', params['uuid']), webapi#json#encode(params), {'Content-Type': 'application/json'}).content)
  else
    let res = webapi#json#decode(webapi#http#post('https://qiita.com/api/v1/items', webapi#json#encode(params), {'Content-Type': 'application/json'}).content)
  endif
  if has_key(res, 'error')
    throw res.error
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

function! s:api.user(user)
  let res = webapi#json#decode(webapi#http#get(printf('https://qiita.com/api/v1/users/%s', a:user), {'token': self.token}).content)
  if has_key(res, 'error')
    throw res.error
  endif
  let user = deepcopy(s:user)
  let user['token'] = self.token
  let user['item_count'] = res['items']
  for [k, v] in items(res)
    if !has_key(user, k)
      let user[k] = v
    endif
    unlet v
  endfor
  return user
endfunction

function! s:user.item(uuid)
  let items = self.items()
  let items = filter(items, 'v:val.uuid == a:uuid')
  return items[0]
endfunction

function! s:user.items()
  let res = webapi#json#decode(webapi#http#get(printf('https://qiita.com/api/v1/users/%s/items', self.url_name), {'token': self.token}).content)
  if type(res) == 4 && has_key(res, 'error')
    throw res.error
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
  return webapi#json#decode(webapi#http#get(printf('https://qiita.com/api/v1/users/%s/stocks', self.url_name), {'token': self.token}).content)
endfunction

function! s:tag.items()
  let res = webapi#json#decode(webapi#http#get(printf('https://qiita.com/api/v1/tags/%s/items', self.name), {'token': self.token}).content)
  if type(res) == 4 && has_key(res, 'error')
    throw res.error
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

function! s:item.delete()
  let res = webapi#http#post(printf('https://qiita.com/api/v1/items/%s', self['uuid']), {'token': self.token}, {'X-HTTP-Override-Method': 'DELETE'})
  if res.header[0] !~ ' 20[0-9] '
    throw res.header[0]
  endif
  return 1
endfunction

function! qiita#createApi(token)
  let api = deepcopy(s:api)
  let api['token'] = a:token
  return api
endfunction

function! qiita#createApiWithAuth(url_name, password)
  let res = webapi#json#decode(webapi#http#post('https://qiita.com/api/v1/auth', {'url_name': a:url_name, 'password': a:password}).content)
  if has_key(res, 'error')
    throw res.error
  endif
  let api = deepcopy(s:api)
  let api['token'] = res.token
  return api
endfunction
