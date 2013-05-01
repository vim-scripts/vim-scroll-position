if exists("scroll_position")
  finish
endif
let scroll_position = 1

command! -nargs=0 ScrollPositionShow call scroll_position#show()
command! -nargs=0 ScrollPositionHide call scroll_position#hide()
command! -nargs=0 ScrollPositionToggle call scroll_position#toggle()

if !exists('g:scroll_position_auto_enable') || g:scroll_position_auto_enable
  call scroll_position#show()
end
