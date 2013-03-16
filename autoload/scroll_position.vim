if exists("g:scroll_position_loaded") || !has('signs')
  finish
endif
let g:scroll_position_loaded = 1

function scroll_position#show()
  let s:types = {}

  if exists("g:scroll_position_jump")
    exec "sign define scroll_position_jump text=".g:scroll_position_jump." texthl=ScrollPositionJump"
    let s:types['jump'] = "''"
  endif
  if exists("g:scroll_position_change")
    exec "sign define scroll_position_change text=".g:scroll_position_change." texthl=ScrollPositionchange"
    let s:types['change'] = "'."
  endif

  " For visual range
  let s:vtypes = copy(s:types)
  if !exists("g:scroll_position_visual_begin")
    let g:scroll_position_visual_begin = '^'
  endif
  if !exists("g:scroll_position_visual_middle")
    let g:scroll_position_visual_middle = ':'
  endif
  if !exists("g:scroll_position_visual_end")
    let g:scroll_position_visual_end = 'v'
  endif
  if !exists("g:scroll_position_visual_overlap")
    let g:scroll_position_visual_overlap = '<>'
  endif

  if !exists("g:scroll_position_marker")
    let g:scroll_position_marker = '>'
  endif
  let s:types['marker'] = "."
  exec "sign define scroll_position_marker text=".g:scroll_position_marker." texthl=ScrollPositionMarker"

  let s:vtypes['visual_begin'] = "."
  let s:vtypes['visual_end'] = "v"
  exec "sign define scroll_position_visual_begin text=".g:scroll_position_visual_begin." texthl=ScrollPositionVisualBegin"
  exec "sign define scroll_position_visual_middle text=".g:scroll_position_visual_middle." texthl=ScrollPositionVisualMiddle"
  exec "sign define scroll_position_visual_end text=".g:scroll_position_visual_end." texthl=ScrollPositionVisualEnd"
  exec "sign define scroll_position_visual_overlap text=".g:scroll_position_visual_overlap." texthl=ScrollPositionVisualOverlap"

  if !exists("g:scroll_position_exclusion")
    let g:scroll_position_exclusion = "&buftype == 'nofile'"
  endif

  augroup ScrollPosition
    autocmd!
    autocmd WinEnter,CursorMoved,CursorMovedI,VimResized * :call scroll_position#update()
  augroup END

  let s:format = "sign place 99999%s line=%s name=scroll_position_%s buffer=%s"
  let s:scroll_position_enabled = 1
  call scroll_position#update()
endfunction

function! s:NumSort(a, b)
  return a:a>a:b ? 1 : a:a==a:b ? 0 : -1
endfunction

function scroll_position#update()
  if exists('g:scroll_position_exclusion') && eval(g:scroll_position_exclusion)
    return
  endif

  let top    = line('w0')
  let lines  = line('$')
  let height = line('w$') - top + 1
  let bfr    = bufnr('%')

  if !exists('b:scroll_position_prev')
    let b:scroll_position_prev = {}
  endif

  if mode() == 'v'
    let types = s:vtypes
  else
    let types = s:types
  endif

  let places = {}
  let places_r = {}
  let pplaces = b:scroll_position_prev
  for [type, l] in items(types)
    let line = line(l)
    if line
      let lineno = top + float2nr(height * (line - 1) / lines)
      if type == 'visual_begin' || type == 'visual_end'
        let places_r[ type ] = lineno
      else
        let places[ lineno ] = type
      endif
    endif
  endfor

  for [pos, type] in items(places)
    if !has_key(pplaces, pos) || type != pplaces[pos]
      exec printf(s:format, pos, pos, type, bfr)
    endif
  endfor

  if mode() == 'v'
    let [b, e] = sort([places_r['visual_begin'], places_r['visual_end']], 's:NumSort')
    if b < e
      let places[b] = 'visual_begin'
      let places[e] = 'visual_end'

      exec printf(s:format, b, b, 'visual_begin', bfr)
      for l in range(b + 1, e - 1)
        exec printf(s:format, l, l, 'visual_middle', bfr)
        let places[l] = 'visual_middle'
      endfor
      exec printf(s:format, e, e, 'visual_end', bfr)
    else
      let places[b] = 'visual_overlap'
      exec printf(s:format, b, b, 'visual_overlap', bfr)
    endif
  endif

  let valid_keys = keys(places)
  for pp in keys(pplaces)
    if index(valid_keys, pp) == -1
      exec printf("sign unplace 99999%s buffer=%s", pp, bfr)
    endif
  endfor

  let b:scroll_position_prev = places
endfunction

function scroll_position#hide()
  augroup ScrollPosition
    autocmd!
  augroup END
  sign unplace *
  let b:scroll_position_prev = {}
  let s:scroll_position_enabled = 0
endfunction

function scroll_position#toggle()
  if s:scroll_position_enabled
    call scroll_position#hide()
  else
    call scroll_position#show()
  endif
endfunction
