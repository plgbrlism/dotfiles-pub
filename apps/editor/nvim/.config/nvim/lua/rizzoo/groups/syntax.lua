local M = {}

function M.get(c, _)
  return {
    Comment                = { fg = c.outline, italic = true },
    Constant               = { fg = c.secondary },
    String                 = { fg = c.tertiary },
    Identifier             = { fg = c.fg },
    Function               = { fg = c.primary, bold = true },
    Statement              = { fg = c.secondary, bold = true },
    Keyword                = { fg = c.secondary, italic = true },
    PreProc                = { fg = c.primary },
    Type                   = { fg = c.secondary },
    Special                = { fg = c.primary },
    Error                  = { fg = c.error },
    
    -- Treesitter Captures
    ["@variable"]          = { fg = c.fg },
    ["@variable.builtin"]  = { fg = c.secondary, italic = true },
    ["@variable.parameter"]= { fg = c.dim },
    ["@function"]          = { fg = c.primary, bold = true },
    ["@function.builtin"]  = { fg = c.primary },
    ["@keyword"]           = { fg = c.secondary, italic = true },
    ["@string"]            = { fg = c.tertiary },
    ["@type"]              = { fg = c.secondary },
    ["@property"]          = { fg = c.primary },
    ["@punctuation.bracket"] = { fg = c.outline },
  }
end

return M
