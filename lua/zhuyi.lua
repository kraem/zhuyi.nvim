local api = vim.api
local luv = vim.loop
local open_mode = luv.constants.O_CREAT + luv.constants.O_WRONLY + luv.constants.O_TRUNC

local rest_api = require('zhuyi-rest')

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

local function get_config()
  local trailing_slash = '/'
  local zp = os.getenv("ZHUYI_PATH")
  local l = string.len(zp)
  local c = string.sub(zp, l, l)
  if c ~= trailing_slash then
    zp = zp .. trailing_slash
  end
  -- TODO
  -- assert we've got perms
  return zp
end

local function file_exists(path)
  -- perl -e 'printf "%d\n", (stat "201103-0034a.md")[2] & 07777'
  -- https://stackoverflow.com/questions/15055634/understanding-and-decoding-the-file-mode-value-from-stat-function-output
  local fd = luv.fs_open(path, "r", 438)
  if fd == nil then return false else return true end
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

local function write_file(path, time_fm)
  -- TODO return success
  touch_file(path)
  write_fm(path, time_fm)
end

local function change_dir(path)
  api.nvim_command('cd '..path)
end

local function new_buffer()
  return api.nvim_command('enew')
end

local function open_file(fn)
  api.nvim_command('edit '..fn)
end

local function index()
  local zp = get_config()
  change_dir(zp)
  open_file('index.md')
  -- rest_api.backend_status()
end

local function backend_status()
  rest_api.backend_status()
end

function callback(ret, nodes)
  for k,v in pairs(ret.payload.unlinked_zettels) do
    table.insert(nodes, v)
  end
end

local function unlinked_nodes()
  local zp = get_config()
  local nodes = {}
  rest_api.unlinked_nodes(callback, nodes)
  -- nodes is an array with objects
  for k,v in pairs(nodes) do
    -- loop over keys in the objects
    --for k,v in pairs(v) do
    --  print(k,v)
    --end
    fn = v.file
    fp = zp..fn
    open_file(fp)
  end
end


local function new_note()
  local zp = get_config()
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

return {
  new_note = new_note,
  index = index,
  unlinked_nodes = unlinked_nodes
}
