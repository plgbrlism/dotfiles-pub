local M = {}

function M.blend(foreground, background, alpha)
  local function hex_to_rgb(hex)
    hex = hex:gsub("#", "")
    return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
  end

  local r1, g1, b1 = hex_to_rgb(foreground)
  local r2, g2, b2 = hex_to_rgb(background)

  local r = math.floor(r1 * alpha + r2 * (1 - alpha) + 0.5)
  local g = math.floor(g1 * alpha + r2 * (1 - alpha) + 0.5)
  local b = math.floor(b1 * alpha + r2 * (1 - alpha) + 0.5)

  return string.format("#%02x%02x%02x", r, g, b)
end

return M
