local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/"

-- NvChad standard integration
-- defaults() sets diagnostics, LSP highlights, the LspAttach mappings,
-- capabilities/on_init for every server ("*"), and enables lua_ls
local nvlsp = require("nvchad.configs.lspconfig")
nvlsp.defaults()

local on_attach = nvlsp.on_attach
local on_init = nvlsp.on_init
local capabilities = nvlsp.capabilities

-- 1. Standard Servers
local servers = { "pyright", "clangd", "ts_ls", "html", "cssls" }
for _, lsp in ipairs(servers) do
  vim.lsp.config(lsp, {
    on_attach = on_attach,
    on_init = on_init,
    capabilities = capabilities,
  })
  vim.lsp.enable(lsp)
end

-- 2. Svelte Native Setup
-- vim.lsp.config uses root_markers; lspconfig.util.root_pattern() is the old
-- root_dir signature and keeps the server from ever starting
vim.lsp.config('svelte', {
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
  filetypes = { "svelte" },
  root_markers = { "svelte.config.js", "package.json", ".git" },
})
vim.lsp.enable('svelte')

-- 3. Tailwind Native Setup
vim.lsp.config('tailwindcss', {
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
  filetypes = { "html", "css", "svelte", "javascriptreact", "typescriptreact" },
  root_markers = { 'tailwind.config.js', 'postcss.config.js', '.git' },
})
vim.lsp.enable('tailwindcss')

-- 4. Intelephense (Laravel Optimized)
vim.lsp.config('intelephense', {
  -- Use the absolute path so the native API can find it
  cmd = { mason_bin .. "intelephense", "--stdio" },
  filetypes = { "php" },
  -- REQUIRED: These link the LSP to NvChad's keybindings and completion engine
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
  root_markers = { 'artisan', 'composer.json', '.git' },
  settings = {
    intelephense = {
      files = { maxSize = 5000000 },
      environment = { includePaths = { "vendor/" } }
    }
  }
})
vim.lsp.enable('intelephense')
