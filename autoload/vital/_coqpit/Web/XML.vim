" ___vital___
" NOTE: lines between '" ___vital___' is generated by :Vitalize.
" Do not modify the code nor insert new lines before '" ___vital___'
function! s:_SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
endfunction
execute join(['function! vital#_coqpit#Web#XML#import() abort', printf("return map({'parseFile': '', '_vital_depends': '', 'createElement': '', 'parse': '', 'decodeEntityReference': '', 'encodeEntityReference': '', 'parseURL': '', '_vital_loaded': ''}, \"vital#_coqpit#function('<SNR>%s_' . v:key)\")", s:_SID()), 'endfunction'], "\n")
delfunction s:_SID
" ___vital___
let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V

  let s:S = s:V.import('Data.String')
  let s:H = s:V.import('Web.HTTP')
endfunction

function! s:_vital_depends() abort
  return ['Data.String', 'Web.HTTP']
endfunction

let s:__template = { 'name': '', 'attr': {}, 'child': [] }

function! s:decodeEntityReference(str) abort
  if a:str ==# ''
    return a:str
  endif
  let str = a:str
  let str = substitute(str, '&gt;', '>', 'g')
  let str = substitute(str, '&lt;', '<', 'g')
  "let str = substitute(str, '&quot;', '"', 'g')
  "let str = substitute(str, '&apos;', "'", 'g')
  "let str = substitute(str, '&nbsp;', ' ', 'g')
  "let str = substitute(str, '&yen;', '\&#65509;', 'g')
  let str = substitute(str, '&#x\([0-9a-fA-F]\+\);', '\=s:S.nr2enc_char("0x".submatch(1))', 'g')
  let str = substitute(str, '&#\(\d\+\);', '\=s:S.nr2enc_char(submatch(1))', 'g')
  let str = substitute(str, '&amp;', '\&', 'g')
  return str
endfunction

function! s:encodeEntityReference(str) abort
  if a:str ==# ''
    return a:str
  endif
  let str = a:str
  let str = substitute(str, '&', '\&amp;', 'g')
  let str = substitute(str, '>', '\&gt;', 'g')
  let str = substitute(str, '<', '\&lt;', 'g')
  let str = substitute(str, '"', '\&#34;', 'g')
  "let str = substitute(str, "\n", '\&#x0d;', 'g')
  "let str = substitute(str, '"', '&quot;', 'g')
  "let str = substitute(str, "'", '&apos;', 'g')
  "let str = substitute(str, ' ', '&nbsp;', 'g')
  return str
endfunction

function! s:__matchNode(node, cond) abort
  if type(a:cond) == 1 && a:node.name == a:cond
    return 1
  endif
  if type(a:cond) == 2
    return a:cond(a:node)
  endif
  if type(a:cond) == 3
    let ret = 1
    for R in a:cond
      if !s:__matchNode(a:node, R) | let ret = 0 | endif
      unlet R
    endfor
    return ret
  endif
  if type(a:cond) == 4
    for k in keys(a:cond)
      if has_key(a:node.attr, k) && a:node.attr[k] == a:cond[k] | return 1 | endif
    endfor
  endif
  return 0
endfunction

function! s:__template.childNode(...) dict abort
  for c in self.child
    if type(c) == 4 && s:__matchNode(c, a:000)
      return c
    endif
    unlet c
  endfor
  return {}
endfunction

function! s:__template.childNodes(...) dict abort
  let ret = []
  for c in self.child
    if type(c) == 4 && s:__matchNode(c, a:000)
      let ret += [c]
    endif
    unlet c
  endfor
  return ret
endfunction

function! s:__template.value(...) dict abort
  if a:0
    let self.child = a:000
    return
  endif
  let ret = ''
  for c in self.child
    if type(c) <= 1 || type(c) == 5
      let ret .= c
    elseif type(c) == 4
      let ret .= c.value()
    endif
    unlet c
  endfor
  return ret
endfunction

function! s:__template.find(...) dict abort
  for c in self.child
    if type(c) == 4
      if s:__matchNode(c, a:000)
        return c
      endif
      unlet! ret
      let ret = c.find(a:000)
      if !empty(ret)
        return ret
      endif
    endif
    unlet c
  endfor
  return {}
endfunction

function! s:__template.findAll(...) dict abort
  let ret = []
  for c in self.child
    if type(c) == 4
      if s:__matchNode(c, a:000)
        call add(ret, c)
      endif
      let ret += c.findAll(a:000)
    endif
    unlet c
  endfor
  return ret
endfunction

function! s:__template.toString() dict abort
  let xml = '<' . self.name
  for attr in keys(self.attr)
    let xml .= ' ' . attr . '="' . s:encodeEntityReference(self.attr[attr]) . '"'
  endfor
  if len(self.child)
    let xml .= '>'
    for c in self.child
      if type(c) == 4
        let xml .= c.toString()
      elseif type(c) > 1
        let xml .= s:encodeEntityReference(string(c))
      else
        let xml .= s:encodeEntityReference(c)
      endif
      unlet c
    endfor
    let xml .= '</' . self.name . '>'
  else
    let xml .= ' />'
  endif
  return xml
endfunction

function! s:createElement(name) abort
  let node = deepcopy(s:__template)
  let node.name = a:name
  return node
endfunction

" @vimlint(EVL102, 1, l:content)
function! s:__parse_tree(ctx, top) abort
  let node = a:top
  let stack = [a:top]
  " content accumulates the text only tags
  let content = ''
  let append_content_to_parent = 'if len(stack) && content != "" | call add(stack[-1].child, content) | let content ="" | endif'

  let mx = '^\s*\(<?xml[^>]\+>\)'
  if a:ctx['xml'] =~ mx
    let match = matchstr(a:ctx['xml'], mx)
    let a:ctx['xml'] = a:ctx['xml'][stridx(a:ctx['xml'], match) + len(match):]
    let mx = 'encoding\s*=\s*["'']\{0,1}\([^"'' \t]\+\|[^"'']\+\)["'']\{0,1}'
    let matches = matchlist(match, mx)
    if len(matches)
      let encoding = matches[1]
      if encoding !=# '' && a:ctx['encoding'] ==# ''
        let a:ctx['encoding'] = encoding
        let a:ctx['xml'] = iconv(a:ctx['xml'], encoding, &encoding)
      endif
    endif
  endif

  " this regex matches
  " 1) the remaining until the next tag begins
  "    2) maybe closing "/" of tag name
  "    3) tagname
  "    4) the attributes of the text (optional)
  "    5) maybe closing "/" (end of tag name)
  " or
  "    6) CDATA or ''
  "    7) text content of CDATA
  " or
  "    8) comment
  " (These numbers correspond to the indexes in matched list m)
  let tag_mx = '^\(\_.\{-}\)\%(\%(<\(/\?\)\([^!/>[:space:]]\+\)\(\%([[:space:]]*[^/>=[:space:]]\+[[:space:]]*=[[:space:]]*\%([^"'' >\t]\+\|"[^"]*"\|''[^'']*''\)\|[[:space:]]\+[^/>=[:space:]]\+[[:space:]]*\)*\)[[:space:]]*\(/\?\)>\)\|\%(<!\[\(CDATA\)\[\(.\{-}\)\]\]>\)\|\(<!--.\{-}-->\)\)'

  while a:ctx.xml !=# ''
    let m = matchlist(a:ctx.xml, tag_mx)
    if empty(m) | break | endif
    let a:ctx.xml = a:ctx.xml[len(m[0]) :]
    let is_end_tag = m[2] ==# '/' && m[5] ==# ''
    let is_start_and_end_tag = m[2] ==# '' && m[5] ==# '/'
    let tag_name = m[3]
    let attrs = m[4]

    let content .= s:decodeEntityReference(m[1])

    if is_end_tag
      " closing tag: pop from stack and continue at upper level
      exec append_content_to_parent

      if len(stack) " TODO: checking whether opened tag exists.
        call remove(stack, -1)
      endif
      continue
    endif

    " comment tag
    if m[8] !=# ''
      continue
    endif

    " if element is a CDATA
    if m[6] !=# ''
      let content .= m[7]
      continue
    endif

    let node = deepcopy(s:__template)
    let node.name = tag_name
    let attr_mx = '\([^=[:space:]]\+\)\s*\%(=\s*''\([^'']*\)''\|=\s*"\([^"]*\)"\|=\s*\(\w\+\)\|\)'
    while attrs !=# ''
      let attr_match = matchlist(attrs, attr_mx)
      if len(attr_match) == 0
        break
      endif
      let name = attr_match[1]
      let value = attr_match[2] !=# '' ? attr_match[2] : attr_match[3] !=# '' ? attr_match[3] : attr_match[4] !=# '' ? attr_match[4] : ''
      let node.attr[name] = s:decodeEntityReference(value)
      let attrs = attrs[stridx(attrs, attr_match[0]) + len(attr_match[0]):]
    endwhile

    exec append_content_to_parent

    if len(stack)
      call add(stack[-1].child, node)
    endif
    if !is_start_and_end_tag
      " opening tag, continue parsing its contents
      call add(stack, node)
    endif
  endwhile
endfunction
" @vimlint(EVL102, 0, l:content)

function! s:parse(xml) abort
  let top = deepcopy(s:__template)
  let oldmaxmempattern = &maxmempattern
  let oldmaxfuncdepth = &maxfuncdepth
  let &maxmempattern = 2000000
  let &maxfuncdepth = 2000
  try
    call s:__parse_tree({'xml': a:xml, 'encoding': ''}, top)
    for node in top.child
      if type(node) == 4
        return node
      endif
      unlet node
    endfor
  finally
    let &maxmempattern = oldmaxmempattern
    let &maxfuncdepth = oldmaxfuncdepth
  endtry
  throw 'vital: Web.XML: Parse Error'
endfunction

function! s:parseFile(fname) abort
  return s:parse(join(readfile(a:fname), "\n"))
endfunction

function! s:parseURL(url) abort
  return s:parse(s:H.get(a:url).content)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0: