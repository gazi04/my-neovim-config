require "nvchad.options"

-- add yours here!

-- Python host for remote plugins (molten-nvim). Venv has pynvim, jupyter_client,
-- jupytext, ipykernel, cairosvg, plotly, kaleido, ... (~/.virtualenvs/neovim)
vim.g.python3_host_prog = vim.fn.expand "~/.virtualenvs/neovim/bin/python3"
vim.g.loaded_python3_provider = nil -- NvChad disables it; molten needs it

-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99 -- Start with all folds open
vim.opt.foldcolumn = "1" -- Shows a small column on the left to indicate folds

vim.filetype.add({
  extension = {
    twig = "twig",
  },
  pattern = {
    [".*%.html%.twig"] = "twig", -- Forces double extension to be recognized
  },
})

-- Force global indentation settings
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2

-- Fix for PHP specifically (prevents the runtime script from overriding you)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "php",
  callback = function()
    vim.opt_local.autoindent = true
    vim.opt_local.smartindent = true
  end,
})
