# Plan F — Lesson 03 (Variables & scope) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Author Lesson 03 ("Variables & scope") — a `next_fib()` exercise whose state must live in chunk-level locals, graded by a spec that loads a fresh sandboxed copy of the module per test — with a failing `busted` spec, reference solution, README, and slide deck, so `03-variables-scope` becomes a published lesson.

**Architecture:** Scaffold `lessons/03-variables-scope/` with `make new-lesson`, rename the template's `main`→`scope`, and replace the placeholder content with the `next_fib` exercise/solution + specs. `scope.lua` is a pure module whose only state is two chunk-level locals. The spec deliberately does NOT use the house `package.path` + `require` header: it loads `scope.lua` per test via `loadfile(path, "t", env)` with a stand-in global table, so a missing `local` fails `busted` (not only `luacheck`) and no `reset()` function is needed. No harness change — `make lint`/`make fmt` already cover `lessons/`, `make test` already loops lesson `solutions/`, and `tools/build-index/catalog.lua` already lists `03-variables-scope`.

**Tech Stack:** Lua 5.4 (`.lua/bin/lua`), `busted`, `luacheck`, reveal.js slides, GNU Make.

**Spec:** `docs/superpowers/specs/2026-09-18-lesson-03-variables-scope-design.md`

## Global Constraints

- **Lua 5.4** (PUC-Rio, via `.lua/`); `luacheck` `std = "lua54"` is the only static gate.
- **Prerequisite ceiling:** students have done Lessons 01–02 only. Graded solution code may use: functions/modules (L01), `..`, `type`/`math.type`/`tostring`/`tonumber` and truthiness (L02), and basic `+`. It must NOT use control flow (L05), multiple return values or varargs (L06), tables as data structures (L08), metatables (L10) or `_ENV`/`_G` (L18). `setmetatable`/`loadfile`/`_G` appear ONLY in the spec's commented test-plumbing helper.
- **Four-file lesson convention:** `README.md`, `slides/`, `exercises/`, `solutions/`; the spec file is byte-identical in `exercises/` and `solutions/`.
- **Module name:** `scope` (files `scope.lua`, `scope_spec.lua`); graded function `next_fib`.
- **`<const>` is taught, never graded** — it must not appear in `solutions/scope.lua`.
- **No harness edits:** no changes to `Makefile`, `.luacheckrc`, `tools/`, `shared/`.
- **Definition of done for the lesson:** `make test-lesson LESSON=03-variables-scope` passes AND `make lint` is clean.
- **Em dashes in prose** (`—`) and the `·` separator in catalog blurbs match the existing lessons; keep the house voice (short, second person, no exclamation marks).

---

## Context for the implementer

- **Working directory:** `/Users/ristkari/code/private/lua-training/`. **Branch:** `lesson-03-variables-scope` (already checked out, off merged `main`, which has Plans A + B, the CI fix, and Lessons 01, 02, 05). The design doc is already committed on this branch. Commit here; do NOT push.
- **Toolchain present:** the gitignored `.lua/` tree already exists. Use `.lua/bin/lua`, `.lua/bin/busted`, `.lua/bin/luacheck`, or the `make` targets. Do NOT run `make bootstrap`.
- **Read for house style before writing prose:** `lessons/02-values-types/README.md` and `lessons/05-control-flow/slides/slides.md`.
- **Scratch dir for throwaway files (mistake injection):** `/private/tmp/claude-501/-Users-ristkari-code-private-lua-training/f282ee64-4464-42c2-be99-69487673f9f6/scratchpad/l03-impl/`. Nothing there is ever committed.
- **Why the spec has a sandbox loader:** a `require`-based spec loads the module once per process, so this lesson would need a `reset()` helper AND a global-state solution would still pass. The loader gives per-test isolation and makes "creates no global variables" a real test. This is a Lesson 03 one-off; later lessons keep the house header.
- **`make test-lesson` output is expected to be noisy:** the `exercises/` run fails by design (3 errors), then the `solutions/` run passes (3 successes); the target exits 0.

## File Structure

```
lessons/03-variables-scope/             (scaffolded, then hand-authored)
├── README.md                           (Task 2 — rewritten)
├── slides/
│   ├── index.html                      (from scaffold; title already "Lesson 03 — Variables & scope")
│   ├── slides.md                       (Task 2 — rewritten, 11 slides)
│   └── assets/.gitkeep                 (from scaffold, unchanged)
├── exercises/
│   ├── scope.lua                       (Task 1 — next_fib stub; renamed from main.lua)
│   └── scope_spec.lua                  (Task 1 — failing spec)
└── solutions/
    ├── scope.lua                       (Task 1 — next_fib implemented)
    └── scope_spec.lua                  (Task 1 — identical spec, passes)
```

No `Makefile`/`.luacheckrc`/`tools/` changes.

---

## Task 1: Scaffold and author the `next_fib` exercise + solution

**Files:**
- Create (via scaffold, then rename/rewrite): `lessons/03-variables-scope/exercises/scope.lua`, `lessons/03-variables-scope/exercises/scope_spec.lua`, `lessons/03-variables-scope/solutions/scope.lua`, `lessons/03-variables-scope/solutions/scope_spec.lua`
- Also created by the scaffold (left for Task 2): `lessons/03-variables-scope/README.md`, `lessons/03-variables-scope/slides/index.html`, `lessons/03-variables-scope/slides/slides.md`, `lessons/03-variables-scope/slides/assets/.gitkeep`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: module `scope` returning a table with one function, `scope.next_fib()` → integer. Successive calls return 1, 1, 2, 3, 5, 8, … The module must create no global variables. Task 2's README and slides quote this function name and the commands below.

- [ ] **Step 1: Scaffold the lesson**

Run: `make new-lesson NAME=03-variables-scope`
Expected: prints `created lessons/03-variables-scope`, with `README.md`, `slides/{index.html,slides.md,assets/.gitkeep}`, `exercises/{main.lua,main_spec.lua}`, `solutions/{main.lua,main_spec.lua}`.

- [ ] **Step 2: Rename the template's `main`→`scope` in both dirs**

```bash
mv lessons/03-variables-scope/exercises/main.lua      lessons/03-variables-scope/exercises/scope.lua
mv lessons/03-variables-scope/exercises/main_spec.lua lessons/03-variables-scope/exercises/scope_spec.lua
mv lessons/03-variables-scope/solutions/main.lua      lessons/03-variables-scope/solutions/scope.lua
mv lessons/03-variables-scope/solutions/main_spec.lua lessons/03-variables-scope/solutions/scope_spec.lua
```

- [ ] **Step 3: Write the failing spec (`exercises/scope_spec.lua`)**

Overwrite `lessons/03-variables-scope/exercises/scope_spec.lua` with EXACTLY:

```lua
local here = debug.getinfo(1, "S").source:match("^@(.*/)")

-- Test plumbing (you don't need to follow this until Lessons 10 and 18).
-- Each test loads a brand-new copy of scope.lua with its own stand-in for the
-- global table: reading a global (like `error`) still works, but any global the
-- module *creates* lands in `globals`, where the last test can see it.
-- A syntax error in scope.lua is reported at the loadfile line below.
local function load_scope()
  local globals = setmetatable({}, { __index = _G })
  local scope = assert(loadfile(here .. "scope.lua", "t", globals))()
  return scope, globals
end

describe("next_fib", function()
  it("starts the sequence at 1", function()
    local scope = load_scope()
    assert.are.equal(1, scope.next_fib())
  end)

  it("walks 1, 1, 2, 3, 5, 8", function()
    local scope = load_scope()
    assert.are.equal(1, scope.next_fib())
    assert.are.equal(1, scope.next_fib())
    assert.are.equal(2, scope.next_fib())
    assert.are.equal(3, scope.next_fib())
    assert.are.equal(5, scope.next_fib())
    assert.are.equal(8, scope.next_fib())
  end)

  it("creates no global variables", function()
    local scope, globals = load_scope()
    scope.next_fib()
    scope.next_fib()
    assert.are.same({}, globals) -- a leak prints as { *[name] = value }
  end)
end)
```

- [ ] **Step 4: Write the stub (`exercises/scope.lua`)**

Overwrite `lessons/03-variables-scope/exercises/scope.lua` with EXACTLY:

```lua
local M = {}

function M.next_fib()
  error("TODO: implement next_fib so the tests pass")
end

return M
```

- [ ] **Step 5: Run the exercise spec to verify it fails**

Run: `.lua/bin/busted lessons/03-variables-scope/exercises`
Expected: `0 successes / 0 failures / 3 errors`, each error reading `TODO: implement next_fib so the tests pass`. Exit code 1.

- [ ] **Step 6: Copy the spec into `solutions/` (byte-identical)**

```bash
cp lessons/03-variables-scope/exercises/scope_spec.lua lessons/03-variables-scope/solutions/scope_spec.lua
diff lessons/03-variables-scope/exercises/scope_spec.lua lessons/03-variables-scope/solutions/scope_spec.lua && echo "specs identical"
```
Expected: `specs identical`.

- [ ] **Step 7: Write the reference solution (`solutions/scope.lua`)**

Overwrite `lessons/03-variables-scope/solutions/scope.lua` with EXACTLY:

```lua
local M = {}

local current, upcoming = 0, 1

function M.next_fib()
  current, upcoming = upcoming, current + upcoming
  return current
end

return M
```

- [ ] **Step 8: Run the solution spec to verify it passes**

Run: `.lua/bin/busted lessons/03-variables-scope/solutions`
Expected: `3 successes / 0 failures / 0 errors`. Exit code 0.

- [ ] **Step 9: Verify the spec catches the three scope mistakes**

These are throwaway copies in the scratch dir — never commit them. Run:

```bash
SCRATCH=/private/tmp/claude-501/-Users-ristkari-code-private-lua-training/f282ee64-4464-42c2-be99-69487673f9f6/scratchpad/l03-impl
rm -rf "$SCRATCH" && mkdir -p "$SCRATCH"/{narrow,wide,sequential}
for d in narrow wide sequential; do
  cp lessons/03-variables-scope/solutions/scope_spec.lua "$SCRATCH/$d/scope_spec.lua"
done

# too narrow: state declared inside the function
cat > "$SCRATCH/narrow/scope.lua" <<'LUA'
local M = {}

function M.next_fib()
  local current, upcoming = 0, 1
  current, upcoming = upcoming, current + upcoming
  return current
end

return M
LUA

# too wide: no `local`, so the state is global
cat > "$SCRATCH/wide/scope.lua" <<'LUA'
local M = {}

current, upcoming = 0, 1

function M.next_fib()
  current, upcoming = upcoming, current + upcoming
  return current
end

return M
LUA

# one variable at a time instead of a multiple assignment
cat > "$SCRATCH/sequential/scope.lua" <<'LUA'
local M = {}

local current, upcoming = 0, 1

function M.next_fib()
  current = upcoming
  upcoming = current + upcoming
  return current
end

return M
LUA

for d in narrow wide sequential; do
  echo "== $d =="
  .lua/bin/busted "$SCRATCH/$d" 2>&1 | tail -n 20 | grep -E "successes|Failure|Expected|Passed in" | head -n 6
done
```

Expected: every directory reports at least one failure.
- `narrow` → "walks 1, 1, 2, 3, 5, 8" fails (it returns 1 every call).
- `wide` → "creates no global variables" fails, printing the leaked names (e.g. `{ *[current] = 1, *[upcoming] = 1 }`).
- `sequential` → the sequence test fails (it yields 1, 2, 4).

If any directory reports `3 successes`, STOP — the spec does not grade the lesson and the plan's author must be told.

- [ ] **Step 10: Clean up the scratch copies**

```bash
rm -rf /private/tmp/claude-501/-Users-ristkari-code-private-lua-training/f282ee64-4464-42c2-be99-69487673f9f6/scratchpad/l03-impl
git status --porcelain lessons/03-variables-scope
```
Expected: only files under `lessons/03-variables-scope/` are listed as untracked.

- [ ] **Step 11: Lint the new lesson**

Run: `.lua/bin/luacheck --config .luacheckrc lessons/03-variables-scope`
Expected: `0 warnings / 0 errors in 4 files`.

- [ ] **Step 12: Both specs through the make target**

Run: `make test-lesson LESSON=03-variables-scope`
Expected: the `exercises/` run reports 3 errors (by design), the `solutions/` run reports `3 successes`, and the target exits 0.

- [ ] **Step 13: Commit**

```bash
git add lessons/03-variables-scope/exercises lessons/03-variables-scope/solutions
git commit -m "feat(lesson-03): add next_fib exercise + solution with busted specs"
```

(The scaffolded `README.md` and `slides/` stay untracked until Task 2.)

---

## Task 2: Author the README and the slide deck

**Files:**
- Modify (rewrite the scaffold placeholders): `lessons/03-variables-scope/README.md`, `lessons/03-variables-scope/slides/slides.md`
- Verify only (no edit expected): `lessons/03-variables-scope/slides/index.html`

**Interfaces:**
- Consumes: `scope.next_fib()` from Task 1, and the commands `make test-lesson LESSON=03-variables-scope` and `make lint`.
- Produces: prose only; nothing later depends on it except the final verification in Task 3.

- [ ] **Step 1: Check the deck bootstrap already carries the right title**

Run: `grep '<title>' lessons/03-variables-scope/slides/index.html`
Expected: `<title>Lesson 03 — Variables & scope</title>` (the scaffold fills this from `tools/build-index/catalog.lua`). If it differs, edit that one line to match exactly and note it in the task report.

- [ ] **Step 2: Write `slides/slides.md`**

Overwrite `lessons/03-variables-scope/slides/slides.md` with EXACTLY:

````markdown
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

luacheck: `shadowing upvalue n on line 1`

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
````

- [ ] **Step 3: Write `README.md`**

Overwrite `lessons/03-variables-scope/README.md` with EXACTLY:

````markdown
# Lesson 03 — Variables & scope

Where a variable lives decides who can see it and how long it lasts. You will
implement `next_fib()`, whose state only works at the right scope.

## Learning goals

- Declare variables with `local`, and explain why an assignment without one creates a global
- Say where a local is visible: its block, a function body, or the whole file (a chunk)
- Recognize shadowing — declaring a new variable instead of assigning to the outer one
- Mark a never-changing local `<const>` (a 5.4 attribute)
- Use multiple assignment, including the swap `a, b = b, a`
- Implement `next_fib()` to make a failing `busted` spec pass

## Prereqs

- Lessons 01–02. Toolchain via `make bootstrap`. (`+` is the only operator used here;
  operators proper are Lesson 04.)

## Concepts

**Globals by default.** An assignment without `local` creates a global, shared by
every chunk in the program. That costs twice: a typo (`countr`) reads as `nil`
instead of failing, and any other file that picks the same name overwrites yours.
`make lint` reports one as `setting non-standard global variable 'count'`.

**`local` and blocks.** A local is visible from its declaration to the end of its
block — a `do … end`, a function body, or the whole file (a chunk). When the block
ends, the variable is gone: `do local secret = 42 end; print(secret)` prints `nil`.
A local declared at the top of a file is private to that file yet stays alive
between calls, which is how a module keeps state without a single global.

**Declaring vs assigning.** Inside a block, `local n = n + 1` declares a *new* `n`
that hides the outer one; `n = n + 1` updates the outer one. luacheck warns about
the first as `shadowing upvalue n` ("upvalue" means a local from an enclosing
scope — Lesson 15 tells the full story).

**`<const>`.** Lua 5.4 lets you mark a local that never changes:
`local LIMIT <const> = 10`. Assigning to it is an error when the file loads —
`attempt to assign to const variable 'LIMIT'`. Each name needs its own attribute:
in `local a <const>, b = 1, 2`, only `a` is const. luacheck does not catch this;
Lua does.

**Multiple assignment.** `local a, b = 1, 2` declares two variables at once, and
`a, b = b, a` swaps them with no temporary, because Lua works out every value on
the right before it assigns any of them. Missing values become `nil`, and extra
ones are dropped.

## Exercise brief

Implement `next_fib()` in `exercises/scope.lua`. Each call returns the next
Fibonacci number — 1, 1, 2, 3, 5, 8, … — where each number is the sum of the two
before it.

The two numbers it needs have to survive from one call to the next. Where you
declare them is the whole exercise: inside the function they reset every call, and
as globals they are exposed to the rest of the program. All three examples in
`exercises/scope_spec.lua` must pass.

You are done when `make test-lesson LESSON=03-variables-scope` passes **and**
`make lint` is clean.

The `load_scope` helper at the top of the spec is test plumbing: it gives each
example a fresh copy of your module and watches for globals. You do not need to
follow it yet — Lessons 10 and 18 cover the pieces.

## How to run

```bash
make test-lesson LESSON=03-variables-scope
make lint
```

Explore in the REPL (from the lesson's `solutions/` directory so `require` finds
the file):

```bash
cd lessons/03-variables-scope/solutions
../../../.lua/bin/lua -e 'local s = require("scope"); print(s.next_fib(), s.next_fib(), s.next_fib())'
```

## Going further

- `local f <close> = …` (5.4) closes a value when its block ends; it needs a metatable, so it waits for Lesson 10.
- Globals really live in a table called `_G`: `_G.count` and `count` are the same variable (Lesson 18).
- `local function f() … end` lets `f` call itself; `local f = function() … end` does not, because `f` is not in scope yet inside the body (Lesson 06).
````

- [ ] **Step 4: Render the deck locally**

```bash
make slides-dev LESSON=03-variables-scope &
sleep 2
curl -s http://127.0.0.1:8000/ | grep -o "<title>[^<]*</title>"
curl -s -o /dev/null -w "slidesmd=%{http_code}\n" http://127.0.0.1:8000/slides.md
pkill -f "slides-dev/main.lua"
```
Expected: `<title>Lesson 03 — Variables & scope</title>` and `slidesmd=200`.

- [ ] **Step 5: Check the deck has eleven slides**

Run: `grep -c '^---$' lessons/03-variables-scope/slides/slides.md`
Expected: `10` (eleven slides separated by ten `---` lines).

- [ ] **Step 6: Commit**

```bash
git add lessons/03-variables-scope/README.md lessons/03-variables-scope/slides
git commit -m "docs(lesson-03): author the README and slide deck"
```

---

## Task 3: Final verification

No files change in this task — it confirms the lesson is integrated. (Commit only if a step surfaces something to tidy.)

- [ ] **Step 1: Lint the whole repo**

Run: `make lint`
Expected: `0 warnings / 0 errors`. (The stub's `next_fib` takes no arguments, so `unused_args` does not come into it.)

- [ ] **Step 2: Full test suite**

Run: `make test`
Expected: `busted tools` → `42 successes`; `== lessons/01-hello/solutions ==` → `2`; `== lessons/02-values-types/solutions ==` → `6`; `== lessons/03-variables-scope/solutions ==` → `3`; `== lessons/05-control-flow/solutions ==` → `5`. Exit 0.

If the tools run fails with `File exists` from `tools/slides-dev/spec/server_spec.lua`, that is a known pre-existing flake (temp directory names come from `os.time()`, so two runs in the same second collide). Wait a second, re-run, and note it in the task report — do not fix it here.

- [ ] **Step 3: Static build publishes the lesson as a link**

```bash
make slides-build
grep -q '<a class="lesson" href="lessons/03-variables-scope/slides/">' dist/index.html && echo "03 is a link"
grep -c 'class="lesson future"' dist/index.html   # expect 19 (23 total minus 01+02+03+05)
grep -o "<title>[^<]*</title>" dist/lessons/03-variables-scope/slides/index.html
rm -rf dist
```
Expected: `03 is a link`, `19`, `<title>Lesson 03 — Variables & scope</title>`.

- [ ] **Step 4: Formatting matches StyLua (only if StyLua is installed)**

```bash
command -v stylua >/dev/null && stylua --check lessons/03-variables-scope || echo "stylua not installed — skipped"
```
Expected: no output from `--check` (or the skip message). If it reports diffs, run `make fmt`, re-run Task 1 Step 8 and Step 11, and amend the Task 1 commit.

- [ ] **Step 5: Clean check**

Run: `git status --porcelain`
Expected: empty (no `dist/`, no scratch files, no lingering `slides-dev` server — if one lingers, `pkill -f "slides-dev/main.lua"`).

---

## Self-review notes (run before reporting overall)

- `make test-lesson LESSON=03-variables-scope` → exercises error (3), solutions pass (3), exit 0.
- Mistake injection (Task 1 Step 9) → all three wrong solutions fail.
- `make test` → 42 + 2 + 6 + 3 + 5.
- `make lint` → 0/0.
- `make slides-build` → `03-variables-scope` is a link; 19 future placeholders; deck title "Lesson 03 — Variables & scope".
- No tool/Makefile/.luacheckrc changes; `solutions/scope.lua` uses no `<const>`, no control flow, no multiple returns.
- Specs byte-identical between `exercises/` and `solutions/`.

## Notes for execution

- No `git push`, no `gcloud`, no `make bootstrap`.
- The exercise spec failing is the deliverable; `make test` runs only `solutions/`.
- Two commits are expected: `feat(lesson-03): …` (Task 1) and `docs(lesson-03): …` (Task 2).
- End commit messages with:
  `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`
- After this plan, the lesson is ready for a PR titled "Lesson 03 — Variables & scope"; Lesson 04 (Operators & expressions) is a future plan.
