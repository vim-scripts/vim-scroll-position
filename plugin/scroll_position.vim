if exists("scroll_position")
  finish
endif
let scroll_position = 1

call scroll_position#show()
command! -nargs=0 ScrollPositionShow call scroll_position#show()
command! -nargs=0 ScrollPositionHide call scroll_position#hide()
command! -nargs=0 ScrollPositionToggle call scroll_position#toggle()
