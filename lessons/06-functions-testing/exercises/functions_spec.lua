local here = debug.getinfo(1, "S").source:match("^@(.*/)")
package.path = here .. "?.lua;" .. package.path
local functions = require("functions")

describe("tally", function()
  it("returns the passes first and the failures second", function()
    local passed, failed = functions.tally(nil, 1, false, "x", nil, 2)
    assert.are.equal(3, passed)
    assert.are.equal(2, failed)
  end)

  it("returns exactly two values", function()
    assert.are.equal(2, select("#", functions.tally(nil, 1, 2)))
  end)

  it("counts nothing when there is nothing to check", function()
    local passed, failed = functions.tally(nil)
    assert.are.equal(0, passed)
    assert.are.equal(0, failed)
  end)

  it("counts a trailing nil as a value that failed", function()
    local passed, failed = functions.tally(nil, 1, nil)
    assert.are.equal(1, passed)
    assert.are.equal(1, failed)
  end)

  it("checks ten values without running out of room", function()
    local over_two = function(value)
      return value ~= nil and value > 2
    end
    local passed, failed = functions.tally(over_two, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
    assert.are.equal(8, passed)
    assert.are.equal(2, failed)
  end)

  describe("with a spy", function()
    local over_two

    before_each(function()
      over_two = spy.new(function(value)
        return value ~= nil and value > 2
      end)
    end)

    it("calls the check once per value, nils included", function()
      functions.tally(over_two, 5, nil, 9)
      assert.spy(over_two).was.called(3)
    end)

    it("never calls the check when there are no values", function()
      functions.tally(over_two)
      assert.spy(over_two).was_not.called()
    end)

    it("hands the check one value, not the rest of them", function()
      functions.tally(over_two, 5, 1, 9)
      assert.spy(over_two).was.called_with(5)
      assert.spy(over_two).was.called_with(1)
      assert.spy(over_two).was.called_with(9)
    end)
  end)

  it("works with any function that keeps notes, spy or not", function()
    local seen = ""
    local function record(value)
      seen = seen .. tostring(value) .. "|"
      return value ~= nil
    end
    local passed, failed = functions.tally(record, "a", nil, "b")
    assert.are.equal("a|nil|b|", seen)
    assert.are.equal(2, passed)
    assert.are.equal(1, failed)
  end)
end)
