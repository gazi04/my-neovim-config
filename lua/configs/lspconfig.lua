local lsp_util = require("lspconfig.util")

-- NvChad standard integration
local on_attach = require("nvchad.configs.lspconfig").on_attach
local on_init = require("nvchad.configs.lspconfig").on_init
local capabilities = require("nvchad.configs.lspconfig").capabilities

-- 1. Standard Servers
local servers = { "pyright", "ts_ls", "html", "cssls" }
for _, lsp in ipairs(servers) do
  vim.lsp.config(lsp, {
    on_attach = on_attach,
    on_init = on_init,
    capabilities = capabilities,
  })
  vim.lsp.enable(lsp)
end

-- 2. Svelte Native Setup
vim.lsp.config('svelte', {
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = { "svelte" },
  root_dir = lsp_util.root_pattern("svelte.config.js", "package.json", ".git"),
})
vim.lsp.enable('svelte')

-- 3. Tailwind Native Setup
vim.lsp.config('tailwindcss', {
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = { "html", "css", "svelte", "javascriptreact", "typescriptreact" },
  root_dir = lsp_util.root_pattern('tailwind.config.js', 'postcss.config.js', '.git'),
})
vim.lsp.enable('tailwindcss')

-- 4. Intelephense (Laravel Optimized)
vim.lsp.config('intelephense', {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = { "intelephense", "--stdio" },
  filetypes = { "php" },
  root_dir = function(fname)
    -- Prioritize Laravel's 'artisan' file for root detection
    return lsp_util.root_pattern("artisan", "composer.json", ".git")(fname) 
           or vim.uv.cwd()
  end,
  settings = {
    intelephense = {
      files = { 
        maxSize = 5000000,
        associations = { "*.php", "*.phtml", "*.blade.php" } 
      },
      environment = {
        -- Standard Laravel vendor path
        includePaths = { "vendor/" },
        phpVersion = "8.2" 
      },
      diagnostics = {
        enable = true,
      },
      completion = {
        fullyQualifyImportedNames = true
      }
    }
  }
})
vim.lsp.enable('intelephense')
