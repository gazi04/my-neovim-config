require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("n", "<leader>z", "za", { desc = "Toggle fold" })

-- Ctrl + h/j/k/l: move between Neovim splits and tmux panes (vim-tmux-navigator).
-- Replaces NvChad's plain split switching on the same keys.
map("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Navigate left (split/tmux pane)" })
map("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", { desc = "Navigate down (split/tmux pane)" })
map("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", { desc = "Navigate up (split/tmux pane)" })
map("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", { desc = "Navigate right (split/tmux pane)" })

-- Alt + arrows: the same, and also from insert mode and the built-in terminal
map({ "n", "i", "t" }, "<M-Left>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Navigate left (split/tmux pane)" })
map({ "n", "i", "t" }, "<M-Down>", "<cmd>TmuxNavigateDown<cr>", { desc = "Navigate down (split/tmux pane)" })
map({ "n", "i", "t" }, "<M-Up>", "<cmd>TmuxNavigateUp<cr>", { desc = "Navigate up (split/tmux pane)" })
map({ "n", "i", "t" }, "<M-Right>", "<cmd>TmuxNavigateRight<cr>", { desc = "Navigate right (split/tmux pane)" })

-- Scroll up half a screen and then center the cursor
vim.api.nvim_set_keymap('n', '<C-u>', '<C-u>zz', { noremap = true, silent = true, desc = 'Scroll Up Half Page and Center' })

-- Scroll down half a screen and then center the cursor
vim.api.nvim_set_keymap('n', '<C-d>', '<C-d>zz', { noremap = true, silent = true, desc = 'Scroll Down Half Page and Center' })
-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- Custom function to handle grt (Type Definition) with a fallback
local function smart_type_definition()
  local clients = vim.lsp.get_active_clients({ bufnr = 0 })
  local supports_type_def = false

  for _, client in ipairs(clients) do
    if client.supports_method("textDocument/typeDefinition") then
      supports_type_def = true
      break
    end
  end

  if supports_type_def then
    vim.lsp.buf.type_definition()
  else
    -- Fallback for PHP/Intelephense which only supports standard definition
    vim.lsp.buf.definition()
  end
end

-- Override the default grt
-- map("n", "grt", smart_type_definition, { desc = "Smart Type/Base Definition" })

