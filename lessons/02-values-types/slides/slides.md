## Lesson 02
### Values & types

Lua's value types, the integer/float split, and truthiness.

Note:
Goal: name the types, tell integers from floats, and know what counts as true.

---

## The value types

```lua
type(nil)     -- "nil"
type(true)    -- "boolean"
type(42)      -- "number"
type("hi")    -- "string"
type({})      -- "table"
type(print)   -- "function"
```

`type(x)` returns the type name as a string.

---

## Numbers: integer & float

Lua 5.4 splits numbers into integers and floats.

```lua
math.type(3)      -- "integer"
math.type(3.0)    -- "float"
math.type(6 / 2)  -- "float"    (/ always gives a float)
math.type(6 // 2) -- "integer"  (// floor-divides — more in L04)
```

---

## Strings

```lua
local s = "Hello"
#s              -- 5             (length in bytes)
s .. ", Lua"    -- "Hello, Lua"  (.. joins, from L01)
[[ multi
line ]]                          -- a long string
```

---

## Truthiness

Only `nil` and `false` are falsy. **Everything else is truthy — including
`0` and `""`.**

```lua
-- truthy:  0, "", "false", {}, print
-- falsy:   nil, false
```

Note:
Surprising if you come from C/Python/JS, where 0 and "" are falsy.

---

## Inspecting values

```lua
type(3.0)       -- "number"
math.type(3.0)  -- "float"
math.type("x")  -- nil   (nil for non-numbers)
```

`type` names the type; `math.type` splits numbers into integer/float.

---

## Converting

```lua
tostring(42)     -- "42"
tonumber("42")   -- 42
tonumber("3.14") -- 3.14
tonumber("nope") -- nil   (nil on failure)
```

---

## The exercise

```lua
function M.describe(value)
  return math.type(value) or type(value)
end
```

`math.type` gives `"integer"`/`"float"`, or `nil` for non-numbers — and
because `nil` is falsy, `or` falls through to `type`.

```bash
make test-lesson LESSON=02-values-types
```

---

## What's next

**Lesson 03 — Control flow.**
