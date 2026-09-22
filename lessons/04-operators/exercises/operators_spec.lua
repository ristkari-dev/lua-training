local here = debug.getinfo(1, "S").source:match("^@(.*/)")
package.path = here .. "?.lua;" .. package.path
local operators = require("operators")

describe("page_label", function()
  it("says page in the singular for one full page", function()
    assert.are.equal("1 page", operators.page_label(10, 10))
  end)

  it("says page in the singular for one partial page", function()
    assert.are.equal("1 page", operators.page_label(7, 10))
  end)

  it("rounds a partial page up", function()
    assert.are.equal("2 pages", operators.page_label(11, 10))
  end)

  it("counts every partial page, it does not round to nearest", function()
    assert.are.equal("4 pages", operators.page_label(10, 3))
  end)

  it("adds no extra page when the division is exact", function()
    assert.are.equal("3 pages", operators.page_label(9, 3))
  end)

  it("needs no pages for no items", function()
    assert.are.equal("0 pages", operators.page_label(0, 10))
  end)
end)
