local lspconfig = require("lspconfig")
local util = require("lspconfig.util")
local nvlsp = require("nvchad.configs.lspconfig")

-- 1. Load Defaults
nvlsp.defaults()

-- 2. Define the list of servers
local servers = { "pyright", "ts_ls", "tailwindcss", "html", "cssls", "twiggy_language_server", "emmet_ls" }

-- 3. Enable standard servers
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }
end

-- 4. Configure Intelephense specifically to fix the "Undefined type" errors
lspconfig.intelephense.setup {
  on_attach = nvlsp.on_attach,
  capabilities = nvlsp.capabilities,
  -- FORCE the root to be the main shopware folder, not the plugin folder
  root_dir = function(fname)
    return util.root_pattern("bin/console", "composer.lock", ".git")(fname) 
           or util.root_pattern("composer.json")(fname)
  end,
  settings = {
    intelephense = {
      files = {
        maxSize = 5000000; -- Increase file size limit if needed
      },
      environment = {
        includePaths = {
          -- Explicitly tell it where the vendor folder is relative to your plugin
          -- This helps if it still gets confused
          "vendor/**", 
          "../../vendor/**" 
        }
      }
    }
  }
}
