local lsp_util = require("lspconfig.util")

local servers = { "pyright", "ts_ls", "html", "cssls" }
vim.lsp.enable(servers)

vim.lsp.config['svelte'] = {
  cmd = { "svelteserver", "--stdio" },
  filetypes = { "svelte" },
  root_dir = function(fname)
    return lsp_util.root_pattern("package.json", ".git")(fname)
  end,
  -- This tells Svelte how to find your TypeScript files
  settings = {
    svelte = {
      plugin = {
        svelte = { enabled = true },
        typescript = { enabled = true },
        css = { enabled = true },
      }
    }
  }
}
vim.lsp.enable("svelte")

vim.lsp.config['tailwindcss'] = {
  cmd = { "tailwindcss-language-server", "--stdio" },
  -- Explicitly include svelte, but we'll use a hack to ensure it doesn't block
  filetypes = { "html", "css", "svelte", "javascriptreact", "typescriptreact" },
  root_dir = lsp_util.root_pattern('tailwind.config.js', 'tailwind.config.ts', 'postcss.config.js'),
  settings = {
    tailwindCSS = {
      includeLanguages = {
        svelte = "html", -- Treat the markup part of svelte as html for tailwind
      },
    },
  },
}
vim.lsp.enable("tailwindcss")

vim.lsp.config['intelephense'] = {
  cmd = { "intelephense", "--stdio" },
  filetypes = { "php" },
  root_dir = function(fname)
    -- Look for Shopware markers first, fallback to composer.json
    local root = lsp_util.root_pattern("bin/console", "composer.lock", ".git")(fname)
               or lsp_util.root_pattern("composer.json")(fname)
    return root
  end,
  settings = {
    intelephense = {
      files = { maxSize = 5000000 },
      environment = {
        includePaths = {
          "vendor/**", 
          "../../vendor/**" 
        }
      }
    }
  }
}

vim.lsp.enable("intelephense")
