local M = {}

function M.describe(value)
  return math.type(value) or type(value)
end

return M
