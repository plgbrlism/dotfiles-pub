local M = {}

function M.get(c, u)
  return {
    -- Telescope / Fzf-lua / Snacks
    SnacksPickerNormal         = { fg = c.fg, bg = c.surface },
    SnacksPickerBorder         = { fg = c.outline, bg = c.surface },
    TelescopeNormal            = { fg = c.fg, bg = c.surface },
    TelescopeBorder            = { fg = c.outline, bg = c.surface },
    TelescopePromptNormal      = { fg = c.fg, bg = c.surface_hi },
    TelescopePromptBorder      = { fg = c.primary, bg = c.surface_hi },
    
    -- Git signs
    GitSignsAdd                = { fg = c.tertiary },
    GitSignsChange             = { fg = c.secondary },
    GitSignsDelete             = { fg = c.error },

    -- Neo-tree / Bufferline
    NeoTreeNormal              = { fg = c.fg, bg = u.blend(c.surface, c.bg, 0.5) },
    NeoTreeNormalNC            = { fg = c.dim, bg = u.blend(c.surface, c.bg, 0.5) },
  }
end

return M
