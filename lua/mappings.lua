require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("n", "<leader>fw", "<cmd>Telescope find_files find_command=rg,--ignore,--hidden,--files,-g,!var/**,-g,!.git/**<CR>", { desc = "Find Shopware Files (No Cache)" })

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

