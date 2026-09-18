local here = debug.getinfo(1, "S").source:match("^@(.*/)")

-- Test plumbing (you don't need to follow this until Lessons 10 and 18).
-- Each test loads a brand-new copy of scope.lua with its own stand-in for the
-- global table: reading a global (like `error`) still works, but any global the
-- module *creates* lands in `globals`, where the last test can see it.
-- A syntax error in scope.lua is reported at the loadfile line below.
local function load_scope()
  local globals = setmetatable({}, { __index = _G })
  local scope = assert(loadfile(here .. "scope.lua", "t", globals))()
  return scope, globals
end

describe("next_fib", function()
  it("starts the sequence at 1", function()
    local scope = load_scope()
    assert.are.equal(1, scope.next_fib())
  end)

  it("walks 1, 1, 2, 3, 5, 8", function()
    local scope = load_scope()
    assert.are.equal(1, scope.next_fib())
    assert.are.equal(1, scope.next_fib())
    assert.are.equal(2, scope.next_fib())
    assert.are.equal(3, scope.next_fib())
    assert.are.equal(5, scope.next_fib())
    assert.are.equal(8, scope.next_fib())
  end)

  it("creates no global variables", function()
    local scope, globals = load_scope()
    scope.next_fib()
    scope.next_fib()
    assert.are.same({}, globals) -- a leak prints as { *[name] = value }
  end)
end)
