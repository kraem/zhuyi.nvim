function zhuyi#new_note()
  call luaeval('require("zhuyi").new_note()')
endfunction

command ZhuyiNewNote :call zhuyi#new_note()
