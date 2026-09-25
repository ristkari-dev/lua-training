# Plan H — Lesson 06 (Functions & testing) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Author Lesson 06 ("Functions & testing") — a `tally(check, ...)` exercise whose nine lines grade varargs, `select("#", ...)`, `select(i, ...)`, the call-truncation rule, a default-argument idiom and multiple return values — with a failing `busted` spec that also grades the testing half (spies in a nested `describe` with `before_each`), reference solution, README and 14-slide deck.

**Architecture:** Scaffold `lessons/06-functions-testing/` with `make new-lesson`, rename the template's `main`→`functions`, and replace the placeholder content with the `tally` exercise/solution + specs. `functions.lua` is a pure module with one function and one file-local helper. The spec uses the house `package.path` + `require` header. No harness change — `make lint`/`make fmt` already cover `lessons/`, `make test` already loops lesson `solutions/`, and since PR #9 `make new-lesson` takes the deck title from `tools/build-index/catalog.lua`, so no title hand-fix is expected this time.

**Tech Stack:** Lua 5.4 (`.lua/bin/lua`), `busted` 2.2.0 (with luassert spies), `luacheck`, reveal.js slides, GNU Make.

**Spec:** `docs/superpowers/specs/2026-09-22-lesson-06-functions-testing-design.md`

## Global Constraints

- **Lua 5.4** (PUC-Rio, via `.lua/`); `luacheck` `std = "lua54"` is the only static gate.
- **Prerequisite ceiling:** students have finished Lessons 01–05, so control flow IS available. Still forbidden in the graded solution: tables as data structures and the table library — including **`{...}` and `table.pack`** (L08; the module table `local M = {}` is the L01 pattern and is fine) — the string library (L09), metatables (L10), `pcall`/error handling beyond the stub's bare `error()` (L13), iterators (L14), deep closures (L15), `math`/`os`/`io` (L17), `_G`/`_ENV` (L18). `select` IS in scope: the curriculum line names it.
- **Four-file lesson convention:** `README.md`, `slides/`, `exercises/`, `solutions/`; the spec file is byte-identical in `exercises/` and `solutions/`.
- **Module name:** `functions` (files `functions.lua`, `functions_spec.lua`); graded function `tally`.
- **House spec header:** `debug.getinfo` + `package.path` + `require`, as in lessons 01/02/04/05.
- **No harness edits:** no changes to `Makefile`, `.luacheckrc`, `tools/`, `shared/`.
- **Definition of done for the lesson:** `make test-lesson LESSON=06-functions-testing` passes AND `make lint` is clean.
- **House voice:** short sentences, second person, em dashes, no exclamation marks.
- **Commit messages end with:** `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`
- **Commits are GPG-signed.** If one fails with `gpg: signing failed: Bad PIN`, report BLOCKED — never commit unsigned, never retry in a loop.

---

## Context for the implementer

- **Working directory:** `/Users/ristkari/code/private/lua-training/`. **Branch:** `lesson-06-functions-testing` (already checked out off merged `main`, which has Lessons 01–05 and the tool fixes from PR #9). The design doc is already committed on this branch. Commit here; do NOT push.
- **Toolchain present:** the gitignored `.lua/` tree already exists. Use `.lua/bin/lua`, `.lua/bin/busted`, `.lua/bin/luacheck`, or the `make` targets. Do NOT run `make bootstrap`.
- **Read for house style before writing prose:** `lessons/04-operators/README.md` and `lessons/05-control-flow/slides/slides.md`.
- **Scratch dir for throwaway files:** `/private/tmp/claude-501/-Users-ristkari-code-private-lua-training/f282ee64-4464-42c2-be99-69487673f9f6/scratchpad/l06-impl/`. Nothing there is ever committed.
- **`make test-lesson` output is expected to be noisy:** the `exercises/` run fails by design (9 errors), then the `solutions/` run passes (9 successes); the target exits 0.
- **Every Lua and busted value quoted in this plan was run against the repo's toolchain before the plan was written.** If one of your own runs contradicts the plan, report that rather than silently changing the text.
- **Known, accepted dodges:** `table.pack(...)` with `.n`, and a positional unroll wide enough to cover the ten-value test (`local a, b, c, d, e, f, g, h, i, j = ...`), both pass all nine tests and lint clean. Documented in the design doc, closed in the README's prose (Task 2) — a fixed list of named parameters is banned by name, alongside `{...}` and `table.pack` — never in the spec. Do not add tests or sandboxing to catch either. Plain `{...}` + `#` does NOT pass — it misses the trailing `nil`.

## File Structure

```
lessons/06-functions-testing/             (scaffolded, then hand-authored)
├── README.md                             (Task 2 — rewritten)
├── slides/
│   ├── index.html                        (from scaffold; title should already be
│   │                                      correct since PR #9 — Task 2 verifies)
│   ├── slides.md                         (Task 2 — rewritten, 14 slides)
│   └── assets/.gitkeep                   (from scaffold, unchanged)
├── exercises/
│   ├── functions.lua                     (Task 1 — tally stub; renamed from main.lua)
│   └── functions_spec.lua                (Task 1 — failing spec)
└── solutions/
    ├── functions.lua                     (Task 1 — tally implemented)
    └── functions_spec.lua                (Task 1 — identical spec, passes)
```

No `Makefile`/`.luacheckrc`/`tools/` changes.

---

## Task 1: Scaffold and author the `tally` exercise + solution

**Files:**
- Create (via scaffold, then rename/rewrite): `lessons/06-functions-testing/exercises/functions.lua`, `lessons/06-functions-testing/exercises/functions_spec.lua`, `lessons/06-functions-testing/solutions/functions.lua`, `lessons/06-functions-testing/solutions/functions_spec.lua`
- Also created by the scaffold (left for Task 2): `lessons/06-functions-testing/README.md`, `lessons/06-functions-testing/slides/index.html`, `lessons/06-functions-testing/slides/slides.md`, `lessons/06-functions-testing/slides/assets/.gitkeep`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: module `functions` returning a table with one function, `functions.tally(check, ...)` → two integers (passes, failures). `check` is optional: when `nil`, a value passes if it is truthy. Task 2's README and slides quote this signature and the commands below.

- [ ] **Step 1: Scaffold the lesson**

Run: `make new-lesson NAME=06-functions-testing`
Expected: prints `created lessons/06-functions-testing`, with `README.md`, `slides/{index.html,slides.md,assets/.gitkeep}`, `exercises/{main.lua,main_spec.lua}`, `solutions/{main.lua,main_spec.lua}`.

- [ ] **Step 2: Rename the template's `main`→`functions` in both dirs**

```bash
mv lessons/06-functions-testing/exercises/main.lua      lessons/06-functions-testing/exercises/functions.lua
mv lessons/06-functions-testing/exercises/main_spec.lua lessons/06-functions-testing/exercises/functions_spec.lua
mv lessons/06-functions-testing/solutions/main.lua      lessons/06-functions-testing/solutions/functions.lua
mv lessons/06-functions-testing/solutions/main_spec.lua lessons/06-functions-testing/solutions/functions_spec.lua
```

- [ ] **Step 3: Write the failing spec (`exercises/functions_spec.lua`)**

Overwrite `lessons/06-functions-testing/exercises/functions_spec.lua` with EXACTLY:

```lua
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
```

- [ ] **Step 4: Write the stub (`exercises/functions.lua`)**

Overwrite `lessons/06-functions-testing/exercises/functions.lua` with EXACTLY:

```lua
local M = {}

function M.tally(check, ...)
  error("TODO: implement tally so the tests pass")
end

return M
```

- [ ] **Step 5: Run the exercise spec to verify it fails**

Run: `.lua/bin/busted lessons/06-functions-testing/exercises`
Expected: `0 successes / 0 failures / 9 errors`, each error reading `TODO: implement tally so the tests pass`. Exit code 1.

- [ ] **Step 6: Copy the spec into `solutions/` (byte-identical)**

```bash
cp lessons/06-functions-testing/exercises/functions_spec.lua lessons/06-functions-testing/solutions/functions_spec.lua
diff lessons/06-functions-testing/exercises/functions_spec.lua lessons/06-functions-testing/solutions/functions_spec.lua && echo "specs identical"
```
Expected: `specs identical`.

- [ ] **Step 7: Write the reference solution (`solutions/functions.lua`)**

Overwrite `lessons/06-functions-testing/solutions/functions.lua` with EXACTLY:

```lua
local M = {}

-- With no check to judge them, a value passes when it is truthy (Lesson 02).
local function truthy(value)
  return value
end

function M.tally(check, ...)
  check = check or truthy
  local passed, failed = 0, 0
  for i = 1, select("#", ...) do
    if check((select(i, ...))) then
      passed = passed + 1
    else
      failed = failed + 1
    end
  end
  return passed, failed
end

return M
```

The inner parentheses in `check((select(i, ...)))` are deliberate and load-bearing: `select(i, ...)` returns value *i* **and every value after it**, so without them the check receives the whole tail. Do not "simplify" them away.

- [ ] **Step 8: Run the solution spec to verify it passes**

Run: `.lua/bin/busted lessons/06-functions-testing/solutions`
Expected: `9 successes / 0 failures / 0 errors`. Exit code 0.

- [ ] **Step 9: Run the solution spec shuffled, five seeds**

```bash
for seed in 1 2 3 4 5; do
  printf 'seed %s: ' "$seed"
  .lua/bin/busted --shuffle --seed=$seed lessons/06-functions-testing/solutions 2>&1 | grep -E "successes" | head -1
done
```
Expected: `9 successes` on every seed. This is what proves the `before_each` isolates the spy — a shared spy would accumulate calls and fail under reordering.

- [ ] **Step 10: Verify the spec catches every mistake**

Throwaway copies in the scratch dir — never commit them. Run:

```bash
SCRATCH=/private/tmp/claude-501/-Users-ristkari-code-private-lua-training/f282ee64-4464-42c2-be99-69487673f9f6/scratchpad/l06-impl
rm -rf "$SCRATCH" && mkdir -p "$SCRATCH"
for d in skip_nil unroll spill swapped third_value no_default brace_count table_pack; do
  mkdir -p "$SCRATCH/$d"
  cp lessons/06-functions-testing/solutions/functions_spec.lua "$SCRATCH/$d/functions_spec.lua"
done

# skips the check for nil values
cat > "$SCRATCH/skip_nil/functions.lua" <<'LUA'
local M = {}
local function truthy(v) return v end
function M.tally(check, ...)
  check = check or truthy
  local passed, failed = 0, 0
  for i = 1, select("#", ...) do
    local value = select(i, ...)
    if value ~= nil and check(value) then passed = passed + 1 else failed = failed + 1 end
  end
  return passed, failed
end
return M
LUA

# positional unroll instead of select(i, ...)
cat > "$SCRATCH/unroll/functions.lua" <<'LUA'
local M = {}
local function truthy(v) return v end
function M.tally(check, ...)
  check = check or truthy
  local n = select("#", ...)
  local a, b, c, d, e = ...
  local passed, failed = 0, 0
  if n >= 1 then if check(a) then passed = passed + 1 else failed = failed + 1 end end
  if n >= 2 then if check(b) then passed = passed + 1 else failed = failed + 1 end end
  if n >= 3 then if check(c) then passed = passed + 1 else failed = failed + 1 end end
  if n >= 4 then if check(d) then passed = passed + 1 else failed = failed + 1 end end
  if n >= 5 then if check(e) then passed = passed + 1 else failed = failed + 1 end end
  return passed, failed
end
return M
LUA

# spills the whole tail into the check
cat > "$SCRATCH/spill/functions.lua" <<'LUA'
local M = {}
local function truthy(v) return v end
function M.tally(check, ...)
  check = check or truthy
  local passed, failed = 0, 0
  for i = 1, select("#", ...) do
    if check(select(i, ...)) then passed = passed + 1 else failed = failed + 1 end
  end
  return passed, failed
end
return M
LUA

# returns the two numbers the wrong way round
cat > "$SCRATCH/swapped/functions.lua" <<'LUA'
local M = {}
local function truthy(v) return v end
function M.tally(check, ...)
  check = check or truthy
  local passed, failed = 0, 0
  for i = 1, select("#", ...) do
    if check((select(i, ...))) then passed = passed + 1 else failed = failed + 1 end
  end
  return failed, passed
end
return M
LUA

# helpfully returns a third value
cat > "$SCRATCH/third_value/functions.lua" <<'LUA'
local M = {}
local function truthy(v) return v end
function M.tally(check, ...)
  check = check or truthy
  local passed, failed = 0, 0
  for i = 1, select("#", ...) do
    if check((select(i, ...))) then passed = passed + 1 else failed = failed + 1 end
  end
  return passed, failed, passed + failed
end
return M
LUA

# no default for check
cat > "$SCRATCH/no_default/functions.lua" <<'LUA'
local M = {}
function M.tally(check, ...)
  local passed, failed = 0, 0
  for i = 1, select("#", ...) do
    if check((select(i, ...))) then passed = passed + 1 else failed = failed + 1 end
  end
  return passed, failed
end
return M
LUA

# {...} with # — misses the trailing nil
cat > "$SCRATCH/brace_count/functions.lua" <<'LUA'
local M = {}
local function truthy(v) return v end
function M.tally(check, ...)
  check = check or truthy
  local values = {...}
  local passed, failed = 0, 0
  for i = 1, #values do
    if check(values[i]) then passed = passed + 1 else failed = failed + 1 end
  end
  return passed, failed
end
return M
LUA

# the documented dodge — expected to PASS
cat > "$SCRATCH/table_pack/functions.lua" <<'LUA'
local M = {}
local function truthy(v) return v end
function M.tally(check, ...)
  check = check or truthy
  local values = table.pack(...)
  local passed, failed = 0, 0
  for i = 1, values.n do
    if check(values[i]) then passed = passed + 1 else failed = failed + 1 end
  end
  return passed, failed
end
return M
LUA

for d in skip_nil unroll spill swapped third_value no_default brace_count table_pack; do
  printf '%-13s ' "$d"
  .lua/bin/busted "$SCRATCH/$d" 2>&1 | grep -E "successes" | head -1
done
```

Expected, exactly (verified before this plan was written):

| Directory | Expected result | Caught by |
|---|---|---|
| `skip_nil` | 7 successes / 2 failures | spy call count, and the recorder test |
| `unroll` | 8 successes / 1 failure | the ten-value test |
| `spill` | 8 successes / 1 failure | `called_with` |
| `swapped` | 6 successes / 3 failures | three value tests |
| `third_value` | 8 successes / 1 failure | the arity assertion |
| `no_default` | 6 successes / 0 failures / 3 errors | the no-check tests |
| `brace_count` | 8 successes / 1 failure | the trailing-`nil` test |
| `table_pack` | **9 successes** | nothing — the documented dodge |

If any row other than `table_pack` reports 9 successes, STOP and report it — the spec would not be grading the lesson.

- [ ] **Step 11: Clean up the scratch copies**

```bash
rm -rf /private/tmp/claude-501/-Users-ristkari-code-private-lua-training/f282ee64-4464-42c2-be99-69487673f9f6/scratchpad/l06-impl
git status --porcelain lessons/06-functions-testing
```
Expected: only files under `lessons/06-functions-testing/` are listed as untracked.

- [ ] **Step 12: Lint the new lesson**

Run: `.lua/bin/luacheck --config .luacheckrc lessons/06-functions-testing`
Expected: `0 warnings / 0 errors in 4 files`. (The `spy` global in the spec is covered by `files["**/*_spec.lua"] std "+busted"`; the stub's unused `check`/`...` are covered by `unused_args = false`.)

- [ ] **Step 13: Both specs through the make target**

Run: `make test-lesson LESSON=06-functions-testing`
Expected: the `exercises/` run reports 9 errors (by design), the `solutions/` run reports `9 successes`, and the target exits 0.

- [ ] **Step 14: Commit**

```bash
git add lessons/06-functions-testing/exercises lessons/06-functions-testing/solutions
git commit -m "feat(lesson-06): add tally exercise + solution with busted specs"
```

(The scaffolded `README.md` and `slides/` stay untracked until Task 2.)

---

## Task 2: Author the README and the slide deck

**Files:**
- Modify (rewrite the scaffold placeholders): `lessons/06-functions-testing/README.md`, `lessons/06-functions-testing/slides/slides.md`
- Verify only (no edit expected): `lessons/06-functions-testing/slides/index.html`

**Interfaces:**
- Consumes: `functions.tally(check, ...)` from Task 1, and the commands `make test-lesson LESSON=06-functions-testing` and `make lint`.
- Produces: prose only; nothing later depends on it except Task 3's verification.

- [ ] **Step 1: Check the deck bootstrap already carries the right title**

Run: `grep '<title>' lessons/06-functions-testing/slides/index.html`
Expected: `  <title>Lesson 06 — Functions &amp; testing</title>` — escaped, and taken from the lesson catalog by the scaffolder (PR #9 changed this; lessons 03 and 04 needed the line hand-fixed, this one should not). If it differs, fix that one line to exactly the expected text and say so in your report — that would mean the PR #9 fix regressed.

- [ ] **Step 2: Write `slides/slides.md`**

Overwrite `lessons/06-functions-testing/slides/slides.md` with EXACTLY the following content. (The outer four-backtick fence is this plan's quoting only — write its *contents*, starting at `## Lesson 06`. The inner ```lua and ```bash fences are part of the file.)

````markdown
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
````

- [ ] **Step 3: Write `README.md`**

Overwrite `lessons/06-functions-testing/README.md` with EXACTLY the following content. (Again: write the fence's contents, starting at `# Lesson 06`.)

````markdown
# Lesson 06 — Functions & testing

Lua functions take and return any number of values. You will implement
`tally(check, ...)` — and this is the lesson where `busted` stops being magic.

## Learning goals

- Return several values, and know that the caller decides how many to keep
- Know where a call is cut to one value: mid-list, in parentheses, or on the right of a single-name assignment
- Take any number of arguments with `...`, count them with `select("#", ...)`, reach one with `select(i, ...)`
- Pass a function as an argument and call it — functions are values
- Give an argument a default with `name = name or fallback`, and know when that is unsafe
- Read a `busted` spec: `describe`, `it`, `assert`, `before_each`, and spies
- Implement `tally(check, ...)` to make a failing spec pass

## Prereqs

- Lessons 01–05. Toolchain via `make bootstrap`.

## Concepts

**Several values.** `return passed, failed` returns two values, and the caller
decides what to do with them: `local a, b = tally(...)` keeps both, `local a =`
keeps the first, and asking for more than a function returns gives `nil`. Only the
last expression in a list expands — `print(split(), 9)` prints `1  9`, while
`print(9, split())` prints `9  1  2`.

**Parentheses mean one value.** `(split())` is the first value only. The same rule
is why `return (a, b)` will not compile: grouping asks for a single value.

**Varargs.** `function M.tally(check, ...)` accepts anything after `check`. `...` is
not a table — it is the remaining arguments, as values.

**Counting and reaching.** `select("#", ...)` is how many arguments there are,
**including trailing `nil`s**: `select("#", 1, nil, nil)` is `3`. `select(i, ...)`
returns the i-th argument *and every one after it*, so `check((select(i, ...)))` —
or `local value = select(i, ...)` — is what hands over exactly one.

**Functions are values.** A function can live in a local, be passed as an argument,
or be returned by another function. `check` is an ordinary parameter you can call.

**Defaults.** Lua has no default-argument syntax; `check = check or truthy` is the
idiom. It is safe for `0`, which is truthy in Lua, but not for `false` —
`false or "fallback"` is `"fallback"`. When `false` is a legitimate value, write
`if flag == nil then flag = true end` instead.

**busted.** `describe` groups examples, `it` names one behaviour, `assert` decides.
`before_each` runs before every `it` in its block, so each example starts from fresh
state. A **spy** wraps a function and records every call to it, which lets a test
assert *how* your code called something — `was.called(3)`, `was.called_with(5)`,
`was_not.called()` — rather than only what it returned.

## Exercise brief

Implement `tally(check, ...)` in `exercises/functions.lua`. It returns two numbers:
how many of the values passed `check`, and how many failed. With no `check` given, a
value passes when it is truthy.

Two parts of the contract are graded by spies, so they are worth stating outright:
**call `check` once per value, in order — including values that are `nil` — with
exactly one argument.** Watch the truncation rule here: `check(select(i, ...))` hands
the check the i-th value *and every value after it*; `check((select(i, ...)))` or
`local value = select(i, ...)` fixes it.

**Varargs only: no `{...}`, no `table.pack` (both Lesson 08), and no fixed list of
named parameters either — you do not know how many values there will be.**
`table.pack(...).n` gives the same answer and the tests cannot tell — but
`select("#", ...)` costs nothing and is the point of this lesson.

You are done when `make test-lesson LESSON=06-functions-testing` passes **and**
`make lint` is clean.

## How to run

```bash
make test-lesson LESSON=06-functions-testing
make lint
```

Explore in the REPL (from the lesson's `solutions/` directory so `require` finds the
file):

```bash
cd lessons/06-functions-testing/solutions
../../../.lua/bin/lua -e 'print(require("functions").tally(nil, 1, false, "x"))'
```

That prints `2	1` — two values, from one call.

## Going further

- The loop is not the only way. A recursive peel works too: pass the count along, take one value per call, and stop at zero. It never builds a table either.
- `select(-1, ...)` gives the last argument, and negative indexes count back from the end.
- Forwarding matters: `f(1, ...)` passes everything, but `f(..., 1)` cuts `...` down to its first value, because it is no longer last in the list.
````

- [ ] **Step 4: Render the deck locally**

```bash
make slides-dev LESSON=06-functions-testing &
sleep 2
curl -s http://127.0.0.1:8000/ | grep -o "<title>[^<]*</title>"
curl -s -o /dev/null -w "slidesmd=%{http_code}\n" http://127.0.0.1:8000/slides.md
pkill -f "slides-dev/main.lua"
```
Expected: `<title>Lesson 06 — Functions &amp; testing</title>` and `slidesmd=200`.

- [ ] **Step 5: Check the deck has fourteen slides**

Run: `grep -c '^---$' lessons/06-functions-testing/slides/slides.md`
Expected: `13` (fourteen slides separated by thirteen `---` lines).

- [ ] **Step 6: Verify every Lua and busted claim the prose makes**

```bash
.lua/bin/lua -e 'local function s() return 1,2 end local a,b = s() local c = s() local d,e = 7 print(a,b,c,d,e)'   # 1 2 1 7 nil
.lua/bin/lua -e 'local function s() return 1,2 end print(s()); print(s(), 9); print(9, s())'                        # 1 2 / 1 9 / 9 1 2
.lua/bin/lua -e 'local function s() return 1,2 end print((s()))'                                                    # 1
SCRATCH=/private/tmp/claude-501/-Users-ristkari-code-private-lua-training/f282ee64-4464-42c2-be99-69487673f9f6/scratchpad/l06-impl; mkdir -p "$SCRATCH"; printf 'local a, b = 1, 2\nreturn (a, b)\n' > "$SCRATCH/l06check.lua"; .lua/bin/lua "$SCRATCH/l06check.lua" 2>&1 | head -1; rm -f "$SCRATCH/l06check.lua"   # ')' expected near ','
.lua/bin/lua -e 'print(select("#", 1, nil, nil), select("#"))'                                                      # 3  0
.lua/bin/lua -e 'print(select(2, "a", "b", "c"))'                                                                   # b  c
.lua/bin/lua -e 'print(0 or "fallback", false or "fallback")'                                                       # 0  fallback
cd lessons/06-functions-testing/solutions && ../../../.lua/bin/lua -e 'print(require("functions").tally(nil, 1, false, "x"))'; cd ../../..   # 2  1
```

Then the spy claim from slide 12's speaker note, which needs busted rather than plain Lua:

```bash
SCRATCH=/private/tmp/claude-501/-Users-ristkari-code-private-lua-training/f282ee64-4464-42c2-be99-69487673f9f6/scratchpad/l06-impl-spy
mkdir -p "$SCRATCH"
cat > "$SCRATCH/spy_spec.lua" <<'LUA'
describe("spy facts", function()
  it("is a callable table that records", function()
    local s = spy.new(function(v) return v end)
    s(1)
    assert.are.equal("table", type(s))
    assert.spy(s).was.called(1)
    assert.spy(s).was.called_with(1)
  end)
end)
LUA
.lua/bin/busted "$SCRATCH/spy_spec.lua" 2>&1 | tail -2
rm -rf "$SCRATCH"
```
Expected: `1 success / 0 failures / 0 errors` — confirming a spy's `type` really is `"table"`.

If any output differs from the comment beside it, fix the prose to match reality and say so in your report — reality wins.

- [ ] **Step 7: Commit**

```bash
git add lessons/06-functions-testing/README.md lessons/06-functions-testing/slides
git commit -m "docs(lesson-06): author the README and slide deck"
```

---

## Task 3: Final verification

No files change in this task — it confirms the lesson is integrated. (Commit only if a step surfaces something to tidy.)

- [ ] **Step 1: Lint the whole repo**

Run: `make lint`
Expected: `0 warnings / 0 errors`.

- [ ] **Step 2: Full test suite**

Run: `make test`
Expected: `busted tools` → `49 successes`; `== lessons/01-hello/solutions ==` → `2`; `== lessons/02-values-types/solutions ==` → `6`; `== lessons/03-variables-scope/solutions ==` → `3`; `== lessons/04-operators/solutions ==` → `6`; `== lessons/05-control-flow/solutions ==` → `5`; `== lessons/06-functions-testing/solutions ==` → `9`. Exit 0.

(The `os.time()` temp-dir flake that used to interrupt this run was fixed in PR #9. If you see "File exists" from a tool spec, that is a regression worth reporting, not a known flake.)

- [ ] **Step 3: Static build publishes the lesson as a link**

```bash
make slides-build
grep -q '<a class="lesson" href="lessons/06-functions-testing/slides/">' dist/index.html && echo "06 is a link"
grep -c 'class="lesson future"' dist/index.html   # expect 17 (23 total minus 01-06)
grep -o "<title>[^<]*</title>" dist/lessons/06-functions-testing/slides/index.html
rm -rf dist
```
Expected: `06 is a link`, `17`, `<title>Lesson 06 — Functions &amp; testing</title>`.

- [ ] **Step 4: Formatting matches StyLua (only if StyLua is installed)**

```bash
command -v stylua >/dev/null && stylua --check lessons/06-functions-testing || echo "stylua not installed — skipped"
```
Expected: no output from `--check` (or the skip message). If it reports diffs, run `make fmt`, re-run Task 1 Step 8 and Step 12, and amend the Task 1 commit.

- [ ] **Step 5: Clean check**

Run: `git status --porcelain`
Expected: empty (no `dist/`, no scratch files, no lingering `slides-dev` server — if one lingers, `pkill -f "slides-dev/main.lua"`).

---

## Self-review notes (run before reporting overall)

- `make test-lesson LESSON=06-functions-testing` → exercises error (9), solutions pass (9), exit 0.
- `--shuffle` on five seeds → 9/9 each.
- Mistake injection (Task 1 Step 10) → seven wrong solutions fail with the tabulated counts; `table_pack` passes, as documented.
- `make test` → 49 + 2 + 6 + 3 + 6 + 5 + 9.
- `make lint` → 0/0.
- `make slides-build` → `06-functions-testing` is a link; 17 future placeholders; escaped deck title.
- Deck has 14 slides; every quoted Lua and busted claim re-verified (Task 2 Step 6).
- `solutions/functions.lua` keeps the inner parentheses in `check((select(i, ...)))`; no `{...}`, no `table.pack`, no string library.
- Specs byte-identical between `exercises/` and `solutions/`.

## Notes for execution

- No `git push`, no `gcloud`, no `make bootstrap`.
- The exercise spec failing is the deliverable; `make test` runs only `solutions/`.
- Two commits are expected: `feat(lesson-06): …` (Task 1) and `docs(lesson-06): …` (Task 2).
- End commit messages with:
  `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`
- After this plan, Phase 1 needs only Lesson 07 (the CLI capstone) to be complete.
