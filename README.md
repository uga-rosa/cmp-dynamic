# cmp-dynamic

Source of [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) to dynamically generate candidates using Lua functions.

# Usage

```lua
require("cmp").setup({
  -- other settings
  sources = {
    { name = "dynamic" },
  },
})

require("cmp_dynamic").register({
  -- items
})
```

# Define completion items

Here is an example of defining completion items.

```lua
local Date = require("cmp_dynamic.utils.date")

require("cmp_dynamic").register({
  {
    label = "today",
    insertText = function()
      return os.date("%Y/%m/%d")
    end,
  },
  {
    label = "next Monday",
    insertText = function()
      return Date.new():add_date(7):day(1):format("%Y/%m/%d")
    end,
    resolve = true, -- default: false
  },
})
```

Basically, items conforms to [LSP's CompletionItem](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#completionItem).
There is a special key `resolve`, and functions can be specified for any values.

By default, `resolve` is false.
Setting it to true delays to evaluate the functions until it is complete.
However, since `label` is a required field, it is evaluated first regardless of the value of `resolve`.

- resolve = true

![image](https://user-images.githubusercontent.com/82267684/197586670-7b3c4794-54c1-4f2d-864a-1abfab1d4d3c.png)

Press \<CR>

![image](https://user-images.githubusercontent.com/82267684/197586711-d6d889af-66d7-43c9-b397-7b4f5d2b6e9c.png)

- resolve = false

![image](https://user-images.githubusercontent.com/82267684/197586575-18a94501-5462-4a2b-b7eb-d70391f9e0d3.png)
