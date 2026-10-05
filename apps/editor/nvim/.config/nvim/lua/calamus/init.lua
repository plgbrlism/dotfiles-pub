local M = {}

function M.load()
  if vim.g.colors_name then
    vim.cmd("hi clear")
  end
  vim.g.colors_name = "calamus"
  vim.o.termguicolors = true

  local ok, palette = pcall(require, "calamus.palette")
  if not ok then
    vim.notify("calamus: Could not load palette.lua", vim.log.levels.WARN)
    return
  end

  local util = require("calamus.util")
  local group_modules = {
    require("calamus.groups.editor"),
    require("calamus.groups.syntax"),
    require("calamus.groups.lsp"),
    require("calamus.groups.plugins"),
  }

  for _, mod in ipairs(group_modules) do
    local highlights = mod.get(palette, util)
    for group, opts in pairs(highlights) do
      vim.api.nvim_set_hl(0, group, opts)
    end
  end
end

return M
