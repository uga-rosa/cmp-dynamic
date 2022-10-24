---@class cmp.dynamic.CompletionItem: lsp.CompletionItem
---@field public cb function[]
---@field public resolve boolean

local source = {}
source.__index = source
---@type lsp.CompletionItem[]
source._items = {}

function source.new()
    return setmetatable({}, source)
end

---@return string
function source:get_debug_name()
    return "dynamic"
end

---@param item cmp.dynamic.CompletionItem
---@param done boolean
---@return lsp.CompletionItem
local function resolve(item, done)
    local result = {}
    for k, v in pairs(item) do
        result[k] = v
    end

    if done then
        local resolved = vim.tbl_map(function(v)
            return v()
        end, item.data.cb)

        for k, v in pairs(item.data) do
            if type(v) == "number" then
                result[k] = resolved[v]
            end
        end
    end

    return result
end

---@param _ cmp.SourceCompletionApiParams
---@param callback fun(response: lsp.CompletionResponse)
function source:complete(_, callback)
    local completionItems = vim.tbl_map(function(item)
        return resolve(item, not item.data.resolve)
    end, self._items)
    callback(completionItems)
end

---@param item cmp.dynamic.CompletionItem
---@param callback fun(completion_item: lsp.CompletionItem|nil)
function source:resolve(item, callback)
    if item.data.resolve then
        callback(resolve(item, item.data.resolve))
    end
end

---@param items cmp.dynamic.CompletionItem[]
function source.setup(items)
    vim.validate({ items = { items, "t" } })
    for i, item in ipairs(items) do
        item.data = {}
        item.data.cb = vim.F.if_nil(item.cb, {})
        item.cb = nil
        item.data.resolve = vim.F.if_nil(item.resolve, false)
        item.resolve = nil
        for k, v in pairs(item) do
            if type(v) == "number" then
                item.data[k] = v
                item[k] = nil
            end
        end
        items[i] = item
    end
    source._items = items
end

return source
