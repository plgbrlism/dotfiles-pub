local M = {}

function M.get(c, u)
  return {
    Normal       = { fg = c.fg, bg = c.bg },
    NormalNC     = { fg = c.fg, bg = c.bg },
    NormalFloat  = { fg = c.fg, bg = c.surface },
    FloatBorder  = { fg = c.outline, bg = c.surface },
    CursorLine   = { bg = u.blend(c.fg, c.bg, 0.05) },
    CursorLineNr = { fg = c.primary, bold = true },
    LineNr       = { fg = c.dim },
    Visual       = { bg = u.blend(c.primary, c.bg, 0.25) },
    Search       = { fg = c.bg, bg = c.tertiary },
    IncSearch    = { fg = c.bg, bg = c.primary },
    StatusLine   = { fg = c.fg, bg = c.surface },
    StatusLineNC = { fg = c.dim, bg = c.bg },
    WinSeparator = { fg = u.blend(c.outline, c.bg, 0.4) },
    Pmenu        = { fg = c.fg, bg = c.surface },
    PmenuSel     = { fg = c.bg, bg = c.primary, bold = true },
    PmenuThumb   = { bg = c.outline },
  }
end

return M

