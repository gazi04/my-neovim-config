local lspconfig = require("lspconfig")
local util = require("lspconfig.util")

-- This function is standard for NvChad to map keys only when LSP attaches
local on_attach = function(client, bufnr)
  -- NvChad specific: if you have a custom on_attach in your main config, 
  -- you might need to call it here.
end

local capabilities = vim.lsp.protocol.make_client_capabilities()

-- Standard servers list
local servers = { "pyright", "ts_ls", "html", "cssls" }

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

-- 1. Svelte Setup
lspconfig.svelte.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = { "svelte" },
  root_dir = util.root_pattern("package.json", ".git"),
}

-- 2. Tailwind Setup
lspconfig.tailwindcss.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = { "html", "css", "svelte", "javascriptreact", "typescriptreact" },
  root_dir = util.root_pattern('tailwind.config.js', 'postcss.config.js', '.git'),
}

-- 3. Intelephense Setup (The most important one right now)
lspconfig.intelephense.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = { "intelephense", "--stdio" },
  filetypes = { "php" },
  -- This force-returns the current directory if it can't find a root, 
  -- just to ensure it STARTS no matter what.
  root_dir = function(fname)
    return util.root_pattern("bin/console", "composer.json", ".git")(fname) or vim.loop.cwd()
  end,
  settings = {
    intelephense = {
      files = { maxSize = 5000000 },
      environment = {
        includePaths = { "vendor/**", "../../vendor/**" }
      }
    }
  }
}
