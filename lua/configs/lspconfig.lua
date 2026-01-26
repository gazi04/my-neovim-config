-- 1. Load Defaults
require("nvchad.configs.lspconfig").defaults()

-- 2. Define Variables
local configs = require "lspconfig.configs"
local nvlsp = require "nvchad.configs.lspconfig"
local util = require "lspconfig.util" -- THIS WAS MISSING
local lspconfig = require "lspconfig"

-- 3. Standard Servers
local servers = { "pyright", "intelephense", "laravel_ls", "ts_ls", "tailwindcss", "vue_ls", "html", "cssls", "twiggy_language_server", "emmet_ls" }
vim.lsp.enable(servers)

-- Helper function to fix the "Unknown Scheme" by adding file:// prefix
local function fix_uri(uri)
  if uri and not string.match(uri, "^%w+://") then
    return "file://" .. uri
  end
  return uri
end

-- 1. Register the Shopware LSP
if not configs.shopware_lsp then
  configs.shopware_lsp = {
    default_config = {
      cmd = { "/home/gazi/go/bin/shopware-lsp" },
      filetypes = { "php", "twig", "xml", "yaml" },
      root_dir = util.root_pattern("bin/console", "composer.json", ".git"),
    },
  }
end

-- 2. Setup with "Unknown Scheme" middleware
lspconfig.shopware_lsp.setup {
  on_attach = nvlsp.on_attach,
  capabilities = nvlsp.capabilities,
  handlers = {
    -- Fixes "Go to Definition" and "References"
    ["textDocument/definition"] = function(err, result, ctx, config)
      if result then
        if vim.islist(result) then
          for _, res in ipairs(result) do res.uri = fix_uri(res.uri) end
        else
          result.uri = fix_uri(result.uri)
        end
      end
      vim.lsp.handlers["textDocument/definition"](err, result, ctx, config)
    end,
    -- Fixes "Unknown Scheme" error for Diagnostics/Errors
    ["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
      if result and result.uri then
        result.uri = fix_uri(result.uri)
      end
      vim.lsp.handlers["textDocument/publishDiagnostics"](err, result, ctx, config)
    end,
  },
}
