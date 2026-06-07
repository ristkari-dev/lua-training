-- CLI: lua tools/build-index/main.lua [--lessons DIR] [--shared DIR] [--out DIR]
local here = arg[0]:match("^(.*/)") or "./"
package.path = here .. "?.lua;" .. package.path

local builder = require("builder")

local USAGE =
  "usage: lua tools/build-index/main.lua [--lessons DIR] [--shared DIR] [--out DIR]"

local function main(argv)
  local opts = { lessons = "lessons", shared = "shared/reveal", out = "dist" }
  local i = 1
  while i <= #argv do
    local a = argv[i]
    if a == "--lessons" then
      opts.lessons = argv[i + 1]
      i = i + 2
    elseif a == "--shared" then
      opts.shared = argv[i + 1]
      i = i + 2
    elseif a == "--out" then
      opts.out = argv[i + 1]
      i = i + 2
    elseif a == "--help" or a == "-h" then
      print(USAGE)
      return 0
    else
      io.stderr:write("error: unknown argument: " .. tostring(a) .. "\n")
      return 1
    end
  end
  builder.build(opts.lessons, opts.shared, opts.out)
  print("built " .. opts.out)
  return 0
end

os.exit(main(arg))
