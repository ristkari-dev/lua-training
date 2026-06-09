# Plan D — Lesson 02 (Values & types) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Author Lesson 02 ("Values & types") — a `describe(value)` exercise (`math.type(value) or type(value)`) with a failing `busted` spec, reference solution, README, and slide deck — so `02-values-types` becomes the second published lesson.

**Architecture:** Scaffold `lessons/02-values-types/` with `make new-lesson`, rename the template's `main`→`values`, and replace the placeholder content with the `describe` exercise/solution + specs. `values.lua` is a pure module. No harness change is needed — `make lint`/`make fmt` already cover `lessons/` and `make test` already loops lesson `solutions/` (both from Lesson 01).

**Tech Stack:** Lua 5.4 (`.lua/bin/lua`), `busted`, `luacheck` (from the `.lua/` toolchain), reveal.js slides, GNU Make.

---

## Context for the implementer

- **Working directory:** `/Users/ristkari/code/private/lua-training/`. **Branch:** `lesson-02-values-types` (already checked out, off the merged `main` which has Plans A + B, the CI fix, and Lesson 01). Commit here; do not push.
- **Toolchain is present:** the gitignored `.lua/` tree already exists. Use `.lua/bin/lua`, `.lua/bin/busted`, `.lua/bin/luacheck`, or the `make` targets. Do NOT run `make bootstrap`.
- **Design:** `docs/superpowers/specs/2026-06-09-lesson-02-values-types-design.md` (read for intent; this plan is self-contained).
- **Module/spec resolution:** a lesson spec sits beside its module and prepends its own dir to `package.path` (`local here = debug.getinfo(1,"S").source:match("^@(.*/)"); package.path = here .. "?.lua;" .. package.path`), then `require("values")`. `make test` runs `exercises/` and `solutions/` in separate `busted` processes.
- **Lua note:** `math.type(x)` returns `"integer"` for integer numbers, `"float"` for floats, and `nil` for non-numbers (it does not error on non-numbers). So `math.type(value) or type(value)` returns the integer/float subtype for numbers and falls through to `type(value)` for everything else.

## File Structure

```
lessons/02-values-types/                (scaffolded, then hand-authored)
├── README.md                           (Task 2 — rewritten)
├── slides/
│   ├── index.html                      (Task 2 — title edited to "Values & types")
│   ├── slides.md                       (Task 2 — rewritten, ~9 slides)
│   └── assets/.gitkeep                 (from scaffold, unchanged)
├── exercises/
│   ├── values.lua                      (Task 1 — describe stub; renamed from main.lua)
│   └── values_spec.lua                 (Task 1 — failing spec; renamed from main_spec.lua)
└── solutions/
    ├── values.lua                      (Task 1 — describe implemented)
    └── values_spec.lua                 (Task 1 — identical spec, passes)
```

No Makefile/.luacheckrc changes (Lesson 01 already extended lint/fmt to `lessons/`).

---

## Task 1: Scaffold and author the `describe` exercise + solution

**Files:**
- Create (via scaffold, then rename/rewrite): `lessons/02-values-types/exercises/values.lua`, `lessons/02-values-types/exercises/values_spec.lua`, `lessons/02-values-types/solutions/values.lua`, `lessons/02-values-types/solutions/values_spec.lua`

- [ ] **Step 1: Scaffold the lesson**

Run: `make new-lesson NAME=02-values-types`
Expected: prints `created lessons/02-values-types`, with `README.md`, `slides/{index.html,slides.md,assets/.gitkeep}`, `exercises/{main.lua,main_spec.lua}`, `solutions/{main.lua,main_spec.lua}`.

- [ ] **Step 2: Rename the template's `main`→`values` in both dirs**

```bash
mv lessons/02-values-types/exercises/main.lua      lessons/02-values-types/exercises/values.lua
mv lessons/02-values-types/exercises/main_spec.lua lessons/02-values-types/exercises/values_spec.lua
mv lessons/02-values-types/solutions/main.lua      lessons/02-values-types/solutions/values.lua
mv lessons/02-values-types/solutions/main_spec.lua lessons/02-values-types/solutions/values_spec.lua
```

- [ ] **Step 3: Write `exercises/values.lua` (the stub)**

Overwrite `lessons/02-values-types/exercises/values.lua` with EXACTLY:
```lua
local M = {}

function M.describe(value)
  error("TODO: implement describe so the tests pass")
end

return M
```

- [ ] **Step 4: Write `exercises/values_spec.lua` (the failing spec)**

Overwrite `lessons/02-values-types/exercises/values_spec.lua` with EXACTLY:
```lua
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
```

- [ ] **Step 5: Run the exercise spec to verify it FAILS (by design)**

Run: `.lua/bin/busted lessons/02-values-types/exercises`
Expected: the stub raises `TODO: implement describe so the tests pass` → `0 successes / 0 failures / 6 errors`. This is the intended red state.

- [ ] **Step 6: Write `solutions/values.lua` (the implementation)**

Overwrite `lessons/02-values-types/solutions/values.lua` with EXACTLY:
```lua
local M = {}

function M.describe(value)
  return math.type(value) or type(value)
end

return M
```

- [ ] **Step 7: Write `solutions/values_spec.lua` (identical spec)**

Overwrite `lessons/02-values-types/solutions/values_spec.lua` with EXACTLY the same content as `exercises/values_spec.lua` (Step 4).

- [ ] **Step 8: Run the solution spec to verify it PASSES**

Run: `.lua/bin/busted lessons/02-values-types/solutions`
Expected: `6 successes / 0 failures / 0 errors`.

- [ ] **Step 9: Run the integrated lesson target**

Run: `make test-lesson LESSON=02-values-types`
Expected: exercises error (TODO, tolerated by the leading `-`), solutions pass (6). Target exit 0.

- [ ] **Step 10: Commit**

```bash
git add lessons/02-values-types/exercises lessons/02-values-types/solutions
git commit -m "feat(lesson-02): add describe exercise + solution with busted specs"
```

---

## Task 2: Author the README and slide deck

**Files:**
- Modify: `lessons/02-values-types/README.md` (overwrite)
- Modify: `lessons/02-values-types/slides/slides.md` (overwrite)
- Modify: `lessons/02-values-types/slides/index.html` (title only)

- [ ] **Step 1: Overwrite `lessons/02-values-types/README.md`**

````markdown
# Lesson 02 — Values & types

Lua's value types, the integer/float distinction new in 5.4, and the truthiness
rule. You will implement `describe(value)` to name any value's type.

## Learning goals

- Name Lua's value types: nil, boolean, number, string, table, function
- Tell integers from floats with `math.type` (a 5.4 distinction)
- State the truthiness rule — only `nil` and `false` are falsy
- Inspect with `type` and convert with `tostring`/`tonumber`
- Make a failing `busted` spec pass by implementing `describe`

## Prereqs

- Lesson 01 (functions, modules, `busted`). Toolchain via `make bootstrap`.

## Concepts

**The value types.** `type(x)` returns a type name: `"nil"`, `"boolean"`,
`"number"`, `"string"`, `"table"`, `"function"`. (`thread` and `userdata` also
exist; we meet them later.)

**Integers and floats.** Lua 5.4 splits `number` into integer and float
subtypes. `3` is an integer, `3.0` a float; `math.type(x)` returns `"integer"`,
`"float"`, or `nil` if `x` is not a number. `/` always produces a float
(`6 / 2` is `3.0`); `//` floor-divides (more in Lesson 04).

**Truthiness.** In a boolean context, only `nil` and `false` are falsy —
**everything else is truthy, including `0` and `""`**. This is why
`math.type(value) or type(value)` works: for non-numbers `math.type` returns
`nil` (falsy), so `or` falls through to `type`.

**Converting.** `tostring(x)` gives a string (handy for printing/joining);
`tonumber(s)` parses a string to a number, or returns `nil` if it can't.

## Exercise brief

Implement `describe(value)` in `exercises/values.lua` so it returns the value's
kind: `"integer"` or `"float"` for numbers, and `"string"`/`"boolean"`/`"nil"`/
`"table"` otherwise. All six examples in `exercises/values_spec.lua` must pass.

## How to run

```bash
make test-lesson LESSON=02-values-types
```

Explore in the REPL (from the lesson's `solutions/` directory so `require` finds
the file):

```bash
cd lessons/02-values-types/solutions
../../../.lua/bin/lua -e 'local v = require("values"); print(v.describe(3), v.describe(3.0), v.describe("hi"))'
```

## Going further

- `tonumber("ff", 16)` parses in another base (→ 255).
- Integers wrap on overflow: `math.maxinteger + 1 == math.mininteger`.
- `string.format("%d", 42)` / `string.format("%g", 3.14)` as a typed alternative to `tostring` (teaser for Lesson 09).
````

- [ ] **Step 2: Overwrite `lessons/02-values-types/slides/slides.md`**

````markdown
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
````

- [ ] **Step 3: Edit the deck title in `lessons/02-values-types/slides/index.html`**

The scaffolder rendered `<title>Lesson 02 — Values Types</title>` (slug-derived). Change that one line to:
```html
  <title>Lesson 02 — Values &amp; types</title>
```
(Use the HTML entity `&amp;` for the ampersand inside `<title>`.) Leave the rest of `index.html` unchanged.

- [ ] **Step 4: Verify the deck serves locally**

```bash
make slides-dev LESSON=02-values-types >/tmp/lt-l02.log 2>&1 &
sleep 1.5
curl -s http://127.0.0.1:8000/ | grep -o "<title>[^<]*</title>"
curl -s -o /dev/null -w "slidesmd=%{http_code}\n" http://127.0.0.1:8000/slides.md
pkill -f "slides-dev/main.lua"
```
Expected: `<title>Lesson 02 — Values &amp; types</title>` and `slidesmd=200`.

- [ ] **Step 5: Commit**

```bash
git add lessons/02-values-types/README.md lessons/02-values-types/slides
git commit -m "docs(lesson-02): author the README and slide deck"
```

---

## Task 3: Final verification

No files change in this task — it confirms the lesson is fully integrated. (Commit only if Step 4 surfaces something to tidy.)

- [ ] **Step 1: Lint covers the new lesson**

Run: `make lint`
Expected: `0 warnings / 0 errors` (now scanning `lessons/02-values-types` too; `describe`'s `value` param is used in the solution, and the exercise stub's unused param is allowed by `unused_args = false`).

- [ ] **Step 2: Full test suite**

Run: `make test`
Expected: `busted tools` → `42 successes`; `== lessons/01-hello/solutions ==` → `2 successes`; `== lessons/02-values-types/solutions ==` → `6 successes`. Exit 0.

- [ ] **Step 3: Static build publishes the lesson as a link**

```bash
make slides-build
grep -q '<a class="lesson" href="lessons/02-values-types/slides/">' dist/index.html && echo "02 is a link"
grep -c 'class="lesson future"' dist/index.html   # expect 21 (23 total minus 01 + 02)
grep -o "<title>[^<]*</title>" dist/lessons/02-values-types/slides/index.html
rm -rf dist
```
Expected: `02 is a link`, `21`, `<title>Lesson 02 — Values &amp; types</title>`.

- [ ] **Step 4: Clean check**

Run: `git status --porcelain`
Expected: empty (no `dist/`, no `/tmp` logs, no running `slides-dev` server — if one lingers, `pkill -f "slides-dev/main.lua"`).

---

## Self-review notes (run before reporting overall)

- `make test-lesson LESSON=02-values-types` → exercises error (6), solutions pass (6), exit 0.
- `make test` → 42 + 2 + 6.
- `make lint` → 0/0.
- `make slides-build` → `02-values-types` is a link; 21 future placeholders; deck title "Lesson 02 — Values &amp; types".
- No tool/Makefile/.luacheckrc changes; module pure; single `describe` function.

## Notes for execution

- No `git push`, no `gcloud`, no `make bootstrap`. The `.lua/` toolchain is in the working tree.
- The exercise spec failing is the deliverable (student start point); `make test` runs only `solutions/`.
- After this plan, `02-values-types` is the second published lesson. Lesson 03 (Control flow) is a future plan.
