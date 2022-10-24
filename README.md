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

require("cmp_dynamic").setup({
    -- items
})
```

# Define completion items

Here is an example of defining completion items.

```lua
local Date = require("cmp_dynamic.utils.date")

require("cmp_dynamic").setup({
    {
        label = "today",
        insertText = 1,
        cb = {
            function()
                return os.date("%Y/%m/%d")
            end,
        },
    },
    {
        label = "next Monday",
        insertText = 1,
        cb = {
            function()
                return Date.new():add_date(7):day(1):format("%Y/%m/%d")
            end,
        },
        resolve = true, -- default: false
    },
})
```

Basically, items conforms to LSP's completionItem, but `cb` and `resolve` are special keys.

`cb` is a list of functions, which is evaluated at the time the complete is called;
if `resolve` is false, `cb` is evaluated on the completion.

- resolve = true

![image](https://user-images.githubusercontent.com/82267684/197586670-7b3c4794-54c1-4f2d-864a-1abfab1d4d3c.png)

Press \<CR>

![image](https://user-images.githubusercontent.com/82267684/197586711-d6d889af-66d7-43c9-b397-7b4f5d2b6e9c.png)

- resolve = false

![image](https://user-images.githubusercontent.com/82267684/197586575-18a94501-5462-4a2b-b7eb-d70391f9e0d3.png)

You can use the result of `cb` evaluation by making value the key of the `cb`, as in `insertText = 1`.
