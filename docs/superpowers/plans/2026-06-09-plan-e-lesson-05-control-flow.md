# Plan E — Lesson 05 (Control flow) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Author Lesson 05 ("Control flow") — a `fizzbuzz(n)` exercise (numeric `for` + `if`/`elseif`/`else` ladder, returning newline-joined FizzBuzz for `1..n`) with a failing `busted` spec, reference solution, README, and slide deck — so `05-control-flow` becomes a published lesson (authored ahead of Lessons 03–04).

**Architecture:** Scaffold `lessons/05-control-flow/` with `make new-lesson`, rename the template's `main`→`control_flow`, and replace the placeholder content with the `fizzbuzz` exercise/solution + specs. `control_flow.lua` is a pure module. No harness change — `make lint`/`make fmt` already cover `lessons/` and `make test` already loops lesson `solutions/`.

**Tech Stack:** Lua 5.4 (`.lua/bin/lua`), `busted`, `luacheck`, reveal.js slides, GNU Make.

---

## Context for the implementer

- **Working directory:** `/Users/ristkari/code/private/lua-training/`. **Branch:** `lesson-05-control-flow` (already checked out, off the merged `main` with Plans A + B, the CI fix, and Lessons 01–02). Commit here; do not push.
- **Toolchain present:** the gitignored `.lua/` tree already exists. Use `.lua/bin/lua`, `.lua/bin/busted`, `.lua/bin/luacheck`, or the `make` targets. Do NOT run `make bootstrap`.
- **Design:** `docs/superpowers/specs/2026-06-09-lesson-05-control-flow-design.md` (read for intent; this plan is self-contained).
- **Module/spec resolution:** the spec sits beside its module and prepends its dir to `package.path`, then `require("control_flow")`. `make test` runs `exercises/` and `solutions/` in separate `busted` processes.
- **FizzBuzz ordering:** the `if` ladder MUST test `i % 15 == 0` before `% 3` and `% 5`, or 15 matches "Fizz" first. (`%` is the modulo operator — covered in Lesson 04, which precedes this lesson.)

## File Structure

```
lessons/05-control-flow/                (scaffolded, then hand-authored)
├── README.md                           (Task 2 — rewritten)
├── slides/
│   ├── index.html                      (Task 2 — title edited to "Control flow")
│   ├── slides.md                       (Task 2 — rewritten, ~9 slides)
│   └── assets/.gitkeep                 (from scaffold, unchanged)
├── exercises/
│   ├── control_flow.lua                (Task 1 — fizzbuzz stub; renamed from main.lua)
│   └── control_flow_spec.lua           (Task 1 — failing spec)
└── solutions/
    ├── control_flow.lua                (Task 1 — fizzbuzz implemented)
    └── control_flow_spec.lua           (Task 1 — identical spec, passes)
```

No Makefile/.luacheckrc changes.

---

## Task 1: Scaffold and author the `fizzbuzz` exercise + solution

**Files:**
- Create (via scaffold, then rename/rewrite): `lessons/05-control-flow/exercises/control_flow.lua`, `lessons/05-control-flow/exercises/control_flow_spec.lua`, `lessons/05-control-flow/solutions/control_flow.lua`, `lessons/05-control-flow/solutions/control_flow_spec.lua`

- [ ] **Step 1: Scaffold the lesson**

Run: `make new-lesson NAME=05-control-flow`
Expected: prints `created lessons/05-control-flow`, with `README.md`, `slides/{index.html,slides.md,assets/.gitkeep}`, `exercises/{main.lua,main_spec.lua}`, `solutions/{main.lua,main_spec.lua}`.

- [ ] **Step 2: Rename the template's `main`→`control_flow` in both dirs**

```bash
mv lessons/05-control-flow/exercises/main.lua      lessons/05-control-flow/exercises/control_flow.lua
mv lessons/05-control-flow/exercises/main_spec.lua lessons/05-control-flow/exercises/control_flow_spec.lua
mv lessons/05-control-flow/solutions/main.lua      lessons/05-control-flow/solutions/control_flow.lua
mv lessons/05-control-flow/solutions/main_spec.lua lessons/05-control-flow/solutions/control_flow_spec.lua
```

- [ ] **Step 3: Write `exercises/control_flow.lua` (the stub)**

Overwrite `lessons/05-control-flow/exercises/control_flow.lua` with EXACTLY:
```lua
local M = {}

function M.fizzbuzz(n)
  error("TODO: implement fizzbuzz so the tests pass")
end

return M
```

- [ ] **Step 4: Write `exercises/control_flow_spec.lua` (the failing spec)**

Overwrite `lessons/05-control-flow/exercises/control_flow_spec.lua` with EXACTLY:
```lua
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
```

- [ ] **Step 5: Run the exercise spec to verify it FAILS (by design)**

Run: `.lua/bin/busted lessons/05-control-flow/exercises`
Expected: the stub raises `TODO: implement fizzbuzz so the tests pass` → `0 successes / 0 failures / 5 errors`. Intended red state.

- [ ] **Step 6: Write `solutions/control_flow.lua` (the implementation)**

Overwrite `lessons/05-control-flow/solutions/control_flow.lua` with EXACTLY:
```lua
local M = {}

function M.fizzbuzz(n)
  local lines = ""
  for i = 1, n do
    local token
    if i % 15 == 0 then
      token = "FizzBuzz"
    elseif i % 3 == 0 then
      token = "Fizz"
    elseif i % 5 == 0 then
      token = "Buzz"
    else
      token = tostring(i)
    end
    if i == 1 then
      lines = token
    else
      lines = lines .. "\n" .. token
    end
  end
  return lines
end

return M
```

- [ ] **Step 7: Write `solutions/control_flow_spec.lua` (identical spec)**

Overwrite `lessons/05-control-flow/solutions/control_flow_spec.lua` with EXACTLY the same content as `exercises/control_flow_spec.lua` (Step 4).

- [ ] **Step 8: Run the solution spec to verify it PASSES**

Run: `.lua/bin/busted lessons/05-control-flow/solutions`
Expected: `5 successes / 0 failures / 0 errors`.

- [ ] **Step 9: Run the integrated lesson target**

Run: `make test-lesson LESSON=05-control-flow`
Expected: exercises error (TODO, tolerated), solutions pass (5). Exit 0.

- [ ] **Step 10: Commit**

```bash
git add lessons/05-control-flow/exercises lessons/05-control-flow/solutions
git commit -m "feat(lesson-03): add fizzbuzz exercise + solution with busted specs"
```

---

## Task 2: Author the README and slide deck

**Files:**
- Modify: `lessons/05-control-flow/README.md` (overwrite)
- Modify: `lessons/05-control-flow/slides/slides.md` (overwrite)
- Modify: `lessons/05-control-flow/slides/index.html` (title only)

- [ ] **Step 1: Overwrite `lessons/05-control-flow/README.md`**

````markdown
# Lesson 05 — Control flow

Branch with `if`/`elseif`/`else` and loop with `for`. You will implement
FizzBuzz — the classic exercise that needs both.

## Learning goals

- Branch with `if`/`elseif`/`else`
- Loop with the numeric `for`; recognize `while` and `repeat`/`until`
- Recognize the generic `for` (a teaser for Lesson 08) and `break`
- Know Lua has no `continue`, and the idioms for it
- Implement `fizzbuzz(n)` to make a failing `busted` spec pass

## Prereqs

- Lessons 01–02. Toolchain via `make bootstrap`.

## Concepts

**Branching.** `if cond then … elseif cond then … else … end` — no parentheses
around conditions, and every block ends with `end`. Comparisons are `==`, `~=`
(not `!=`), `<`, `<=`, `>`, `>=`. Recall from Lesson 02 that only `nil` and
`false` are falsy, so `if x then` runs even when `x` is `0` or `""`.

**Looping.** Three loops: the numeric `for i = start, stop[, step] do … end`
(runs zero times if `start > stop`); the top-tested `while cond do … end`; and
the bottom-tested `repeat … until cond` (runs at least once). The generic
`for k, v in pairs(t) do` iterates tables — a teaser; the full story is Lesson 08.

**break and continue.** `break` exits the nearest loop. Lua has **no
`continue`** — skip an iteration with an `if`/`else`, or jump to a label at the
loop's end: `if skip then goto next end … ::next::`.

**FizzBuzz ordering.** Check `i % 15 == 0` **before** `% 3` and `% 5` — 15 is a
multiple of both, so a later branch would otherwise win.

## Exercise brief

Implement `fizzbuzz(n)` in `exercises/control_flow.lua` so it returns the
FizzBuzz lines for `1..n` joined by `"\n"`: numbers become themselves, multiples
of 3 become `"Fizz"`, of 5 `"Buzz"`, of 15 `"FizzBuzz"`. All five examples in
`exercises/control_flow_spec.lua` must pass.

## How to run

```bash
make test-lesson LESSON=05-control-flow
```

Explore in the REPL (from the lesson's `solutions/` directory):

```bash
cd lessons/05-control-flow/solutions
../../../.lua/bin/lua -e 'print(require("control_flow").fizzbuzz(15))'
```

## Going further

- Lua has no `continue`; the `goto ::continue::` label idiom fills the gap.
- A numeric `for`'s loop variable is local to the loop — reassigning it inside the body doesn't change the iteration.
- `repeat … until` can reference locals declared inside the body in its `until` condition (unusual scoping).
````

- [ ] **Step 2: Overwrite `lessons/05-control-flow/slides/slides.md`**

````markdown
## Lesson 05
### Control flow

Branch with `if`, loop with `for` — then build FizzBuzz.

Note:
Goal: write a numeric for loop and an if/elseif/else ladder.

---

## if / elseif / else

```lua
if score >= 90 then
  grade = "A"
elseif score >= 80 then
  grade = "B"
else
  grade = "C"
end
```

No parentheses around the condition; `then` … `end`.

---

## Conditions

```lua
a == b    -- equal
a ~= b    -- not equal   (not !=)
a < b   a <= b   a > b   a >= b
```

Only `nil` and `false` are falsy (from L02) — `if x then` runs for `0` and `""` too.

---

## Numeric for

```lua
for i = 1, 5 do print(i) end    -- 1 2 3 4 5
for i = 10, 1, -1 do end         -- count down (step -1)
for i = 1, 0 do end              -- never runs (start > stop)
```

---

## while and repeat

```lua
while n > 0 do
  n = n - 1
end

local k = 0
repeat
  k = k + 1
until k >= 3                     -- runs at least once
```

---

## Generic for (a teaser)

```lua
for index, value in ipairs(list) do end
for key, value in pairs(tbl) do end
```

Iterates tables — the full story is Lesson 08.

---

## break, and the missing continue

```lua
for i = 1, 10 do
  if done then break end         -- exit the loop
end
```

Lua has no `continue`. Use `if/else`, or jump to a label:

```lua
for i = 1, 10 do
  if skip(i) then goto next end
  process(i)
  ::next::
end
```

---

## The exercise — FizzBuzz

```lua
for i = 1, n do
  if i % 15 == 0 then token = "FizzBuzz"
  elseif i % 3 == 0 then token = "Fizz"
  elseif i % 5 == 0 then token = "Buzz"
  else token = tostring(i) end
  -- join tokens with "\n"
end
```

Check `% 15` first!  `make test-lesson LESSON=05-control-flow`

---

## What's next

**Lesson 06 — Functions & testing.**
````

- [ ] **Step 3: Edit the deck title in `lessons/05-control-flow/slides/index.html`**

The scaffolder rendered `<title>Lesson 05 — Control Flow</title>`. Change that one line to (lowercase "flow", matching the landing-page catalog):
```html
  <title>Lesson 05 — Control flow</title>
```
Leave the rest of `index.html` unchanged.

- [ ] **Step 4: Verify the deck serves locally**

```bash
make slides-dev LESSON=05-control-flow >/tmp/lt-l03.log 2>&1 &
sleep 1.5
curl -s http://127.0.0.1:8000/ | grep -o "<title>[^<]*</title>"
curl -s -o /dev/null -w "slidesmd=%{http_code}\n" http://127.0.0.1:8000/slides.md
pkill -f "slides-dev/main.lua"
```
Expected: `<title>Lesson 05 — Control flow</title>` and `slidesmd=200`.

- [ ] **Step 5: Commit**

```bash
git add lessons/05-control-flow/README.md lessons/05-control-flow/slides
git commit -m "docs(lesson-03): author the README and slide deck"
```

---

## Task 3: Final verification

No files change in this task — it confirms the lesson is integrated. (Commit only if Step 4 surfaces something to tidy.)

- [ ] **Step 1: Lint covers the new lesson**

Run: `make lint`
Expected: `0 warnings / 0 errors`. (`fizzbuzz`'s `n` is used in the solution; the exercise stub's unused `n` is allowed by `unused_args = false`.)

- [ ] **Step 2: Full test suite**

Run: `make test`
Expected: `busted tools` → `42 successes`; `== lessons/01-hello/solutions ==` → `2`; `== lessons/02-values-types/solutions ==` → `6`; `== lessons/05-control-flow/solutions ==` → `5`. Exit 0.

- [ ] **Step 3: Static build publishes the lesson as a link**

```bash
make slides-build
grep -q '<a class="lesson" href="lessons/05-control-flow/slides/">' dist/index.html && echo "03 is a link"
grep -c 'class="lesson future"' dist/index.html   # expect 20 (23 total minus 01+02+03)
grep -o "<title>[^<]*</title>" dist/lessons/05-control-flow/slides/index.html
rm -rf dist
```
Expected: `03 is a link`, `20`, `<title>Lesson 05 — Control flow</title>`.

- [ ] **Step 4: Clean check**

Run: `git status --porcelain`
Expected: empty (no `dist/`, no `/tmp` logs, no running `slides-dev` server — if one lingers, `pkill -f "slides-dev/main.lua"`).

---

## Self-review notes (run before reporting overall)

- `make test-lesson LESSON=05-control-flow` → exercises error (5), solutions pass (5), exit 0.
- `make test` → 42 + 2 + 6 + 5.
- `make lint` → 0/0.
- `make slides-build` → `05-control-flow` is a link; 20 future placeholders; deck title "Lesson 05 — Control flow".
- No tool/Makefile/.luacheckrc changes; module pure; single `fizzbuzz` function.

## Notes for execution

- No `git push`, no `gcloud`, no `make bootstrap`.
- The exercise spec failing is the deliverable; `make test` runs only `solutions/`.
- After this plan, `05-control-flow` is published (authored ahead of Lessons 03–04); Lessons 03–04 are future plans.
