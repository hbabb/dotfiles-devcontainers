return {
  "hrsh7th/nvim-cmp",
  ---@param opts cmp.ConfigSchema
  opts = function(_, opts)
    local cmp = require("cmp")

    -- Merge custom mappings with defaults
    opts.mapping = vim.tbl_deep_extend("force", opts.mapping, {
      -- <CR> always inserts a new line (fallback to default behavior)
      ["<CR>"] = cmp.mapping({
        i = function(fallback)
          if cmp.visible() then
            fallback() -- Inserts newline and closes menu
          else
            fallback()
          end
        end,
        s = function(fallback)
          fallback()
        end,
      }),

      -- <Tab> confirms the highlighted completion (no auto-select)
      ["<Tab>"] = cmp.mapping.confirm({ select = false }),
    })

    -- Disable preselection to avoid automatic highlighting
    opts.preselect = cmp.PreselectMode.None

    -- Completion options: Show menu without auto-insertion or selection
    opts.completion = {
      completeopt = "menu,menuone,noinsert,noselect",
    }

    return opts
  end,
}
