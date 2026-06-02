local here = debug.getinfo(1, "S").source:match("^@(.*/)")
package.path = here .. "../?.lua;" .. package.path
local server = require("server")
local lfs = require("lfs")

local _counter = 0
local function tmpdir()
  _counter = _counter + 1
  local base = (os.getenv("TMPDIR") or "/tmp"):gsub("/+$", "")
  local path = string.format("%s/lua-training-slides-%d-%d", base, os.time(), _counter)
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

-- A minimal repo skeleton: one lesson deck + shared/reveal.
local function make_repo()
  local root = tmpdir()
  mkpath(root .. "/lessons/01-hello/slides")
  write_file(root .. "/lessons/01-hello/slides/index.html", "<html>hello deck</html>")
  write_file(root .. "/lessons/01-hello/slides/slides.md", "# slides")
  mkpath(root .. "/shared/reveal/dist")
  write_file(root .. "/shared/reveal/dist/reveal.css", "/* reveal */")
  return root
end

describe("resolve_lesson", function()
  it("returns the lesson dir when slides/ exists", function()
    local root = make_repo()
    assert.are.equal(root .. "/lessons/01-hello", server.resolve_lesson(root, "01-hello"))
  end)

  it("errors when the lesson has no slides/", function()
    local root = make_repo()
    mkpath(root .. "/lessons/02-empty")
    assert.has_error(function()
      server.resolve_lesson(root, "02-empty")
    end)
  end)

  it("errors when the lesson is missing", function()
    local root = make_repo()
    assert.has_error(function()
      server.resolve_lesson(root, "99-missing")
    end)
  end)
end)

describe("resolve", function()
  local root, slides_root, shared_root
  before_each(function()
    root = make_repo()
    slides_root = root .. "/lessons/01-hello/slides"
    shared_root = root .. "/shared/reveal"
  end)

  it("maps empty path to the deck index", function()
    assert.are.equal(slides_root .. "/index.html", server.resolve("", slides_root, shared_root))
  end)

  it("maps 'index.html' to the deck index", function()
    assert.are.equal(
      slides_root .. "/index.html",
      server.resolve("index.html", slides_root, shared_root)
    )
  end)

  it("serves slides.md from the deck", function()
    assert.are.equal(
      slides_root .. "/slides.md",
      server.resolve("slides.md", slides_root, shared_root)
    )
  end)

  it("maps shared/reveal/* to the shared tree", function()
    assert.are.equal(
      shared_root .. "/dist/reveal.css",
      server.resolve("shared/reveal/dist/reveal.css", slides_root, shared_root)
    )
  end)

  it("returns nil for an unknown file", function()
    assert.is_nil(server.resolve("nope.txt", slides_root, shared_root))
  end)

  it("rejects path traversal", function()
    assert.is_nil(server.resolve("../../etc/passwd", slides_root, shared_root))
    assert.is_nil(server.resolve("shared/reveal/../../../etc/passwd", slides_root, shared_root))
  end)
end)

describe("guess_content_type", function()
  it("maps .css", function()
    assert.are.equal("text/css; charset=utf-8", server.guess_content_type("reveal.css"))
  end)

  it("maps .mjs to javascript", function()
    assert.are.equal("text/javascript; charset=utf-8", server.guess_content_type("reveal.esm.mjs"))
  end)

  it("maps .svg", function()
    assert.are.equal("image/svg+xml", server.guess_content_type("diagram.svg"))
  end)

  it("defaults to octet-stream for unknown extensions", function()
    assert.are.equal("application/octet-stream", server.guess_content_type("mystery.xyz"))
  end)
end)
