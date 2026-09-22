## Lesson 03
### Variables & scope

Decide where each variable lives — and why it matters.

Note:
Goal: local vs global, block/chunk visibility, <const>, multiple assignment.

---

## Globals by default

```lua
count = 0          -- no `local`: this is a GLOBAL
print(countr)      -- nil — a typo just reads as nil, no error
```

Every chunk in the program shares one set of globals.

Note:
Two costs: typos are silent, and any other file can overwrite the name.

---

## Another file, same name

```lua
-- somewhere else in the program
count = 99

-- your code, later
count = count + 1    -- 100, not 1
```

`make lint` catches the missing `local`:
`setting non-standard global variable 'count'`

---

## local

```lua
local count = 0      -- declare: visible from here on
count = count + 1    -- assign: no `local` this time
```

House rule: every variable is `local` unless you can say why not.

---

## Blocks and chunks

```lua
local x = 1
do
  local x = 2        -- a different variable, inside this block
  print(x)           -- 2
end
print(x)             -- 1

do local secret = 42 end
print(secret)        -- nil — gone with its block
```

A file is a chunk; `do … end` and function bodies are blocks.

---

## Declaring vs assigning

```lua
local n = 10

local function bump()
  local n = n + 1    -- a NEW n; the outer one never changes
  return n
end

local function bump_outer()
  n = n + 1          -- updates the outer n
  return n
end
```

luacheck: `shadowing upvalue 'n' on line 1`

Note:
"Upvalue" here just means a local from an enclosing scope — the full story is L15.

---

## Locals keep their value

```lua
local M = {}

local calls = 0      -- private to this file, survives between calls

function M.hit()
  calls = calls + 1
  return calls
end

return M
```

`M.hit()` returns 1, then 2, then 3 — with no global in sight.

---

## const (5.4)

```lua
local LIMIT <const> = 10
LIMIT = 11           -- the file won't even load:
                     -- attempt to assign to const variable 'LIMIT'

local a <const>, b = 1, 2   -- only `a` is const
```

Note:
luacheck does not flag this one — Lua catches it when the file loads.

---

## Multiple assignment

```lua
local a, b = 1, 2
a, b = b, a          -- swap, no temporary: a is 2, b is 1

local x, y, z = 1, 2 -- z is nil    (missing values)
local p = 1, 2       -- p is 1      (extra value dropped)
```

The whole right-hand side is worked out **before** anything is assigned.

---

## The exercise — next_fib

```lua
local current, upcoming = 0, 1     -- too narrow inside the function,
                                   -- too wide as a global

function M.next_fib()
  current, upcoming = upcoming, current + upcoming
  return current
end
```

`make test-lesson LESSON=03-variables-scope` — and `make lint`

---

## What's next

**Lesson 04 — Operators & expressions.**
