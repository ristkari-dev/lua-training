-- CLI entry point: lua tools/new-lesson/main.lua NN-slug [--lessons-dir DIR]
local here = arg[0]:match("^(.*/)") or "./"
package.path = here .. "?.lua;" .. package.path

local new_lesson = require("new_lesson")

local USAGE = "usage: lua tools/new-lesson/main.lua NN-slug [--lessons-dir DIR]"

local function main(argv)
  local name, lessons_dir = nil, "lessons"
  local i = 1
  while i <= #argv do
    local a = argv[i]
    if a == "--lessons-dir" then
      lessons_dir = argv[i + 1]
      i = i + 2
    elseif a == "--help" or a == "-h" then
      print(USAGE)
      return 0
    elseif a:sub(1, 1) == "-" then
      io.stderr:write("error: unknown option: " .. a .. "\n")
      return 1
    elseif not name then
      name = a
      i = i + 1
    else
      io.stderr:write("error: unexpected argument: " .. a .. "\n")
      return 1
    end
  end

  if not name then
    io.stderr:write(USAGE .. "\n")
    return 1
  end

  local ok, result = pcall(new_lesson.scaffold, name, lessons_dir)
  if not ok then
    io.stderr:write("error: " .. tostring(result) .. "\n")
    return 1
  end
  print("created " .. result)
  return 0
end

os.exit(main(arg))
