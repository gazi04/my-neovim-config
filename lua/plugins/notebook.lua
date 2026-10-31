-- Jupyter notebooks in Neovim
--   jupytext.nvim : opens *.ipynb as markdown (prose rendered by render-markdown.nvim,
--                   code in ```python blocks), writes back to .ipynb on save
--   otter.nvim    : LSP (pyright/ruff: completion, hover, diagnostics) inside the code blocks
--   molten-nvim   : runs code in a real Jupyter kernel, shows output inline
--   image.nvim    : renders plots/images inline (kitty graphics protocol)
--
-- Python deps live in ~/.virtualenvs/neovim, managed with uv
-- (see vim.g.python3_host_prog in options.lua). Add a package:
--   uv pip install --python ~/.virtualenvs/neovim/bin/python <pkg>
-- Use a uv project's .venv as kernel (auto-picked when the notebook lives in that project):
--   uv add --dev ipykernel && uv run python -m ipykernel install --user --name <project-dir-name>
-- After first install / molten update run :UpdateRemotePlugins and restart Neovim.

-- Code cells of the current buffer as { open, first, last, close } line numbers (1-based).
--   markdown (notebooks): ```python fenced blocks; open/close are the fence lines
--   python (.py scripts):  "# %%" percent cells; "# %% [markdown]" cells are skipped
local function code_cells()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local cells = {}
  if vim.bo.filetype == "markdown" then
    local open
    for i, l in ipairs(lines) do
      if not open and l:match "^```%s*{?python" then
        open = i
      elseif open and l:match "^```%s*$" then
        table.insert(cells, { open = open, first = open + 1, last = i - 1, close = i })
        open = nil
      end
    end
  else
    local open, md = 0, false
    local function add(stop)
      if not md and stop >= open + 1 then
        table.insert(cells, { open = open, first = open + 1, last = stop, close = stop })
      end
    end
    for i, l in ipairs(lines) do
      if l:match "^# %%%%" then
        add(i - 1)
        open, md = i, l:match "%[markdown%]" ~= nil
      end
    end
    add(#lines)
  end
  return cells
end

local function eval_cell(c)
  if c.first <= c.last then
    vim.fn.MoltenEvaluateRange(c.first, c.last)
  end
end

local function current_cell()
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local cells = code_cells()
  for i, c in ipairs(cells) do
    if cur >= c.open and cur <= c.close then
      return c, cells[i + 1]
    end
  end
end

local function run_cell()
  local c = current_cell()
  if c then
    eval_cell(c)
  else
    vim.notify("Cursor is not in a code cell", vim.log.levels.WARN)
  end
end

local function run_cell_and_next()
  local c, next_cell = current_cell()
  if not c then
    return run_cell()
  end
  eval_cell(c)
  if next_cell then
    vim.api.nvim_win_set_cursor(0, { next_cell.first, 0 })
  end
end

local function run_all()
  for _, c in ipairs(code_cells()) do
    eval_cell(c)
  end
end

local function new_cell()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local c = current_cell()
  if c then
    row = c.close
  end
  local cell = vim.bo.filetype == "markdown" and { "", "```python", "", "```" } or { "", "# %%", "" }
  vim.api.nvim_buf_set_lines(0, row, row, false, cell)
  vim.api.nvim_win_set_cursor(0, { row + 3, 0 })
  vim.cmd "startinsert"
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
    dependencies = { "jmbuhr/otter.nvim" },
    opts = {
      style = "markdown",
      output_extension = "md",
      force_ft = "markdown", -- render-markdown.nvim renders the markdown cells
    },
    config = function(_, opts)
      require("jupytext").setup(opts)
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("notebook_markdown", { clear = true }),
        pattern = "markdown",
        callback = function(e)
          if not vim.api.nvim_buf_get_name(e.buf):match "%.ipynb$" then
            return
          end
          -- prettier (conform, markdown) could reshape cells on save
          vim.b[e.buf].disable_autoformat = true
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(e.buf) then
              vim.api.nvim_buf_call(e.buf, function()
                require("otter").activate({ "python" }, true, true, nil)
              end)
            end
          end)
        end,
      })
    end,
  },

  {
    "jmbuhr/otter.nvim",
    lazy = true,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {},
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
      vim.g.molten_virt_lines_off_by_1 = true -- output below the closing ``` fence
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
      { "<leader>jj", new_cell, desc = "Jupyter new code cell below" },
    },
  },
}
