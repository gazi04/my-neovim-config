local dap = require "dap"
local dapui = require "dapui"

local mason = vim.fn.stdpath "data" .. "/mason"

-- ─── UI ─────────────────────────────────────────────────────────────────────
dapui.setup()
require("nvim-dap-virtual-text").setup {} -- variable values shown next to the code

-- Open the panels when a session starts, close them when it ends
dap.listeners.after.event_initialized["dapui"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui"] = function()
  dapui.close()
end

vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DiagnosticHint" })
vim.fn.sign_define("DapLogPoint", { text = "◉", texthl = "DiagnosticInfo" })
vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual" })

-- ─── Python (debugpy) ───────────────────────────────────────────────────────
-- debugpy runs from Mason's own venv; the program itself runs with the
-- project's interpreter (dap-python checks $VIRTUAL_ENV, then .venv / venv).
-- Built-in configurations: current file, file with arguments, attach, ...
require("dap-python").setup(mason .. "/packages/debugpy/venv/bin/python")

table.insert(dap.configurations.python, {
  type = "python",
  request = "launch",
  name = "FastAPI (uvicorn)",
  module = "uvicorn",
  -- No --reload: it serves from a child process the debugger doesn't follow
  args = function()
    local app = vim.fn.input("App (module:variable): ", "main:app")
    return { app, "--port", "8000" }
  end,
  cwd = "${workspaceFolder}",
  justMyCode = true,
})

-- ─── PHP (Xdebug) ───────────────────────────────────────────────────────────
-- Neovim listens on port 9003; PHP connects when Xdebug is triggered
-- (XDEBUG_TRIGGER=1 for CLI, ?XDEBUG_TRIGGER=1 / browser extension for web).
dap.adapters.php = {
  type = "executable",
  command = mason .. "/bin/php-debug-adapter",
}

dap.configurations.php = {
  {
    type = "php",
    request = "launch",
    name = "Listen for Xdebug",
    port = 9003,
  },
}

-- ─── C / C++ (codelldb) ─────────────────────────────────────────────────────
dap.adapters.codelldb = {
  type = "server",
  port = "${port}",
  executable = {
    command = mason .. "/bin/codelldb",
    args = { "--port", "${port}" },
  },
}

-- Build the current file with debug info into /tmp and return the binary
local function compile_current_file()
  local file = vim.fn.expand "%:p"
  local compiler = vim.bo.filetype == "c" and "gcc" or "g++"
  local out = "/tmp/dap-" .. vim.fn.expand "%:t:r"
  vim.cmd "silent! write"
  local result = vim.system({ compiler, "-g", "-O0", file, "-o", out }, { text = true }):wait()
  if result.code ~= 0 then
    vim.notify("Compile failed:\n" .. result.stderr, vim.log.levels.ERROR)
    return dap.ABORT
  end
  return out
end

local c_configurations = {
  {
    name = "Launch executable",
    type = "codelldb",
    request = "launch",
    -- Build it yourself first with -g (CMake: -DCMAKE_BUILD_TYPE=Debug)
    program = function()
      return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file")
    end,
    args = function()
      return vim.split(vim.fn.input "Arguments: ", " ", { trimempty = true })
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
  },
  {
    name = "Compile & debug current file",
    type = "codelldb",
    request = "launch",
    program = compile_current_file,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
  },
}

dap.configurations.c = c_configurations
dap.configurations.cpp = c_configurations
