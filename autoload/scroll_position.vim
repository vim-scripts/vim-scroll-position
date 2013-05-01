if exists("g:scroll_position_loaded") || !has('signs')
  finish
endif
let g:scroll_position_loaded = 1

function scroll_position#show()
  let s:types = {}

  if exists("g:scroll_position_jump")
    exec "sign define scroll_position_j text=".g:scroll_position_jump." texthl=ScrollPositionJump"
    let s:types['j'] = "''"
  endif
  if exists("g:scroll_position_change")
    exec "sign define scroll_position_c text=".g:scroll_position_change." texthl=ScrollPositionchange"
    let s:types['c'] = "'."
  endif

  " For visual range
  if !exists("g:scroll_position_visual")
    let g:scroll_position_visual = 1
  endif

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
  let s:types['m'] = "."
  exec "sign define scroll_position_m text=".g:scroll_position_marker." texthl=ScrollPositionMarker"

  let s:vtypes['vb'] = "."
  let s:vtypes['ve'] = "v"
  exec "sign define scroll_position_vb text=".g:scroll_position_visual_begin." texthl=ScrollPositionVisualBegin"
  exec "sign define scroll_position_vm text=".g:scroll_position_visual_middle." texthl=ScrollPositionVisualMiddle"
  exec "sign define scroll_position_ve text=".g:scroll_position_visual_end." texthl=ScrollPositionVisualEnd"
  exec "sign define scroll_position_vo text=".g:scroll_position_visual_overlap." texthl=ScrollPositionVisualOverlap"
  sign define scroll_position_e

  if !exists("g:scroll_position_exclusion")
    let g:scroll_position_exclusion = "&buftype == 'nofile'"
  endif

  augroup ScrollPosition
    autocmd!
    autocmd BufNewFile,BufRead * exec printf("sign place 8888880 line=1 name=scroll_position_e buffer=%d", bufnr('%'))
    autocmd WinEnter,CursorMoved,CursorMovedI,VimResized * :call scroll_position#update()
  augroup END

  let s:format = "sign place 99999%d line=%d name=scroll_position_%s buffer=%d"
  let s:scroll_position_enabled = 1
  call scroll_position#update()
endfunction

function! s:NumSort(a, b)
  return a:a>a:b ? 1 : a:a==a:b ? 0 : -1
endfunction

function scroll_position#update()
  if eval(g:scroll_position_exclusion)
    return
  endif

  let top    = line('w0')
  let lines  = line('$')
  let height = line('w$') - top + 1
  let bfr    = bufnr('%')

  if !exists('b:scroll_position_pplaces')
    let b:scroll_position_pplaces = {}
    let b:scroll_position_plines = line('$')
  endif
  if g:scroll_position_visual > 0 && mode() == 'v'
    let types = s:vtypes
  else
    let types = s:types
  endif

  let places = {}
  let places_r = {}
  let pplaces = b:scroll_position_pplaces
  for [type, l] in items(types)
    let line = line(l)
    if line
      let lineno = top + float2nr(height * (line - 1) / lines)
      if type == 'vb' || type == 've'
        let places_r[ type ] = lineno
      else
        let places[ lineno ] = type
      endif
    endif
  endfor

  " Display visual range
  if g:scroll_position_visual > 0 && mode() == 'v'
    let [b, e] = sort([places_r['vb'], places_r['ve']], 's:NumSort')
    if b < e
      let places[b] = 'vb'
      if g:scroll_position_visual > 1
        for l in range(b + 1, e - 1)
          let places[l] = 'vm'
        endfor
      endif
      let places[e] = 've'
    else
      let places[b] = 'vo'
    endif
  endif

  let lines_changed = lines != b:scroll_position_plines

  " Remove all previous signs when total number of lines changed
  let pkeys = keys(pplaces)
  if lines_changed
    for pos in pkeys
      exec printf("sign unplace 99999%d buffer=%d", pos, bfr)
    endfor
  endif

  " Place signs when required
  " - Total number of lines changed (cleared)
  " - New position
  " - Type changed
  for [pos, type] in items(places)
    if lines_changed || !has_key(pplaces, pos) || type != pplaces[pos]
      exec printf(s:format, pos, pos, type, bfr)
    endif
  endfor

  " Remove invalidated signs (after placing new signs!)
  if !lines_changed
    for pp in pkeys
      if !has_key(places, pp)
        exec printf("sign unplace 99999%d buffer=%d", pp, bfr)
      endif
    endfor
  endif

  let b:scroll_position_plines = lines
  let b:scroll_position_pplaces = places
endfunction

function scroll_position#hide()
  augroup ScrollPosition
    autocmd!
  augroup END
 " FIXME
  sign unplace *
  let b:scroll_position_pplaces = {}
  let b:scroll_position_plines = 0
  let s:scroll_position_enabled = 0
endfunction

function scroll_position#toggle()
  if s:scroll_position_enabled
    call scroll_position#hide()
  else
    call scroll_position#show()
  endif
endfunction
