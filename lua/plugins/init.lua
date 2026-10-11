return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre", -- format on save (configs/conform.lua)
    cmd = { "ConformInfo" },
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    lazy=false,
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "mason-org/mason.nvim",
    -- mason.nvim itself ignores this list: :MasonInstallAll (autocmds.lua)
    -- installs whatever is missing. Use Mason package names, not lspconfig ones.
    opts = {
      ensure_installed = {
        "intelephense", "laravel-ls", "blade-formatter",
        "html-lsp", "css-lsp", "prettierd",
        "tailwindcss-language-server",
        "typescript-language-server",
        "svelte-language-server",
        "vue-language-server",
        "pyright", "ruff",
        "lua-language-server", "stylua",
        "arduino-language-server",
      }
    }
  },

  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    -- On the main branch, we pass our settings to 'opts'
    opts = {
      ensure_installed = {
        "lua", "vim", "vimdoc", "typescript", "svelte",
        "python", "c", "cpp", "arduino", "php", "phpdoc", "html", "blade",
        "vue", "javascript", "css", "scss", "json", "yaml", "xml"
      },
      highlight = {
        enable = true,
        use_languagetree = true,
      },
      indent = {
        enable = true,
      }
    },
    -- Lazy.nvim will automatically handle the setup under the hood 
    -- using your 'opts' table above, without looking for the deleted configs module!
  },

  { import = "nvchad.blink.lazyspec" },

  -- Ctrl + h/j/k/l moves between Neovim splits and tmux panes
  -- (keys are mapped in mappings.lua; tmux side lives in ~/.tmux.conf)
  {
    "christoomey/vim-tmux-navigator",
    cmd = { "TmuxNavigateLeft", "TmuxNavigateDown", "TmuxNavigateUp", "TmuxNavigateRight" },
    init = function()
      vim.g.tmux_navigator_no_mappings = 1
    end,
  },

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
}
