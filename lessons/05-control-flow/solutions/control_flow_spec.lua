local here = debug.getinfo(1, "S").source:match("^@(.*/)")
package.path = here .. "?.lua;" .. package.path
local control_flow = require("control_flow")

describe("fizzbuzz", function()
  it("counts plain numbers", function()
    assert.are.equal("1\n2", control_flow.fizzbuzz(2))
  end)

  it("replaces multiples of 3 with Fizz", function()
    assert.are.equal("1\n2\nFizz", control_flow.fizzbuzz(3))
  end)

  it("replaces multiples of 5 with Buzz", function()
    assert.are.equal("1\n2\nFizz\n4\nBuzz", control_flow.fizzbuzz(5))
  end)

  it("replaces multiples of 15 with FizzBuzz", function()
    assert.are.equal(
      "1\n2\nFizz\n4\nBuzz\nFizz\n7\n8\nFizz\nBuzz\n11\nFizz\n13\n14\nFizzBuzz",
      control_flow.fizzbuzz(15)
    )
  end)

  it("returns an empty string for n = 0", function()
    assert.are.equal("", control_flow.fizzbuzz(0))
  end)
end)
