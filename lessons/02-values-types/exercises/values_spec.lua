local here = debug.getinfo(1, "S").source:match("^@(.*/)")
package.path = here .. "?.lua;" .. package.path
local values = require("values")

describe("describe", function()
  it("labels an integer", function()
    assert.are.equal("integer", values.describe(3))
  end)

  it("labels a float", function()
    assert.are.equal("float", values.describe(3.0))
  end)

  it("labels a string", function()
    assert.are.equal("string", values.describe("hi"))
  end)

  it("labels a boolean", function()
    assert.are.equal("boolean", values.describe(true))
  end)

  it("labels nil", function()
    assert.are.equal("nil", values.describe(nil))
  end)

  it("labels a table", function()
    assert.are.equal("table", values.describe({}))
  end)
end)
