local M = {}

local current, upcoming = 0, 1

function M.next_fib()
  current, upcoming = upcoming, current + upcoming
  return current
end

return M
