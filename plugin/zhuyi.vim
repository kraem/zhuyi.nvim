function zhuyi#new_note()
  call luaeval('require("zhuyi").new_note()')
endfunction

function zhuyi#index()
  call luaeval('require("zhuyi").index()')
endfunction

command ZhuyiNewNote :call zhuyi#new_note()
command ZhuyiIndex   :call zhuyi#index()
