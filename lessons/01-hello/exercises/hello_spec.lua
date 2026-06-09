local here = debug.getinfo(1, "S").source:match("^@(.*/)")
package.path = here .. "?.lua;" .. package.path
local hello = require("hello")

describe("greet", function()
  it("greets by name", function()
    assert.are.equal("Hello, Aki!", hello.greet("Aki"))
  end)

  it("greets anyone", function()
    assert.are.equal("Hello, world!", hello.greet("world"))
  end)
end)
