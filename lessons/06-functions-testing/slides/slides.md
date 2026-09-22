## Lesson 06
### Functions & testing

Functions that take and return any number of values — and the tests that prove it.

Note:
Goal: multiple returns, varargs, select, default arguments — and busted explained at last.

---

## Returning more than one value

```lua
local function split()
  return 1, 2
end

local a, b = split()    -- 1  2
local c    = split()    -- 1        (the extra is dropped)
local d, e = 7          -- 7  nil   (the missing one is nil)
```

The caller decides how many values to keep.

---

## Where a call is cut short

```lua
print(split())      -- 1  2    (last in the list: expands)
print(split(), 9)   -- 1  9    (mid-list: cut to one value)
print(9, split())   -- 9  1  2
```

Note:
Only the last expression in a list expands. Anywhere else, a call yields one value.

---

## Parentheses mean one value

```lua
print((split()))    -- 1

return (a, b)       -- syntax error: ')' expected near ','
```

Grouping something is asking for a single value — so Lua refuses to group a
pair of return values at all.

---

## Varargs

```lua
function M.tally(check, ...)
  -- ... is every argument after `check`
end
```

`...` is not a table. It is the rest of the arguments, as values.

---

## Counting them

```lua
select("#", 1, nil, nil)   -- 3   (trailing nils count)
select("#")                -- 0
```

`#` on a table cannot see a trailing `nil`; `select("#", ...)` can — which is
why the count is its own question.

---

## Reaching one of them

```lua
select(2, "a", "b", "c")   -- b  c    (value 2 AND the rest)

check((select(i, ...)))            -- one value
local value = select(i, ...)       -- also one value
```

`select(i, ...)` returns the i-th value *and everything after it*. Parentheses
or an assignment cut it back to one.

---

## Functions are values

```lua
local check = is_even          -- held in a local
tally(check, 1, 2, 3)          -- passed as an argument

local function pick(flag)
  return flag and is_even or truthy   -- returned from a function
end
```

`check` is an ordinary parameter that happens to be callable.

---

## Default arguments

```lua
check = check or truthy    -- the idiom

0 or "fallback"            -- 0          (0 is truthy in Lua)
false or "fallback"        -- "fallback" (so false cannot survive this)
```

When `false` is a legitimate value, test for `nil` instead:
`if flag == nil then flag = true end`

---

## busted: describe, it, assert

```lua
describe("tally", function()
  it("counts the passes", function()
    assert.are.equal(3, (functions.tally(nil, 1, 2, 3)))
  end)
end)
```

`describe` groups, `it` names one behaviour, `assert` decides. This is the file
you have been reading since Lesson 01.

---

## before_each

```lua
describe("with a spy", function()
  local over_two

  before_each(function()
    over_two = spy.new(function(value)
      return value ~= nil and value > 2
    end)
  end)
end)
```

Runs before every `it` in its block. Share one spy across tests instead, and the
recorded calls pile up from the test before.

---

## Spies

```lua
local over_two = spy.new(function(v) return v ~= nil and v > 2 end)

assert.spy(over_two).was.called(3)
assert.spy(over_two).was.called_with(5)
assert.spy(over_two).was_not.called()
```

A spy wraps a function and records every call. It answers *how* your code
called something — which no return value can show.

Note:
A spy is a callable table, so type(spy) is "table", not "function".

---

## The exercise — tally

```lua
function M.tally(check, ...)
  check = check or truthy
  -- count the values that pass, and the ones that fail
  return passed, failed
end
```

Call `check` once per value, in order, with exactly one argument. Varargs only —
no `{...}`, no `table.pack`.

```bash
make test-lesson LESSON=06-functions-testing
```

---

## What's next

**Lesson 07 — Phase 1 capstone.** A small command-line tool, built from
everything so far.
