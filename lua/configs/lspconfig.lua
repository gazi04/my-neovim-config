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
local servers = { "clangd", "html", "cssls" }
for _, lsp in ipairs(servers) do
  vim.lsp.config(lsp, {
    on_attach = on_attach,
    on_init = on_init,
    capabilities = capabilities,
  })
  vim.lsp.enable(lsp)
end

-- TypeScript + Vue
-- vue_ls only handles the template/style parts; it forwards the TypeScript
-- work to ts_ls, which needs the @vue/typescript-plugin and the vue filetype.
local vue_plugin = {
  name = "@vue/typescript-plugin",
  location = vim.fn.stdpath("data") .. "/mason/packages/vue-language-server/node_modules/@vue/language-server",
  languages = { "vue" },
  configNamespace = "typescript",
}
vim.lsp.config('ts_ls', {
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
  init_options = { plugins = { vue_plugin } },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
})
vim.lsp.enable('ts_ls')

-- No on_init here: vue_ls's own on_init wires the request forwarding to ts_ls
vim.lsp.config('vue_ls', {
  on_attach = on_attach,
  capabilities = capabilities,
})
vim.lsp.enable('vue_ls')

-- Laravel: routes, views, config, env and translation keys (starts only in
-- projects with an `artisan` file, alongside intelephense)
vim.lsp.config('laravel_ls', {
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
  -- Without a project root it fails to start ("unknown scheme") on every
  -- PHP/Blade file outside Laravel
  workspace_required = true,
})
vim.lsp.enable('laravel_ls')

-- Python: pyrefly for types/completion, ruff for linting, quick fixes and
-- import sorting (formatting runs through conform). Pyright config kept below,
-- disabled; swap the vim.lsp.enable calls to go back.
local function venv_python(root)
  for _, dir in ipairs({ ".venv", "venv", "env" }) do
    local python = root .. "/" .. dir .. "/bin/python"
    if vim.uv.fs_stat(python) then
      return python
    end
  end
end

vim.lsp.config('pyright', {
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
  settings = {
    pyright = {
      disableOrganizeImports = true, -- ruff does it
      disableTaggedHints = true, -- "x is not accessed": ruff reports unused code
    },
  },
  -- Use the project's virtualenv so its packages resolve
  before_init = function(_, config)
    local python = venv_python(config.root_dir or vim.fn.getcwd())
    if python then
      config.settings.python = vim.tbl_deep_extend("force", config.settings.python or {}, { pythonPath = python })
    end
  end,
})
-- vim.lsp.enable('pyright')

vim.lsp.config('pyrefly', {
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
  on_exit = function() end, -- silence lspconfig's "exited with code" notify on every quit
  settings = {
    python = {
      pyrefly = { displayTypeErrors = "force-on" }, -- type errors even without a pyrefly.toml
    },
  },
  -- Same virtualenv lookup as pyright (pyrefly reads python.pythonPath)
  before_init = function(_, config)
    local python = venv_python(config.root_dir or vim.fn.getcwd())
    if python then
      config.settings.python = vim.tbl_deep_extend("force", config.settings.python or {}, { pythonPath = python })
    end
  end,
})
vim.lsp.enable('pyrefly')

vim.lsp.config('ruff', {
  on_attach = function(client, bufnr)
    client.server_capabilities.hoverProvider = false -- pyrefly's hover is richer
    on_attach(client, bufnr)
  end,
  on_init = on_init,
  capabilities = capabilities,
})
vim.lsp.enable('ruff')

-- Rust: rust-analyzer (Mason). Std library completion / go-to-definition
-- needs the std sources: `pacman -S rust-src`.
vim.lsp.config('rust_analyzer', {
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
  settings = {
    ["rust-analyzer"] = {
      check = { command = "clippy" }, -- clippy lints on save instead of plain `cargo check`
      cargo = { allFeatures = true },
      procMacro = { enable = true },
    },
  },
})
vim.lsp.enable('rust_analyzer')

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
  -- Its sketch mapper panics ("error replacing text: Line access out of range")
  -- when one didChange carries several ranged edits, e.g. after clang-format
  -- rewrites the buffer on save. Full-text sync isn't implemented either, so
  -- don't batch: send each edit in its own notification.
  flags = { debounce_text_changes = 0 },
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
