require "nvchad.autocmds"

vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    pcall(vim.treesitter.start)
  end,
})

vim.api.nvim_create_user_command("TSInstallAll", function()
  local spec = require("lazy.core.config").plugins["nvim-treesitter"]
  local opts = type(spec.opts) == "table" and spec.opts or {}
  require("nvim-treesitter").install(opts.ensure_installed)
end, {})

vim.api.nvim_create_user_command("MasonInstallAll", function()
  require("lazy").load { plugins = { "mason.nvim" } }
  local spec = require("lazy.core.config").plugins["mason.nvim"]
  local opts = require("lazy.core.plugin").values(spec, "opts", false)
  local registry = require "mason-registry"

  registry.refresh(function()
    for _, name in ipairs(opts.ensure_installed or {}) do
      local ok, pkg = pcall(registry.get_package, name)
      if not ok then
        vim.notify("Mason: unknown package " .. name, vim.log.levels.WARN)
      elseif not pkg:is_installed() then
        vim.notify("Mason: installing " .. name)
        pkg:install()
      end
    end
  end)
end, {})
