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

-- ─── Rust (codelldb) ────────────────────────────────────────────────────────
-- Builds with cargo (debug profile) and debugs the resulting binary.
-- `cargo_args` is e.g. { "build" } or { "test", "--no-run" }.
local function cargo_executable(cargo_args)
  vim.cmd "silent! wall"
  local cmd = vim.list_extend({ "cargo" }, cargo_args)
  vim.list_extend(cmd, { "--message-format=json" })
  vim.notify("Running " .. table.concat(cmd, " ") .. " ...", vim.log.levels.INFO)
  local result = vim.system(cmd, { text = true, cwd = vim.fn.getcwd() }):wait()

  local exes = {}
  for line in (result.stdout or ""):gmatch "[^\n]+" do
    local ok, msg = pcall(vim.json.decode, line)
    if ok and msg.reason == "compiler-artifact" and msg.executable and msg.executable ~= vim.NIL then
      table.insert(exes, msg.executable)
    end
  end
  if result.code ~= 0 or #exes == 0 then
    vim.notify("Cargo build failed:\n" .. (result.stderr or ""), vim.log.levels.ERROR)
    return dap.ABORT
  end
  if #exes == 1 then
    return exes[1]
  end
  -- Several binaries (e.g. lib tests + integration tests): ask which one
  local items = { "Pick executable:" }
  for i, exe in ipairs(exes) do
    items[#items + 1] = i .. ". " .. vim.fn.fnamemodify(exe, ":t")
  end
  local choice = vim.fn.inputlist(items)
  return exes[choice] or dap.ABORT
end

-- Name of the function the cursor is in (the test to run)
local function current_fn_name()
  local line = vim.fn.search([[\v^\s*(pub\s+)?(async\s+)?fn\s+\w+]], "bcnW")
  return line > 0 and vim.fn.getline(line):match "fn%s+([%w_]+)" or ""
end

local rust_base = {
  type = "codelldb",
  request = "launch",
  cwd = "${workspaceFolder}",
  stopOnEntry = false,
  sourceLanguages = { "rust" }, -- Rust-aware display of Vec, String, Option, ...
}

dap.configurations.rust = {
  vim.tbl_extend("force", rust_base, {
    name = "Cargo: debug main binary",
    program = function()
      return cargo_executable { "build" }
    end,
    args = function()
      return vim.split(vim.fn.input "Arguments: ", " ", { trimempty = true })
    end,
  }),
  vim.tbl_extend("force", rust_base, {
    name = "Cargo: debug test under cursor",
    program = function()
      return cargo_executable { "test", "--no-run" }
    end,
    args = function()
      -- Test filter (substring match); --nocapture shows println! output
      return { vim.fn.input("Test name: ", current_fn_name()), "--nocapture", "--test-threads=1" }
    end,
  }),
}
