return {
  "obsidian-nvim/obsidian.nvim",
  version = "*", -- recommended, use latest release instead of latest commit
  ft = "markdown",
  -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
  -- event = {
  --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
  --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
  --   -- refer to `:h file-pattern` for more examples
  --   "BufReadPre path/to/my-vault/*.md",
  --   "BufNewFile path/to/my-vault/*.md",
  -- },
  ---@module 'obsidian'
  -- -@type obsidian.config.Internal
  opts = {
    workspaces = {
      {
        name = "personal",
        path = "~/vaults/LCARS",
      },
    },

    note_id_function = require("obsidian.builtin").zettel_id,
    wiki_link_function = require("obsidian.builtin").wiki_link_id_prefix,
    markdown_link_function = require("obsidian.builtin").markdown_link,
    preferred_link_style = "wiki",
    open_notes_in = "current",

    frontmatter = {
      enabled = true,
      func = require("obsidian.builtin").frontmatter,
      sort = { "id", "aliases", "tags" },
    },

    templates = {
      folder = "~/vaults/LCARS/templates",
    },

    backlinks = {
      parse_headers = true,
    },

    completion = (function()
      local has_nvim_cmp, _ = pcall(require, "cmp")
      local has_blink = pcall(require, "blink.cmp")
      return {
        nvim_cmp = has_nvim_cmp and not has_blink,
        blink = has_blink,
        min_chars = 2,
        match_case = true,
        create_new = true,
      }
    end)(),

    daily_notes = {
      folder = "~/vaults/LCARS/Daily",
      default_tags = { "daily-notes" },
    },

    ui = {
      enable = true,
      ignore_conceal_warn = false,
      update_debounce = 200,
      max_file_length = 5000,
      checkboxes = {
        [" "] = { char = "󰄱", hl_group = "obsidiantodo" },
        ["~"] = { char = "󰰱", hl_group = "obsidiantilde" },
        ["!"] = { char = "", hl_group = "obsidianimportant" },
        [">"] = { char = "", hl_group = "obsidianrightarrow" },
        ["x"] = { char = "", hl_group = "obsidiandone" },
      },
      bullets = { char = "•", hl_group = "ObsidianBullet" },
      external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
      reference_text = { hl_group = "ObsidianRefText" },
      highlight_text = { hl_group = "ObsidianHighlightText" },
      tags = { hl_group = "ObsidianTag" },
      block_ids = { hl_group = "ObsidianBlockID" },
      hl_groups = {
        ObsidianTodo = { bold = true, fg = "#f78c6c" },
        ObsidianDone = { bold = true, fg = "#89ddff" },
        ObsidianRightArrow = { bold = true, fg = "#f78c6c" },
        ObsidianTilde = { bold = true, fg = "#ff5370" },
        ObsidianImportant = { bold = true, fg = "#d73128" },
        ObsidianBullet = { bold = true, fg = "#89ddff" },
        ObsidianRefText = { underline = true, fg = "#c792ea" },
        ObsidianExtLinkIcon = { fg = "#c792ea" },
        ObsidianTag = { italic = true, fg = "#89ddff" },
        ObsidianBlockID = { italic = true, fg = "#89ddff" },
        ObsidianHighlightText = { bg = "#75662e" },
      },
    },

    attachments = {
      img_folder = "assets/imgs",
      img_text_func = require("obsidian.builtin").img_text_func,
      img_name_func = function()
        return string.format("Pasted image %s", os.date("%Y%m%d%H%M%S"))
      end,
      confirm_img_paste = true,
    },

    checkbox = {
      enabled = true,
      create_new = true,
      order = { " ", "~", "!", ">", "x" },
    },
  },
}
