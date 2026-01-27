local lsp_util = require("lspconfig.util")

local servers = {
  "pyright",
  "ts_ls",
  "intelephense",
  "tailwindcss",
  "html",
  "cssls",
  "emmet_ls"
}
vim.lsp.enable(servers)

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
