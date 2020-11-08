function zhuyi#new_note()
  call luaeval('require("zhuyi").new_note()')
endfunction

function zhuyi#index()
  call luaeval('require("zhuyi").index()')
endfunction

function zhuyi#unlinked_nodes()
  call luaeval('require("zhuyi").unlinked_nodes()')
endfunction

command ZhuyiNewNote    :call zhuyi#new_note()
command ZhuyiIndex      :call zhuyi#index()
command ZhuyiUnlinked   :call zhuyi#unlinked_nodes()
