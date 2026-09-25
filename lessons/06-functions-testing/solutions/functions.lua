local M = {}

-- With no check to judge them, a value passes when it is truthy (Lesson 02).
local function truthy(value)
  return value
end

function M.tally(check, ...)
  check = check or truthy
  local passed, failed = 0, 0
  for i = 1, select("#", ...) do
    if check((select(i, ...))) then
      passed = passed + 1
    else
      failed = failed + 1
    end
  end
  return passed, failed
end

return M
