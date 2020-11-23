local daedalus = require('daedalus')
local specs = require('daedalus.specs')
local helpers = require('daedalus.helpers')

local spec = specs.define {
        ['*'] = {url = 'http://' .. vim.g.zhuyi_backend, method = 'get'},
        status = {path = '/status'},
        unlinked_nodes = {path = '/unlinked'}
}

local client = daedalus.make_client(spec)

local function unlinked_nodes_handler(ret, nodes)
        -- TODO
        -- error handling
        for _, v in pairs(ret.payload.unlinked_zettels) do
                table.insert(nodes, v)
        end
end

local function unlinked_nodes(nodes)
        client.unlinked_nodes {
                before = function(cmd)
                        -- if you need to extend the curl command or debug it before calling,
                        -- override this function
                        return cmd
                end,
                handler = function(ret)
                        unlinked_nodes_handler(ret, nodes)
                end,
                decode = function(str)
                        -- if you need to parse values other than json, override this function
                        return vim.fn.json_decode(str)
                end
        }
end

local function backend_status()
        client.status {
                before = function(cmd)
                        -- if you need to extend the curl command or debug it before calling,
                        -- override this function
                        return cmd
                end,
                handler = function(ret)
                        -- the handler function receives already parsed objects
                end,
                decode = function(str)
                        -- if you need to parse values other than json, override this function
                        return vim.fn.json_decode(str)
                end
        }
end

return {backend_status = backend_status, unlinked_nodes = unlinked_nodes}
