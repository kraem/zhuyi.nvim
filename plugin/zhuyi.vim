function zhuyi#index()
  call luaeval('require("zhuyi").index()')
endfunction

function zhuyi#new_zhuyi()
  call luaeval('require("zhuyi").new_zhuyi()')
endfunction

function zhuyi#del_zhuyi()
  call luaeval('require("zhuyi").del_cur_zhuyi()')
endfunction

function zhuyi#unlinked()
  call luaeval('require("zhuyi").unlinked()')
endfunction

function zhuyi#unlinked_rest()
  call luaeval('require("zhuyi").unlinked_rest()')
endfunction

function zhuyi#follow_link()
  call luaeval('require("zhuyi").follow_link()')
endfunction

command ZhuyiIndex        :call zhuyi#index()
command ZhuyiNew          :call zhuyi#new_zhuyi()
command ZhuyiDel          :call zhuyi#del_zhuyi()
command ZhuyiFollowLink   :call zhuyi#follow_link()
command ZhuyiUnlinked     :call zhuyi#unlinked()
command ZhuyiUnlinkedRest :call zhuyi#unlinked_rest()
