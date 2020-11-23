local api = vim.api
local luv = vim.loop

local open_mode = luv.constants.O_CREAT + luv.constants.O_WRONLY +
                      luv.constants.O_TRUNC

local rest_api = require('rest')

local alphabet = 'abcdefghijklmnopqrstuvwxyz'

local ext_md = '.md'
local ext = ext_md
local index_file = 'index' .. ext
local delim_fm = '---'

local function lines_from(file)
        -- if not file_exists(file) then return {} end
        local lines = {}
        for line in io.lines(file) do lines[#lines + 1] = line end
        return lines
end

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
        if c ~= trailing_slash then zp = zp .. trailing_slash end
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

local function fm_write(path, time_fm)
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
        local _ = luv.fs_write(fd, body, 0, nil)
        assert(luv.fs_close(fd))
end


local function fm_read(path)
        local delim_fm_occur = 2
        local title_field = 'title'
        local date_field = 'date'
        local title = ''
        local lines = lines_from(path)
        for _,v in pairs(lines) do
                if delim_fm_occur <= 0 then break end
                if v == delim_fm then delim_fm_occur = delim_fm_occur - 1 end
                local tf, t = v:match("(%a+):%s*(.*)")
                if tf == title_field then title = t end
        end
        return title
end

local function unlinked_payload_to_md(nodes)
        local md = {}
        if #nodes < 1 then return md end
        local newline = ''
        local heading = '# Unlinked'
        table.insert(md, newline)
        table.insert(md, heading)
        table.insert(md, newline)
        for _, v in pairs(nodes) do
                local node_md =
                    '- ' .. '[' .. v.title .. ']' .. '(' .. v.file .. ')'
                table.insert(md, node_md)
        end
        return md
end

local function write_file(path, time_fm)
        -- TODO
        -- return success/err
        touch_file(path)
        fm_write(path, time_fm)
end

local function file_exists(path)
        -- TODO
        -- fix 438 mode
        local fd = luv.fs_open(path, "r", 438)
        if fd == nil then return false end
        return true
end

-- TODO
-- remove won't be used?
local function change_dir(path)
        api.nvim_set_current_dir(path)
        -- api.nvim_command('cd '..path)
end

local function new_buffer() return api.nvim_command('enew') end

local function open_file(fn) api.nvim_command('edit ' .. fn) end

local function append_to_current_buffer(content)
        local cur_buf = vim.api.nvim_get_current_buf()
        vim.api.nvim_buf_set_lines(cur_buf, -1, -1, false, content)
end

local function backend_status() rest_api.backend_status() end

local function index()
        local zp = get_zhuyi_path()
        change_dir(zp)
        open_file(zp .. index_file)
end

local function unlinked_rest()
        local nodes = {}
        rest_api.unlinked_nodes(nodes)
        local md = unlinked_payload_to_md(nodes)
        append_to_current_buffer(md)
end

local function new_zhuyi()
        local zp = get_zhuyi_path()
        local time_file, time_fm = get_time()
        local new_note_path = zp .. time_file .. ext

        local function write_and_open(path, time_fm)
                write_file(new_note_path, time_fm)
                open_file(new_note_path)
        end
        local function available_fn(new_note_path, time_file)
                for i = 1, string.len(alphabet) do
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
        local ok, new_note_path = available_fn(new_note_path, time_file)
        if ok then
                write_and_open(new_note_path, time_fm)
                return true
        end
        return false
end

local function has_md_ext(uri)
        local l = string.len(uri)
        local ext = string.sub(uri, l - 2, l)
        if ext ~= ext_md then return false end
        return true
end

local function handle_link()
        local function handle_non_md_link()
                local uri = vim.fn.expand('<cWORD>')
                return uri
        end
        local function handle_md_link(uri)
                local l = string.len(uri)
                uri = string.sub(uri, 2, l - 1)
                return uri
        end
        local function open_non_local_link(uri)
                -- TODO
                -- this can be done more nicely async (libuv)
                -- that way we can ignore error msgs et. al.
                local xdg_open = 'xdg-open '
                local ig_output = ' 2> /dev/null'
                os.execute(xdg_open .. uri .. ig_output)
        end
        local function open_local_link(uri)
                -- add path to file
                local cur_file_path = vim.fn.expand('%:p:h')
                uri = cur_file_path .. '/' .. uri
                open_file(uri)
        end
        local function is_http_s(uri)
                -- TODO
                -- this won't work as it's not only https uri:s we want to open in other
                -- apps than neovim.
                local http_s = 'https?'
                local ext = string.sub(uri, 1, 4)
                local match = string.match(ext, http_s)
                if match ~= nil then return false end
                return true
        end
        local function uri_is_local(uri)
                -- TODO
                -- can use get_zhuyi_path
                -- TODO
                -- this won't work as we sometimes want to open local files in other apps
                -- than neovim without more logic.
                local zhuyi_path = vim.fn.expand('%:p:h')
                local local_path = zhuyi_path .. '/' .. uri
                if not file_exists(local_path) then return false end
                return true
        end
        local function cur_line_md()
                local title, uri = api.nvim_get_current_line():match(
                                       "(%b[])(%b())")
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
        open_local_link(uri)
end

local function follow_link() handle_link() end

local function del_cur_zhuyi()
        local y = 'y'
        -- TODO
        -- better way to get current file?
        -- any nvim api function?
        local cur_file_path = vim.fn.expand('%:p')
        local query = 'delete ' .. cur_file_path .. '? (y/n) '
        if vim.fn.input(query) ~= y then return end
        local ok, err = luv.fs_unlink(cur_file_path)
        if not ok then
                -- TODO
                -- err handling?
                print(err)
                return
        end
        local opts = {force = true}
        api.nvim_buf_delete(0, opts)
end

local function walk_graph(node, graph)
        local file = node["file"]
        if not has_md_ext(file) then return end
        node = graph[file]
        node["walked"] = true
        local lines = lines_from(file)
        for _, v in pairs(lines) do
                local _, link_file = v:match("(%b[])(%b())")
                if link_file ~= nil then
                        -- TODO
                        -- we don't care about other links than .md for now
                        local l = string.len(link_file)
                        link_file = string.sub(link_file, 2, l - 1)
                        if not has_md_ext(link_file) then
                                goto continue
                        end
                        local child_node = graph[link_file]
                        if not child_node["walked"] then
                                walk_graph(child_node, graph)
                        end
                end
                ::continue::
        end

end

local function init_graph()
        local graph = {}
        local function iter_files(uv_fs_t)
                local file = luv.fs_scandir_next(uv_fs_t)
                if file == nil then return end
                if has_md_ext(file) then
                        local node = {
                                title = fm_read(file),
                                file = file,
                                walked = false
                        }
                        graph[file] = node
                end
                iter_files(uv_fs_t)
        end

        local zp = get_zhuyi_path()
        local uv_fs_t = luv.fs_scandir(zp)
        iter_files(uv_fs_t)
        return graph
end

local function unlinked()
        local function graph_to_nodes(graph)
                -- transform graph from hash map with file name as key
                -- to simple array with nodes in
                local nodes = {}
                for _,v in pairs(graph) do
                        if not v["walked"] then table.insert(nodes, v) end
                end
                return nodes
        end
        local graph = init_graph()
        local start_node = {title = fm_read("index.md"), file = "index.md", walked = true}
        walk_graph(start_node, graph)
        local nodes = graph_to_nodes(graph)
        local md = unlinked_payload_to_md(nodes)
        append_to_current_buffer(md)
end

return {
        index         = index,
        new_zhuyi     = new_zhuyi,
        del_cur_zhuyi = del_cur_zhuyi,
        follow_link   = follow_link,
        unlinked      = unlinked,
        unlinked_rest = unlinked_rest,
}
