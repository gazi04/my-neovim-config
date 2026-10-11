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

-- 5. Arduino (.ino sketches)
-- arduino-language-server wraps clangd and uses arduino-cli to build the
-- sketch's compile flags, so it needs to know the board (FQBN). It reads
-- default_fqbn from the sketch's sketch.yaml; set it per sketch with
--   arduino-cli board attach -b <fqbn> .
local ARDUINO_DEFAULT_FQBN = "esp8266:esp8266:nodemcuv2"

local function sketch_fqbn(root)
  local f = io.open(root .. "/sketch.yaml", "r")
  if f then
    local content = f:read("*a")
    f:close()
    local fqbn = content:match("default_fqbn:%s*([%w_%-%.:=,]+)")
    if fqbn then
      return fqbn
    end
  end
  return ARDUINO_DEFAULT_FQBN
end

-- The server panics ("unimplemented request: workspace/semanticTokens/refresh")
-- when the client advertises semantic tokens, so drop them from NvChad's set.
-- It also can't parse clangd's InsertReplaceEdit completions ("json: undefined
-- required field range into lsp.TextEdit"), so ask for plain TextEdits.
local arduino_capabilities = vim.tbl_deep_extend("force", capabilities, {
  textDocument = {
    semanticTokens = vim.NIL,
    completion = { completionItem = { insertReplaceSupport = false } },
  },
  workspace = { semanticTokens = vim.NIL },
})

vim.lsp.config('arduino_language_server', {
  on_attach = on_attach,
  on_init = on_init,
  capabilities = arduino_capabilities,
  cmd = function(dispatchers, config)
    local root = config.root_dir or vim.fn.getcwd()
    return vim.lsp.rpc.start({
      mason_bin .. "arduino-language-server",
      "-cli", vim.fn.exepath("arduino-cli"),
      "-cli-config", vim.fn.expand("~/.arduino15/arduino-cli.yaml"),
      "-clangd", vim.fn.exepath("clangd"),
      "-fqbn", sketch_fqbn(root),
    }, dispatchers, { cwd = root })
  end,
})
vim.lsp.enable('arduino_language_server')
