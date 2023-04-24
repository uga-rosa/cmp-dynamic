---@class cmp.dynamic.CompletionItem: lsp.CompletionItem
---@field public resolve? boolean
---@field public label string|function
---@field public labelDetails? lsp.CompletionItemLabelDetails|function
---@field public kind? lsp.CompletionItemKind|function
---@field public tags? lsp.CompletionItemTag[]|function
---@field public detail? string|function
---@field public documentation? lsp.MarkupContent|string|function
---@field public deprecated? boolean|function
---@field public preselect? boolean|function
---@field public sortText? string|function
---@field public filterText? string|function
---@field public insertText? string|function
---@field public insertTextFormat? lsp.InsertTextFormat|function
---@field public insertTextMode? lsp.InsertTextMode|function
---@field public textEdit? lsp.TextEdit|lsp.InsertReplaceTextEdit|function
---@field public textEditText? string|function
---@field public additionalTextEdits? lsp.TextEdit[]|function
---@field public commitCharacters? string[]|function
---@field public command? lsp.Command|function
---@field public data? any|function

local source = {}

function source.new()
  return setmetatable({}, { __index = source })
end

---@return string
function source.get_debug_name()
  return "dynamic"
end

---@param _ cmp.SourceCompletionApiParams
---@param callback fun(response: lsp.CompletionResponse)
function source:complete(_, callback)
  local completionItems = vim.tbl_map(function(item)
    local new_item = { data = {} }
    for k, v in pairs(item) do
      if k == "label" or not item.resolve then
        -- Required field or evaluate at the first
        new_item[k] = type(v) == "function" and v() or v
      elseif type(v) == "function" then
        -- Store a function
        new_item.data[k] = v
      else
        new_item[k] = v
      end
    end
    return new_item
  end, self._items)
  callback(completionItems)
end

---@param completion_item cmp.dynamic.CompletionItem
---@param callback fun(completion_item: lsp.CompletionItem|nil)
function source.resolve(_, completion_item, callback)
  if completion_item.resolve then
    for k, v in pairs(completion_item.data) do
      completion_item[k] = v()
    end
  end
  callback(completion_item)
end

---@param items cmp.dynamic.CompletionItem[]
function source.register(items)
  source._items = items
end

return source
