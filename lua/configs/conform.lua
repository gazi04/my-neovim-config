local prettier = { "prettierd" }
local clang = { "clang-format" }

local options = {
  formatters_by_ft = {
    lua = { "stylua" },

    -- PHP: pint (Laravel) or php-cs-fixer (Symfony), whichever the project has in vendor/bin
    php = { "pint", "php_cs_fixer", stop_after_first = true },
    blade = { "blade-formatter" },

    javascript = prettier,
    javascriptreact = prettier,
    typescript = prettier,
    typescriptreact = prettier,
    vue = prettier,
    svelte = prettier,
    css = prettier,
    scss = prettier,
    html = prettier,
    json = prettier,
    jsonc = prettier,
    yaml = prettier,
    markdown = prettier,

    python = { "ruff_organize_imports", "ruff_format" },

    c = clang,
    cpp = clang,
    arduino = clang,

    rust = { "rustfmt" }, -- from the Rust toolchain; reads the edition from Cargo.toml
  },

  -- Format on save. Toggle with :FormatToggle (all buffers) or :FormatToggle!
  -- (current buffer only), e.g. in repos with a different code style.
  format_on_save = function(bufnr)
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end
    -- No LSP fallback: a file type without a formatter above is left as is,
    -- instead of being reformatted by its language server
    return { timeout_ms = 1500, lsp_format = "never" }
  end,
}

vim.api.nvim_create_user_command("FormatToggle", function(args)
  local scope = args.bang and vim.b or vim.g
  scope.disable_autoformat = not scope.disable_autoformat
  vim.notify(
    "Format on save " .. (scope.disable_autoformat and "disabled" or "enabled") .. (args.bang and " (buffer)" or ""),
    vim.log.levels.INFO
  )
end, { bang = true, desc = "Toggle format on save" })

return options
