local M = {}

function M.fizzbuzz(n)
  local lines = ""
  for i = 1, n do
    local token
    if i % 15 == 0 then
      token = "FizzBuzz"
    elseif i % 3 == 0 then
      token = "Fizz"
    elseif i % 5 == 0 then
      token = "Buzz"
    else
      token = tostring(i)
    end
    if i == 1 then
      lines = token
    else
      lines = lines .. "\n" .. token
    end
  end
  return lines
end

return M
