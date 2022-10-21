---@class cmp.dynamic.CompletionItem: lsp.CompletionItem
---@field public cb function[]
---@field public cache boolean
---@field private _cached boolean

local source = {}
source.__index = source
source._items = {}

function source.new()
    return setmetatable({}, source)
end

---@param v function|any
---@return any
local function resolve_fn(v)
    if type(v) == "function" then
        return v()
    else
        return v
    end
end

---@param _ cmp.SourceCompletionApiParams
---@param callback fun(response: lsp.CompletionResponse)
function source:complete(_, callback)
    ---@type lsp.CompletionItem[]
    local completionItems = {}

    for _, item in ipairs(self._items) do
        local completionItem = {}

        local cb = item.cb
        if not item._cached then
            cb = vim.tbl_map(resolve_fn, item.cb)
            if item.cache then
                item.cb = cb
                item._cached = true
            end
        end

        for k, v in pairs(item) do
            if k ~= "cb" then
                if cb[v] then
                    v = cb[v]
                end
                completionItem[k] = v
            end
        end

        table.insert(completionItems, completionItem)
    end

    callback(completionItems)
end

---@param value any
---@param t string type
---@param accept_nil (boolean|nil)
---@return unknown[]
local function assert_unknown_or_unknown_list(value, t, accept_nil)
    if accept_nil and value == nil then
        return {}
    end

    local err_msg = ("validate error: It must be (%s|%s[]%s)"):format(
        t,
        t,
        accept_nil and "|nil" or ""
    )

    if type(value) == t then
        return { t }
    elseif vim.tbl_islist(value) then
        vim.tbl_map(function(v)
            assert(type(v) == t, err_msg)
        end, value)
        return value
    else
        error(err_msg)
    end
end

---@param items cmp.dynamic.CompletionItem[]
function source.setup(items)
    vim.validate({ items = { items, "t" } })
    for _, item in ipairs(items) do
        vim.validate({
            item = { item, "t" },
            ["item.cache"] = { item.cache, "b", true },
        })

        item.cb = assert_unknown_or_unknown_list(item.cb, "function", true)
    end
    source._items = items
end

return source
