require("nvchad.configs.lspconfig").defaults()

local servers = { "pyright", "intelephense", "laravel_ls", "ts_ls", "tailwindcss", "vue_ls", "html", "cssls", "twiggy_language_server", "emmet_ls"}
vim.lsp.enable(servers)
