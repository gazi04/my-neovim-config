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
        "rust-analyzer",
        "debugpy", "codelldb", "php-debug-adapter", -- debug adapters (configs/dap.lua)
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
        "vue", "javascript", "css", "scss", "json", "yaml", "xml",
        "rust", "toml"
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

  -- Debugging: nvim-dap + UI for Python (debugpy), PHP (Xdebug), C/C++ (codelldb)
  -- Adapters and configurations live in configs/dap.lua
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
      "theHamsta/nvim-dap-virtual-text",
      "mfussenegger/nvim-dap-python",
    },
    config = function()
      require "configs.dap"
    end,
    keys = {
      { "<F5>", function() require("dap").continue() end, desc = "Debug start/continue" },
      { "<F9>", function() require("dap").toggle_breakpoint() end, desc = "Debug toggle breakpoint" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Debug start/continue" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Debug toggle breakpoint" },
      {
        "<leader>dB",
        function() require("dap").set_breakpoint(vim.fn.input "Condition: ") end,
        desc = "Debug conditional breakpoint",
      },
      { "<leader>do", function() require("dap").step_over() end, desc = "Debug step over" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Debug step into" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "Debug step out" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Debug run last" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Debug terminate" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Debug toggle UI" },
      { "<leader>de", function() require("dapui").eval() end, mode = { "n", "v" }, desc = "Debug evaluate" },
      { "<leader>dpt", function() require("dap-python").test_method() end, ft = "python", desc = "Debug test method" },
      { "<leader>dpc", function() require("dap-python").test_class() end, ft = "python", desc = "Debug test class" },
      {
        "<leader>drt",
        function()
          local dap = require "dap"
          for _, c in ipairs(dap.configurations.rust) do
            if c.name == "Cargo: debug test under cursor" then
              return dap.run(c)
            end
          end
        end,
        ft = "rust",
        desc = "Debug Rust test under cursor",
      },
    },
  },

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
