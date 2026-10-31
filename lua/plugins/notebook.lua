-- Jupyter notebooks in Neovim
--   jupytext.nvim : opens *.ipynb as Python in "percent" format (# %% cell markers),
--                   writes back to .ipynb on save
--   molten-nvim   : runs code in a real Jupyter kernel, shows output inline
--   image.nvim    : renders plots/images inline (kitty graphics protocol)
--
-- Python deps live in ~/.virtualenvs/neovim, managed with uv
-- (see vim.g.python3_host_prog in options.lua). Add a package:
--   uv pip install --python ~/.virtualenvs/neovim/bin/python <pkg>
-- Use a uv project's .venv as kernel (auto-picked when the notebook lives in that project):
--   uv add --dev ipykernel && uv run python -m ipykernel install --user --name <project-dir-name>
-- After first install / molten update run :UpdateRemotePlugins and restart Neovim.

-- Return start/end line (1-based) of the "# %%" cell under the cursor
local function cell_range()
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local is_marker = function(l)
    return l:match "^# %%" ~= nil
  end

  local start = 1
  for i = cur, 1, -1 do
    if is_marker(lines[i]) then
      start = i + 1
      break
    end
  end
  local stop = #lines
  for i = cur + 1, #lines do
    if is_marker(lines[i]) then
      stop = i - 1
      break
    end
  end
  return start, stop
end

local function run_cell()
  local s, e = cell_range()
  if s <= e then
    vim.fn.MoltenEvaluateRange(s, e)
  end
  return e
end

local function run_cell_and_next()
  local e = run_cell()
  local last = vim.api.nvim_buf_line_count(0)
  vim.api.nvim_win_set_cursor(0, { math.min(e + 2, last), 0 })
end

local function run_all()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local start = 1
  for i, l in ipairs(lines) do
    if l:match "^# %%" then
      if i - 1 >= start then
        vim.fn.MoltenEvaluateRange(start, i - 1)
      end
      start = i + 1
    end
  end
  if start <= #lines then
    vim.fn.MoltenEvaluateRange(start, #lines)
  end
end

-- On opening a .ipynb: start the kernel named in its metadata and load saved outputs
local function import_outputs(e)
  vim.schedule(function()
    local kernels = vim.fn.MoltenAvailableKernels()
    local ok, kernel_name = pcall(function()
      local f = assert(io.open(e.file, "r"))
      local meta = vim.json.decode(f:read "a")["metadata"]
      f:close()
      return meta.kernelspec.name
    end)
    if not ok or not vim.tbl_contains(kernels, kernel_name) then
      kernel_name = nil
      local venv = os.getenv "VIRTUAL_ENV" or os.getenv "CONDA_PREFIX"
      if not venv then
        -- uv project: nearest .venv above the notebook, even if not activated
        local found = vim.fs.find(".venv", { path = vim.fs.dirname(e.file), upward = true, type = "directory" })[1]
        venv = found
      end
      if venv then
        kernel_name = vim.fs.basename(venv)
        if kernel_name == ".venv" then -- uv names every env .venv; use the project dir name
          kernel_name = vim.fs.basename(vim.fs.dirname(venv))
        end
      end
    end
    if kernel_name and vim.tbl_contains(kernels, kernel_name) then
      vim.cmd(("MoltenInit %s"):format(kernel_name))
    end
    vim.cmd "MoltenImportOutput"
  end)
end

return {
  {
    "GCBallesteros/jupytext.nvim",
    lazy = false, -- must hook BufReadCmd for *.ipynb before any notebook is opened
    opts = {
      style = "percent",
      output_extension = "auto",
      force_ft = nil, -- keep python filetype -> pyright/ruff/treesitter keep working
    },
  },

  {
    "3rd/image.nvim",
    lazy = true,
    opts = {
      backend = "kitty",
      processor = "magick_cli", -- uses the `magick` binary, no luarock needed
      integrations = {
        markdown = { enabled = false },
        neorg = { enabled = false },
      },
      max_width = 100,
      max_height = 12,
      max_height_window_percentage = math.huge,
      max_width_window_percentage = math.huge,
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "blink-cmp-menu", "" },
    },
  },

  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    lazy = false, -- needed so the .ipynb autocmds exist before the first notebook opens
    dependencies = { "3rd/image.nvim" },
    build = ":UpdateRemotePlugins",
    init = function()
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_auto_open_output = false -- show output as virtual text instead of a float
      vim.g.molten_virt_text_output = true
      vim.g.molten_virt_lines_off_by_1 = false
      vim.g.molten_wrap_output = true
    end,
    config = function()
      local grp = vim.api.nvim_create_augroup("molten_ipynb", { clear = true })

      vim.api.nvim_create_autocmd("BufAdd", { group = grp, pattern = "*.ipynb", callback = import_outputs })
      -- BufAdd doesn't fire for files passed on the command line (nvim foo.ipynb)
      vim.api.nvim_create_autocmd("BufEnter", {
        group = grp,
        pattern = "*.ipynb",
        callback = function(e)
          if vim.api.nvim_get_vvar "vim_did_enter" ~= 1 then
            import_outputs(e)
          end
        end,
      })
      -- Save cell outputs back into the .ipynb
      vim.api.nvim_create_autocmd("BufWritePost", {
        group = grp,
        pattern = "*.ipynb",
        callback = function()
          if require("molten.status").initialized() == "Molten" then
            vim.cmd "MoltenExportOutput!"
          end
        end,
      })
    end,
    keys = {
      { "<leader>ji", "<cmd>MoltenInit<cr>", desc = "Jupyter init kernel" },
      { "<leader>jc", run_cell, desc = "Jupyter run cell" },
      { "<leader>jn", run_cell_and_next, desc = "Jupyter run cell and go to next" },
      { "<leader>ja", run_all, desc = "Jupyter run all cells" },
      { "<leader>jl", "<cmd>MoltenEvaluateLine<cr>", desc = "Jupyter run line" },
      { "<leader>jr", "<cmd>MoltenReevaluateCell<cr>", desc = "Jupyter re-run cell" },
      { "<leader>jv", ":<C-u>MoltenEvaluateVisual<cr>gv<esc>", mode = "x", desc = "Jupyter run selection" },
      { "<leader>jo", "<cmd>noautocmd MoltenEnterOutput<cr>", desc = "Jupyter open/enter output" },
      { "<leader>jh", "<cmd>MoltenHideOutput<cr>", desc = "Jupyter hide output" },
      { "<leader>jd", "<cmd>MoltenDelete<cr>", desc = "Jupyter delete cell output" },
      { "<leader>jx", "<cmd>MoltenInterrupt<cr>", desc = "Jupyter interrupt kernel" },
      { "<leader>jR", "<cmd>MoltenRestart!<cr>", desc = "Jupyter restart kernel" },
      { "<leader>jb", "<cmd>MoltenOpenInBrowser<cr>", desc = "Jupyter open output in browser" },
      { "<leader>jj", "o<cr># %%<cr>", desc = "Jupyter new cell below" },
    },
  },
}
