-- Filesystem operations and HTML rendering for the static slide site.
local lfs = require("lfs")
local catalog = require("catalog")
local template = require("template")

local M = {}

local function attr_mode(path)
  return lfs.attributes(path, "mode")
end

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

function M.escape_html(text)
  local out = text:gsub("&", "&amp;")
  out = out:gsub("<", "&lt;")
  out = out:gsub(">", "&gt;")
  return out
end

function M.collect_published(lessons_dir)
  local published = {}
  if attr_mode(lessons_dir) ~= "directory" then
    return published
  end
  for entry in lfs.dir(lessons_dir) do
    if entry ~= "." and entry ~= ".." then
      if attr_mode(lessons_dir .. "/" .. entry .. "/slides") == "directory" then
        published[entry] = true
      end
    end
  end
  return published
end

function M.copy_tree(src, dst)
  if attr_mode(src) == nil then
    return
  end
  mkdir_p(dst)
  for entry in lfs.dir(src) do
    if entry ~= "." and entry ~= ".." then
      local sp = src .. "/" .. entry
      local dp = dst .. "/" .. entry
      local mode = attr_mode(sp)
      if mode == "directory" then
        M.copy_tree(sp, dp)
      elseif mode == "file" then
        write_file(dp, read_file(sp))
      end
    end
  end
end

function M.rmtree(path)
  local mode = attr_mode(path)
  if mode == nil then
    return
  end
  if mode == "directory" then
    for entry in lfs.dir(path) do
      if entry ~= "." and entry ~= ".." then
        M.rmtree(path .. "/" .. entry)
      end
    end
    lfs.rmdir(path)
  else
    os.remove(path)
  end
end

local function render_lesson(lesson, published)
  local title = M.escape_html(lesson.title)
  local blurb = M.escape_html(lesson.blurb)
  local number = lesson.number
  local dir = catalog.dir_name(lesson)
  if published[dir] then
    return ('      <a class="lesson" href="lessons/%s/slides/">\n'):format(dir)
      .. ('        <div class="num">%s</div>\n'):format(number)
      .. ('        <div class="title">%s</div>\n'):format(title)
      .. ('        <div class="blurb">%s</div>\n'):format(blurb)
      .. "      </a>\n"
  end
  return '      <div class="lesson future" aria-disabled="true">\n'
    .. ('        <div class="num">%s</div>\n'):format(number)
    .. ('        <div class="title">%s</div>\n'):format(title)
    .. ('        <div class="blurb">%s</div>\n'):format(blurb)
    .. "      </div>\n"
end

function M.render_index(published)
  local parts = {}
  for _, phase in ipairs(catalog.PHASES) do
    local num, name = phase[1], phase[2]
    parts[#parts + 1] =
      ('    <div class="phase">Phase %d · %s</div>\n'):format(num, M.escape_html(name))
    parts[#parts + 1] = '    <div class="grid">\n'
    for _, lesson in ipairs(catalog.LESSONS) do
      if lesson.phase == num then
        parts[#parts + 1] = render_lesson(lesson, published)
      end
    end
    parts[#parts + 1] = "    </div>\n"
  end
  return template.HEAD .. table.concat(parts) .. template.TAIL
end

function M.build(lessons_dir, shared_dir, out_dir)
  M.rmtree(out_dir)
  mkdir_p(out_dir)
  local published = M.collect_published(lessons_dir)
  for name in pairs(published) do
    M.copy_tree(lessons_dir .. "/" .. name .. "/slides", out_dir .. "/lessons/" .. name .. "/slides")
  end
  M.copy_tree(shared_dir, out_dir .. "/shared/reveal")
  write_file(out_dir .. "/index.html", M.render_index(published))
end

return M
