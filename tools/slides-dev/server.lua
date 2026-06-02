-- Pure routing/MIME logic for the local slides dev server.
-- The socket accept-loop lives in main.lua; everything here is unit-testable.
local lfs = require("lfs")

local M = {}

local CONTENT_TYPES = {
  html = "text/html; charset=utf-8",
  md = "text/markdown; charset=utf-8",
  css = "text/css; charset=utf-8",
  js = "text/javascript; charset=utf-8",
  mjs = "text/javascript; charset=utf-8",
  json = "application/json; charset=utf-8",
  svg = "image/svg+xml",
  png = "image/png",
  jpg = "image/jpeg",
  jpeg = "image/jpeg",
  gif = "image/gif",
  ico = "image/x-icon",
  woff = "font/woff",
  woff2 = "font/woff2",
  ttf = "font/ttf",
  otf = "font/otf",
  map = "application/json",
}

local SHARED_PREFIX = "shared/reveal/"

local function is_dir(path)
  return lfs.attributes(path, "mode") == "directory"
end

local function is_file(path)
  return lfs.attributes(path, "mode") == "file"
end

local function has_traversal(path)
  for segment in path:gmatch("[^/]+") do
    if segment == ".." then
      return true
    end
  end
  return false
end

function M.guess_content_type(name)
  local ext = name:match("%.([%a%d]+)$")
  if ext then
    return CONTENT_TYPES[ext:lower()] or "application/octet-stream"
  end
  return "application/octet-stream"
end

function M.resolve_lesson(repo_root, lesson)
  local lesson_dir = repo_root .. "/lessons/" .. lesson
  if not is_dir(lesson_dir .. "/slides") then
    error(("no slides for lesson %q (expected %s/slides)"):format(lesson, lesson_dir), 0)
  end
  return lesson_dir
end

function M.resolve(path, slides_root, shared_root)
  if path == "" or path == "index.html" then
    local candidate = slides_root .. "/index.html"
    return is_file(candidate) and candidate or nil
  end
  if has_traversal(path) then
    return nil
  end
  local candidate
  if path:sub(1, #SHARED_PREFIX) == SHARED_PREFIX then
    candidate = shared_root .. "/" .. path:sub(#SHARED_PREFIX + 1)
  else
    candidate = slides_root .. "/" .. path
  end
  return is_file(candidate) and candidate or nil
end

return M
