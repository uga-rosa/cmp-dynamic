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

Here is an example of adding today's date.

```lua
require("cmp_dynamic").setup({
    {
        label = "today",
        insertText = 1,
        cb = {
            function()
                return os.date("%Y/%m/%d")
            end,
        },
        cache = true -- default: false
    },
})
```

Basically, items conforms to LSP's completionItem, but `cb` and `cache` are special keys.

`cb` is a list of functions, which is evaluated at the time the complete is called;
if `cache` is false, it is evaluated each time, but if `cache` is true, the first evaluation result is stored and used.

You can use the result of `cb` evaluation by making value the key of the `cb`, as in `insertText = 1` or `documentation = 1`.
