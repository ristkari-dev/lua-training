local here = debug.getinfo(1, "S").source:match("^@(.*/)")
package.path = here .. "../?.lua;" .. package.path
local catalog = require("catalog")

describe("catalog", function()
  it("has 23 lessons", function()
    assert.are.equal(23, #catalog.LESSONS)
  end)

  it("numbers are sequential two-digit 01..23", function()
    for i, lesson in ipairs(catalog.LESSONS) do
      assert.are.equal(string.format("%02d", i), lesson.number)
    end
  end)

  it("defines four phases", function()
    local nums = {}
    for _, phase in ipairs(catalog.PHASES) do
      nums[#nums + 1] = phase[1]
    end
    assert.are.same({ 1, 2, 3, 4 }, nums)
  end)

  it("every lesson's phase is a defined phase", function()
    local defined = {}
    for _, phase in ipairs(catalog.PHASES) do
      defined[phase[1]] = true
    end
    for _, lesson in ipairs(catalog.LESSONS) do
      assert.is_true(defined[lesson.phase] == true)
    end
  end)

  it("has the expected phase boundaries", function()
    local by_number = {}
    for _, lesson in ipairs(catalog.LESSONS) do
      by_number[lesson.number] = lesson.phase
    end
    assert.are.equal(1, by_number["01"])
    assert.are.equal(1, by_number["07"])
    assert.are.equal(2, by_number["08"])
    assert.are.equal(2, by_number["13"])
    assert.are.equal(3, by_number["14"])
    assert.are.equal(3, by_number["18"])
    assert.are.equal(4, by_number["19"])
    assert.are.equal(4, by_number["23"])
  end)

  it("slugs are kebab-case", function()
    -- Lua patterns cannot quantify a capture group, so validate per segment:
    -- a lowercase-leading slug split on "-" must have only [a-z0-9]+ segments.
    for _, lesson in ipairs(catalog.LESSONS) do
      local slug = lesson.slug
      assert.is_truthy(slug:match("^%l"), "slug must start lowercase: " .. slug)
      for segment in (slug .. "-"):gmatch("(.-)%-") do
        assert.is_truthy(segment:match("^[%l%d]+$"), "bad slug segment in: " .. slug)
      end
    end
  end)

  it("dir_name combines number and slug", function()
    local first = catalog.LESSONS[1]
    assert.are.equal(first.number .. "-" .. first.slug, catalog.dir_name(first))
  end)
end)
