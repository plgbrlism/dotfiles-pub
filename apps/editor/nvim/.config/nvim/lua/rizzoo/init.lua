local M = {}

function M.load()
  if vim.g.colors_name then
    vim.cmd("hi clear")
  end
  vim.g.colors_name = "rizzoo"
  vim.o.termguicolors = true

  local ok, palette = pcall(require, "rizzoo.palette")
  if not ok then
    vim.notify("rizzoo: Could not load palette.lua", vim.log.levels.WARN)
    return
  end

  local util = require("rizzoo.util")
  local group_modules = {
    require("rizzoo.groups.editor"),
    require("rizzoo.groups.syntax"),
    require("rizzoo.groups.lsp"),
    require("rizzoo.groups.plugins"),
  }

  for _, mod in ipairs(group_modules) do
    local highlights = mod.get(palette, util)
    for group, opts in pairs(highlights) do
      vim.api.nvim_set_hl(0, group, opts)
    end
  end
end

return M
