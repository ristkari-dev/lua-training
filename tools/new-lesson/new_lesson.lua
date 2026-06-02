-- Scaffold a new lua-training lesson from the template tree.
local lfs = require("lfs")

local M = {}

local function read_file(path)
  local f, err = io.open(path, "rb")
  if not f then
    error(("cannot read %q: %s"):format(path, tostring(err)), 0)
  end
  local data = f:read("*a")
  f:close()
  return data
end

local function write_file(path, data)
  local f, err = io.open(path, "wb")
  if not f then
    error(("cannot write %q: %s"):format(path, tostring(err)), 0)
  end
  f:write(data)
  f:close()
end

local function attr_mode(path)
  return lfs.attributes(path, "mode")
end

local function mkdir_p(path)
  local prefix = ""
  if path:sub(1, 1) == "/" then
    prefix = "/"
    path = path:sub(2)
  end
  local accum = ""
  for segment in path:gmatch("[^/]+") do
    accum = (accum == "") and segment or (accum .. "/" .. segment)
    local full = prefix .. accum
    if attr_mode(full) ~= "directory" then
      local ok, err = lfs.mkdir(full)
      if not ok and attr_mode(full) ~= "directory" then
        error(("could not create directory %q: %s"):format(full, tostring(err)), 0)
      end
    end
  end
end

local function render(text, subs)
  return (text:gsub("%${([%w_]+)}", function(key)
    local value = subs[key]
    if value == nil then
      error("unknown template variable: " .. key, 0)
    end
    return value
  end))
end

local function module_dir()
  local dir = debug.getinfo(1, "S").source:match("^@(.*/)")
  if not dir then
    error("could not determine new_lesson module directory; pass template_dir explicitly", 0)
  end
  return dir
end

local function copy_with_substitution(source, target, subs)
  mkdir_p(target)
  for entry in lfs.dir(source) do
    if entry ~= "." and entry ~= ".." then
      local src = source .. "/" .. entry
      local mode = attr_mode(src)
      if mode == "directory" then
        copy_with_substitution(src, target .. "/" .. entry, subs)
      elseif mode == "file" then
        if entry:sub(-5) == ".tmpl" then
          write_file(target .. "/" .. entry:sub(1, -6), render(read_file(src), subs))
        else
          write_file(target .. "/" .. entry, read_file(src))
        end
      end
    end
  end
end

function M.parse_name(raw)
  local number, slug = string.match(raw, "^(%d%d)%-(.+)$")
  if not number then
    error(
      ("invalid lesson name %q: expected 'NN-kebab-name' (e.g. '01-hello', '16-coroutines')"):format(
        raw
      ),
      0
    )
  end
  if not string.match(slug, "^%l") then
    error(("invalid lesson name %q: slug must start with a lowercase letter"):format(raw), 0)
  end
  -- Split on hyphens (the trailing "-" makes the final segment match too). Any
  -- empty segment means a leading/trailing/double hyphen, which is invalid.
  for segment in (slug .. "-"):gmatch("(.-)%-") do
    if not string.match(segment, "^[%l%d]+$") then
      error(("invalid lesson name %q: expected a lowercase kebab slug"):format(raw), 0)
    end
  end
  local words = {}
  for word in slug:gmatch("[^-]+") do
    words[#words + 1] = word:sub(1, 1):upper() .. word:sub(2)
  end
  return raw, number, table.concat(words, " ")
end

function M.scaffold(name, lessons_dir, template_dir)
  local parsed_name, number, title = M.parse_name(name)
  local target = lessons_dir .. "/" .. parsed_name
  if attr_mode(target) ~= nil then
    error(("lesson already exists: %s"):format(target), 0)
  end
  template_dir = template_dir or (module_dir() .. "template")
  copy_with_substitution(template_dir, target, { name = parsed_name, number = number, title = title })
  return target
end

return M
