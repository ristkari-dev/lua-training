local here = debug.getinfo(1, "S").source:match("^@(.*/)")
package.path = here .. "../?.lua;" .. package.path
local builder = require("builder")
local lfs = require("lfs")

local _counter = 0
local function tmpdir()
  _counter = _counter + 1
  local base = (os.getenv("TMPDIR") or "/tmp"):gsub("/+$", "")
  local path = string.format("%s/lua-training-build-%d-%d", base, os.time(), _counter)
  assert(lfs.mkdir(path))
  return path
end

local function mkpath(path)
  local accum = ""
  for segment in path:gmatch("[^/]+") do
    accum = accum .. "/" .. segment
    if lfs.attributes(accum, "mode") ~= "directory" then
      assert(lfs.mkdir(accum))
    end
  end
end

local function write_file(path, data)
  local f = assert(io.open(path, "wb"))
  f:write(data)
  f:close()
end

local function read_file(path)
  local f = assert(io.open(path, "rb"))
  local data = f:read("*a")
  f:close()
  return data
end

local function count(haystack, needle)
  local n, pos = 0, 1
  while true do
    local s = haystack:find(needle, pos, true)
    if not s then
      return n
    end
    n = n + 1
    pos = s + #needle
  end
end

describe("escape_html", function()
  it("escapes &, <, >", function()
    assert.are.equal("a &amp; b &lt; c &gt; d", builder.escape_html("a & b < c > d"))
  end)
end)

describe("collect_published", function()
  it("finds lessons with a slides/ subdir", function()
    local root = tmpdir()
    mkpath(root .. "/01-hello/slides")
    mkpath(root .. "/02-values-types") -- no slides/
    local pub = builder.collect_published(root)
    assert.is_true(pub["01-hello"])
    assert.is_nil(pub["02-values-types"])
  end)

  it("is empty when the dir is missing", function()
    assert.are.same({}, builder.collect_published(tmpdir() .. "/nope"))
  end)

  it("ignores files at the top level", function()
    local root = tmpdir()
    mkpath(root .. "/01-hello/slides")
    write_file(root .. "/stray.txt", "x")
    local pub = builder.collect_published(root)
    assert.is_true(pub["01-hello"])
    assert.is_nil(pub["stray.txt"])
  end)
end)

describe("copy_tree", function()
  it("copies files and directories", function()
    local root = tmpdir()
    mkpath(root .. "/src/sub")
    write_file(root .. "/src/a.txt", "a")
    write_file(root .. "/src/sub/b.txt", "b")
    builder.copy_tree(root .. "/src", root .. "/dst")
    assert.are.equal("a", read_file(root .. "/dst/a.txt"))
    assert.are.equal("b", read_file(root .. "/dst/sub/b.txt"))
  end)

  it("is a no-op when src is missing", function()
    local root = tmpdir()
    builder.copy_tree(root .. "/nope", root .. "/dst")
    assert.is_nil(lfs.attributes(root .. "/dst", "mode"))
  end)
end)

describe("render_index", function()
  it("renders a published lesson as a link", function()
    local html = builder.render_index({ ["01-hello"] = true })
    assert.is_truthy(html:find('<a class="lesson" href="lessons/01-hello/slides/">', 1, true))
  end)

  it("renders an unpublished lesson as a future placeholder", function()
    local html = builder.render_index({})
    assert.is_truthy(html:find('<div class="lesson future" aria-disabled="true">', 1, true))
  end)

  it("contains the title and phase headers", function()
    local html = builder.render_index({})
    assert.is_truthy(html:find("<title>Lua Training</title>", 1, true))
    assert.is_truthy(html:find("Phase 1 · Foundations", 1, true))
    assert.is_truthy(html:find("Phase 3 · Idiomatic &amp; Advanced Lua", 1, true))
  end)

  it("lists lesson titles", function()
    local html = builder.render_index({})
    assert.is_truthy(html:find("Hello, Lua", 1, true))
    assert.is_truthy(html:find("Capstone: embeddable scripting host", 1, true))
  end)
end)

describe("build", function()
  it("produces index.html and copies slides + shared", function()
    local root = tmpdir()
    mkpath(root .. "/lessons/01-hello/slides")
    write_file(root .. "/lessons/01-hello/slides/index.html", "deck")
    mkpath(root .. "/shared/reveal/dist")
    write_file(root .. "/shared/reveal/dist/reveal.css", "/* css */")
    local out = root .. "/dist"

    builder.build(root .. "/lessons", root .. "/shared/reveal", out)

    assert.are.equal("deck", read_file(out .. "/lessons/01-hello/slides/index.html"))
    assert.are.equal("/* css */", read_file(out .. "/shared/reveal/dist/reveal.css"))
    local index = read_file(out .. "/index.html")
    assert.is_truthy(index:find("<title>Lua Training</title>", 1, true))
    assert.is_truthy(index:find('<a class="lesson" href="lessons/01-hello/slides/">', 1, true))
  end)

  it("overwrites a stale out dir", function()
    local root = tmpdir()
    mkpath(root .. "/lessons/01-hello/slides")
    mkpath(root .. "/shared/reveal")
    local out = root .. "/dist"
    mkpath(out)
    write_file(out .. "/stale.txt", "stale")

    builder.build(root .. "/lessons", root .. "/shared/reveal", out)

    assert.is_nil(lfs.attributes(out .. "/stale.txt", "mode"))
    assert.is_truthy(lfs.attributes(out .. "/index.html", "mode"))
  end)

  it("handles zero published lessons (all 23 are future placeholders)", function()
    local root = tmpdir()
    local out = root .. "/dist"
    builder.build(root .. "/lessons", root .. "/shared/reveal", out)
    local index = read_file(out .. "/index.html")
    assert.is_truthy(index:find("<title>Lua Training</title>", 1, true))
    assert.are.equal(23, count(index, 'class="lesson future"'))
  end)
end)
