return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      -- require("nvchad.configs.lspconfig").defaults()
      require "configs.lspconfig"
    end,
  },

  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "intelephense", "laravel-ls",
        "html", "html-lsp", "blade-formatter",
        "twiggy-language-server",
        "cssls", "css-lsp", "emmet-ls",
        "tailwindcss-language-server",
        "ts_ls",
        "typescript-language-server",
        "vue_ls",
        "pyright",
        "lua-language-server",
      }
    }
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "lua",
        "vim", "vimdoc",
        "typescript", "svelte",
        "python",
        "php", "phpdoc",
        "twig", "html", "blade",
        "vue", "javascript",
        "css", "scss",
        "json", "yaml", "xml"
      },
      indent = {
        enable = true
      },
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false
      },
      context_commentstring = {
        enable = true,
        enable_autocmd = false,
      },
    },
  },
  -- test new blink
  { import = "nvchad.blink.lazyspec" },

  {
    "nvim-tree/nvim-tree.lua",
    opts = {
      filters = {
        dotfiles = false, -- Set to false to show dotfiles (e.g., .env, .gitignore)
        -- You might want to keep the git-ignored files hidden, but dotfiles shown:
        -- custom = { ".git", "node_modules", "vendor" }, 
      },
      view = {
        signcolumn = "yes",
      },
      git = {
        ignore = false,
      }
    },
    config = function(_, opts)
      require("nvim-tree").setup(opts)
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufReadPost",
    opts = {
      enable = true,            -- Enable this plugin (Can be enabled/disabled later via commands)
      max_lines = 3,            -- How many lines the window should span. Values <= 0 mean no limit.
      min_window_height = 0,    -- Minimum editor window height to enable context. Values <= 0 mean no limit.
      line_numbers = true,
      multiline_threshold = 20, -- Maximum number of lines to show for a single context
      trim_scope = 'outer',     -- Which context lines to discard if `max_lines` is exceeded
      mode = 'cursor',          -- Line used to calculate context. Can be 'cursor' or 'topline'
    },
  },

  {
    "thomas-hiron/cmp-symfony",
  }
}
