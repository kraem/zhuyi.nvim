local api = vim.api
local luv = vim.loop
local open_mode = luv.constants.O_CREAT + luv.constants.O_WRONLY + luv.constants.O_TRUNC

local alphabet = 'abcdefghijklmnopqrstuvwxyz'

local ext_md = '.md'
local delim_fm = '---'

local function get_time()
  -- TODO these can be 2 different times
  -- not in the mood for string rebuilding magic..
  local time_file = os.date("%y%m%d-%H%M")
  local time_fm = os.date("%Y-%m-%d %H:%M")
  return time_file, time_fm
end

local function get_config()
  -- TODO
  -- assert and exit sanely
  return os.getenv("ZHUYI_PATH")
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

function new_note()
  local zp = get_config()
  local time_file, time_fm = get_time()
  local new_note_name = zp .. time_file
  local new_note_path = zp .. time_file .. ext_md
  if not file_exists(new_note_path)then
    write_file(new_note_path, time_fm)
    return true
  else
    for i=1, string.len(alphabet) do
      local c = string.sub(alphabet, i, i)
      local new_note_path = zp .. time_file .. c .. ext_md
      if not file_exists(new_note_path) then
        write_file(new_note_path, time_fm)
        return true
      end
    end
  end
  return false
end

return {
  new_note = new_note
}
