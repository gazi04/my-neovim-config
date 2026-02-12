local lsp_util = require("lspconfig.util")
local configs = require("lspconfig.configs")

-- 1. Setup Standard Servers
vim.lsp.enable({ "pyright", "ts_ls", "html", "cssls" })

-- 2. Intelephense (Fixed for 0.11)
if not configs.intelephense then
  configs.intelephense = {
    default_config = {
      cmd = { "intelephense", "--stdio" },
      filetypes = { "php" },
      root_dir = function(fname)
        return lsp_util.root_pattern("bin/console", "composer.json", ".git")(fname) 
               or vim.uv.cwd()
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
  }
end
vim.lsp.enable("intelephense")

-- 3. Svelte (Fixed for 0.11)
if not configs.svelte then
  configs.svelte = {
    default_config = {
      cmd = { "svelteserver", "--stdio" },
      filetypes = { "svelte" },
      root_dir = lsp_util.root_pattern("package.json", ".git"),
      settings = {
        svelte = {
          plugin = {
            typescript = { enabled = true },
            css = { enabled = true },
          }
        }
      }
    }
  }
end
vim.lsp.enable("svelte")

-- 4. Tailwind (Fixed for 0.11)
if not configs.tailwindcss then
  configs.tailwindcss = {
    default_config = {
      cmd = { "tailwindcss-language-server", "--stdio" },
      filetypes = { "html", "css", "svelte", "javascriptreact", "typescriptreact" },
      root_dir = lsp_util.root_pattern('tailwind.config.js', 'postcss.config.js'),
      settings = {
        tailwindCSS = {
          includeLanguages = { svelte = "html" },
        },
      }
    }
  }
end
vim.lsp.enable("tailwindcss")
