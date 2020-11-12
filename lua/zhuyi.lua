local api = vim.api
local luv = vim.loop
local open_mode = luv.constants.O_CREAT + luv.constants.O_WRONLY + luv.constants.O_TRUNC

local rest_api = require('rest')

local alphabet = 'abcdefghijklmnopqrstuvwxyz'

local ext_md = '.md'
local ext = ext_md
local index = 'index'..ext
local delim_fm = '---'

local function get_time()
  -- TODO
  -- these can be 2 different times
  -- not in the mood for string rebuilding magic..
  local time_file = os.date("%y%m%d-%H%M")
  local time_fm = os.date("%Y-%m-%d %H:%M")
  return time_file, time_fm
end

local function get_zhuyi_path()
  local trailing_slash = '/'
  local zp = vim.g.zhuyi_path
  local l = string.len(zp)
  local c = string.sub(zp, l, l)
  if c ~= trailing_slash then
    zp = zp .. trailing_slash
  end
  -- TODO
  -- assert we've got perms
  return zp
end

local function touch_file(path)
  -- TODO
  -- check for errors
  local body = ''
  -- TODO
  -- fix 438 mode
  local fd = luv.fs_open(path, "w+", 438)
  local resp = luv.fs_write(fd, body, 0, nil)
  assert(luv.fs_close(fd))
end

local function write_fm(path, time_fm)
  -- TODO check for errors
  local newline = '\n'
  local title_fm = 'title: '
  local date_fm = 'date: '
  local body =
    delim_fm..
    newline..
    title_fm..
    newline..
    date_fm..
    time_fm..
    newline..
    delim_fm..
    newline
  -- TODO
  -- fix 438 mode
  local fd = luv.fs_open(path, "w+", 438)
  local resp = luv.fs_write(fd, body, 0, nil)
  assert(luv.fs_close(fd))
end

local function unlinked_payload_to_md(nodes)
  local md = {}
  if #nodes < 1 then
    return md
  end
  local newline = ''
  local heading = '# Unlinked'
  table.insert(md, newline)
  table.insert(md, heading)
  table.insert(md, newline)
  for _,v in pairs(nodes) do
    local node_md =
          '- ' .. '['..v.title..']'
               .. '('..v.file..')'
    table.insert(md, node_md)
  end
  return md
end

local function write_file(path, time_fm)
  -- TODO
  -- return success/err
  touch_file(path)
  write_fm(path, time_fm)
end

local function file_exists(path)
  -- TODO
  -- fix 438 mode
  local fd = luv.fs_open(path, "r", 438)
  if fd == nil then return false end
  return true
end

local function change_dir(path)
  api.nvim_set_current_dir(path)
  --api.nvim_command('cd '..path)
end

local function new_buffer()
  return api.nvim_command('enew')
end

local function open_file(fn)
  api.nvim_command('edit '..fn)
end

local function append_to_current_buffer(content)
  local cur_buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(cur_buf, -1, -1, false, content)
end

local function backend_status()
  rest_api.backend_status()
end

local function index()
  local zp = get_zhuyi_path()
  change_dir(zp)
  open_file('index.md')
end

local function unlinked_nodes()
  local nodes = {}
  rest_api.unlinked_nodes(nodes)
  local md = unlinked_payload_to_md(nodes)
  append_to_current_buffer(md)
end

local function new_note()
  local zp = get_zhuyi_path()
  local time_file, time_fm = get_time()
  local new_note_name = zp .. time_file
  local new_note_path = zp .. time_file .. ext

  local function write_and_open(path, time_fm)
    write_file(new_note_path, time_fm)
    open_file(new_note_path)
  end

  local function available_fn(new_note_path, time_file)
    for i=1, string.len(alphabet) do
      local c = string.sub(alphabet, i, i)
      local new_note_path = zp .. time_file .. c .. ext
      if not file_exists(new_note_path) then
        return true, new_note_path
      end
    end
    return false
  end

  if not file_exists(new_note_path) then
    write_and_open(new_note_path, time_fm)
    return true
  end

  ok, new_note_path = available_fn(new_note_path, time_file)
  if ok then
    write_and_open(new_note_path, time_fm)
    return true
  end

  return false
end

function follow_link()
  handle_link()
end

function handle_link()

  local function handle_non_md_link()
    local uri = vim.fn.expand('<cWORD>')
    return uri
  end

  local function handle_md_link(uri)
    local l = string.len(uri)
    uri = string.sub(uri, 2, l-1)
    return uri
  end

  local function open_non_local_link(uri)
    -- TODO
    -- this can be done more nicely async (libuv)
    -- that way we can ignore error msgs et. al.
    local xdg_open = 'xdg-open '
    local ig_output = ' 2> /dev/null'
    os.execute(xdg_open..uri..ig_output)
  end

  local function has_md_ext(uri)
    local l = string.len(uri)
    local ext = string.sub(uri, l-2, l)
    if ext ~= ext_md then return false end
    return true
  end

  local function is_http_s(uri)
    -- TODO
    -- this won't work as it's not only https uri:s we want to open in other
    -- apps than neovim.
    local http_s = 'https?'
    local ext = string.sub(uri, 1, 4)
    local match = string.match(ext, http_s)
    if match ~=nil then
      return false
    end
    return true
  end

  local function uri_is_local(uri)
    -- TODO
    -- can use get_zhuyi_path
    -- TODO
    -- this won't work as we sometimes want to open local files in other apps
    -- than neovim without more logic.
    local zhuyi_path = vim.fn.expand('%:p:h')
    local local_path = zhuyi_path..'/'..uri
    if not file_exists(local_path) then
      return false
    end
    return true
  end

  local function cur_line_md()
    local title, uri = api.nvim_get_current_line():match("(%b[])(%b())")
    if title == nil and uri == nil then
      return false, uri
    end
    return true, uri
  end

  is_md, uri = cur_line_md()

  if not is_md then
    uri = handle_non_md_link()
    open_non_local_link(uri)
    return
  end

  uri = handle_md_link(uri)
  if not has_md_ext(uri) then
    open_non_local_link(uri)
    return
  end

  open_file(uri)
end

local function del_cur_zhuyi()
  local y = 'y'
  -- TODO
  -- better way to get current file?
  -- any nvim api function?
  local cur_file_path = vim.fn.expand('%:p')
  local query = 'delete '..cur_file_path..'? (y/n) '
  if vim.fn.input(query) ~= y then
    return
  end
  local ok, err = luv.fs_unlink(cur_file_path)
  if not ok then
    -- TODO
    -- err handling?
    print(err)
    return
  end
  opts = { force = true }
  api.nvim_buf_delete(0, opts)
end

return {
  new_note = new_note,
  index = index,
  unlinked_nodes = unlinked_nodes,
  del_cur_zhuyi = del_cur_zhuyi,
  follow_link = follow_link
}
