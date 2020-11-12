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
  -- TODO these can be 2 different times
  -- not in the mood for string rebuilding magic..
  local time_file = os.date("%y%m%d-%H%M")
  local time_fm = os.date("%Y-%m-%d %H:%M")
  return time_file, time_fm
end

local function get_zhuyi_path()
  local trailing_slash = '/'
  -- local zp = os.getenv("ZHUYI_PATH")
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
  -- TODO check for errors
  local body = ''
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
  -- TODO return success
  touch_file(path)
  write_fm(path, time_fm)
end

local function file_exists(path)
  -- perl -e 'printf "%d\n", (stat "201103-0034a.md")[2] & 07777'
  -- https://stackoverflow.com/questions/15055634/understanding-and-decoding-the-file-mode-value-from-stat-function-output
  local fd = luv.fs_open(path, "r", 438)
  if fd == nil then return false else return true end
end

local function change_dir(path)
  -- nvim_set_current_dir({dir})
  api.nvim_command('cd '..path)
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
  if not file_exists(new_note_path) then
    write_file(new_note_path, time_fm)
    open_file(new_note_path)
    return true
  else
    for i=1, string.len(alphabet) do
      local c = string.sub(alphabet, i, i)
      local new_note_path = zp .. time_file .. c .. ext
      if not file_exists(new_note_path) then
        write_file(new_note_path, time_fm)
        open_file(new_note_path)
        return true
      end
    end
  end
  return false
end

function follow_link()
  handle_link()
end

function handle_link()

  local function handle_non_md_link()
    --https://www.reddit.com/r/neovim/comments/i72eo7/open_link_with_gx_asynchronously/g0zd4gp/?utm_source=reddit&utm_medium=web2x&context=3
    --local cw = api.nvim_eval("expand('<cWORD>')")
    local url = vim.fn.expand('<cWORD>')
    return url
  end

  local function handle_md_link(url)
    local l = string.len(url)
    url = string.sub(url, 2, l-1)
    return url
  end

  local function open_non_local_link(url)
  -- this can be done more nicely async (libuv)
  -- that way we can ignore error msgs et. al.
    local xdg_open = 'xdg-open '
    local ig_output = ' 2> /dev/null'
    os.execute(xdg_open..url..ig_output)
  end

  local function has_md_extension(url)
    local l = string.len(url)
    local ext = string.sub(url, l-2, l)
    if ext ~= ext_md then return false end
    return true
  end

  local function cur_line_md()
    local title, url = api.nvim_get_current_line():match("(%b[])(%b())")
    if title == nil and url == nil then
      return false, url
    end
    return true, url
  end

  is_md, url = cur_line_md()

  if not is_md then
    url = handle_non_md_link()
    open_non_local_link(url)
    return
  end

  url = handle_md_link(url)
  if not has_md_extension(url) then
    open_non_local_link(url)
    return
  end

  open_file(url)
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
