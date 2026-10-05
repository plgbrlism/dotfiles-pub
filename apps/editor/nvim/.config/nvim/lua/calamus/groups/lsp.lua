local M = {}

function M.get(c, u)
  return {
    DiagnosticError            = { fg = c.error },
    DiagnosticWarn             = { fg = c.secondary },
    DiagnosticInfo             = { fg = c.primary },
    DiagnosticHint             = { fg = c.tertiary },
    DiagnosticUnderlineError   = { sp = c.error, undercurl = true },
    DiagnosticUnderlineWarn    = { sp = c.secondary, undercurl = true },
    DiagnosticVirtualTextError = { fg = c.error, bg = u.blend(c.error, c.bg, 0.1) },
  }
end

return M
