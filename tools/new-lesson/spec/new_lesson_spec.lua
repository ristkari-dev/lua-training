local here = debug.getinfo(1, "S").source:match("^@(.*/)")
package.path = here .. "../?.lua;" .. package.path
local new_lesson = require("new_lesson")
local lfs = require("lfs")

local TEMPLATE_DIR = here .. "../template"

local _counter = 0
local function tmpdir()
  _counter = _counter + 1
  local base = (os.getenv("TMPDIR") or "/tmp"):gsub("/+$", "")
  local path = string.format("%s/lua-training-newlesson-%d-%d", base, os.time(), _counter)
  assert(lfs.mkdir(path))
  return path
end

local function read_file(path)
  local f = assert(io.open(path, "rb"))
  local data = f:read("*a")
  f:close()
  return data
end

describe("parse_name", function()
  it("splits a valid two-digit name", function()
    local name, number, title = new_lesson.parse_name("01-hello")
    assert.are.equal("01-hello", name)
    assert.are.equal("01", number)
    assert.are.equal("Hello", title)
  end)

  it("title-cases a multi-word kebab slug", function()
    local name, number, title = new_lesson.parse_name("16-coroutines-deep")
    assert.are.equal("16-coroutines-deep", name)
    assert.are.equal("16", number)
    assert.are.equal("Coroutines Deep", title)
  end)

  it("rejects invalid names", function()
    local bad = {
      "1-hello", -- one digit
      "001-hello", -- three digits
      "01_hello", -- underscore
      "01-Hello", -- uppercase slug
      "hello", -- no number
      "01-", -- empty slug
      "01--x", -- double hyphen
      "01-x-", -- trailing hyphen
      "",
    }
    for _, raw in ipairs(bad) do
      assert.has_error(function()
        new_lesson.parse_name(raw)
      end)
    end
  end)
end)

describe("scaffold", function()
  it("creates the lesson directory", function()
    local lessons = tmpdir() .. "/lessons"
    local target = new_lesson.scaffold("99-demo", lessons, TEMPLATE_DIR)
    assert.are.equal(lessons .. "/99-demo", target)
    assert.are.equal("directory", lfs.attributes(target, "mode"))
  end)

  it("renders templated README with number and title", function()
    local lessons = tmpdir() .. "/lessons"
    local target = new_lesson.scaffold("99-demo", lessons, TEMPLATE_DIR)
    local readme = read_file(target .. "/README.md")
    assert.is_truthy(readme:find("Lesson 99", 1, true))
    assert.is_truthy(readme:find("Demo", 1, true))
    assert.is_nil(lfs.attributes(target .. "/README.md.tmpl"))
  end)

  it("renders the deck index.html title", function()
    local lessons = tmpdir() .. "/lessons"
    local target = new_lesson.scaffold("99-demo", lessons, TEMPLATE_DIR)
    local index = read_file(target .. "/slides/index.html")
    assert.is_truthy(index:find("<title>Lesson 99 — Demo</title>", 1, true))
  end)

  it("renders exercises and solutions", function()
    local lessons = tmpdir() .. "/lessons"
    local target = new_lesson.scaffold("99-demo", lessons, TEMPLATE_DIR)
    local ex = read_file(target .. "/exercises/main.lua")
    local sol = read_file(target .. "/solutions/main.lua")
    assert.is_truthy(ex:find("lesson 99", 1, true))
    assert.is_truthy(sol:find("hello from lesson 99", 1, true))
  end)

  it("copies non-template files verbatim", function()
    local lessons = tmpdir() .. "/lessons"
    local target = new_lesson.scaffold("99-demo", lessons, TEMPLATE_DIR)
    assert.are.equal("file", lfs.attributes(target .. "/slides/assets/.gitkeep", "mode"))
  end)

  it("refuses to overwrite an existing lesson", function()
    local lessons = tmpdir() .. "/lessons"
    new_lesson.scaffold("99-demo", lessons, TEMPLATE_DIR)
    assert.has_error(function()
      new_lesson.scaffold("99-demo", lessons, TEMPLATE_DIR)
    end)
  end)
end)
