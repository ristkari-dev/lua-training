# Lesson 03 — Variables & scope — Design

**Status:** Approved (brainstorming complete, awaiting implementation plan)
**Date:** 2026-09-18
**Owner:** Aki Ristkari

## Summary

The third course lesson by number, authored after Lessons 01, 02 and 05. Lesson 03
("Variables & scope") is where students learn to decide *where a variable lives*:
`local` versus global (and why a global is dangerous), the block/chunk rules that
say how long a local is visible, the `local x <const>` attribute new in 5.4, and
multiple assignment including the temporary-free swap `a, b = b, a`.

The exercise is a **Fibonacci stepper**: `next_fib()` returns the next number in
the sequence (1, 1, 2, 3, 5, 8, …) on each call. Its whole solution is two lines —
`local current, upcoming = 0, 1` at the top of the chunk, and
`current, upcoming = upcoming, current + upcoming` inside the function — and every
scope mistake breaks a test:

- locals declared **inside** the function (too narrow) → returns 1 forever;
- **no `local`** (too wide) → the "creates no global variables" test fails, whatever
  the variables are named, and `make lint` warns as well;
- **one variable at a time** (`current = upcoming; upcoming = current + upcoming`) →
  yields 1, 2, 4 and fails, demonstrating that a multiple assignment evaluates the
  entire right-hand side before it assigns anything.

The exercise was chosen by a design panel: five candidate exercises were built and
verified (busted + luacheck + mistake injection), then scored by three judges
(beginner pedagogy, topic fit/elegance, technical robustness). Two of the three
independently converged on this combination — the Fibonacci step graded through a
per-test sandboxed loader.

No harness change is needed: `make lint`/`make fmt` already cover `lessons/`,
`make test` already loops lesson `solutions/`, and `tools/build-index/catalog.lua`
already lists `03-variables-scope`. This lesson only adds `lessons/03-variables-scope/`.

## Learning goals

1. Declare variables with `local`, and explain why an assignment without `local`
   creates a global — and why globals are dangerous (typos read as `nil`, and any
   other chunk can overwrite the name).
2. State where a local is visible: from its declaration to the end of its block —
   a `do … end`, a function body, or the whole file (a chunk) — and recognize
   shadowing (declaring vs assigning).
3. Mark a never-changing local with `<const>` (5.4), and recognize the load-time
   error when something assigns to it.
4. Use multiple assignment, including the swap `a, b = b, a`, knowing that Lua
   evaluates every right-hand value before assigning any of them.
5. Implement `next_fib` — keeping its state at the right scope — to make a failing
   `busted` spec pass.

## Files

Lesson directory `lessons/03-variables-scope/` (scaffolded via
`make new-lesson NAME=03-variables-scope`, then hand-authored). Rename the
template's `main`→**`scope`**; the exercise function is `next_fib`, so calls read
`scope.next_fib()`.

```
lessons/03-variables-scope/
├── README.md
├── slides/
│   ├── index.html          # reveal bootstrap (from scaffold; deck title authored to "Variables & scope")
│   ├── slides.md           # the deck (authored)
│   └── assets/.gitkeep
├── exercises/
│   ├── scope.lua           # next_fib() stub (errors)
│   └── scope_spec.lua      # failing spec
└── solutions/
    ├── scope.lua           # next_fib() implemented
    └── scope_spec.lua      # identical spec, passes
```

### `exercises/scope.lua`

```lua
local M = {}

function M.next_fib()
  error("TODO: implement next_fib so the tests pass")
end

return M
```

### `exercises/scope_spec.lua`

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

### `solutions/scope.lua`

```lua
local M = {}

local current, upcoming = 0, 1

function M.next_fib()
  current, upcoming = upcoming, current + upcoming
  return current
end

return M
```

### `solutions/scope_spec.lua`

Identical to `exercises/scope_spec.lua`. Each `it` loads its own fresh copy of
`scope.lua`, so the two specs never share state and neither depends on test order.

### Why this shape

The only decisions in the solution are *where the two numbers are declared* and
*how they are stepped* — which is exactly the lesson:

- **Too narrow** — `local current, upcoming = 0, 1` inside `next_fib` re-initialises
  on every call, so the function returns 1 forever and "walks 1, 1, 2, 3, 5, 8" fails.
- **Too wide** — dropping `local` puts the state in the global table; the
  "creates no global variables" test fails and prints the offending names
  (`{ *[current] = 1  [upcoming] = 2 }` — only the first differing key carries the
  `*`), whatever they are called, and `make lint` reports "setting non-standard
  global variable".
- **Just right** — declared at the top of the chunk, the locals are invisible
  outside the file yet keep their values between calls.
- **Right-hand side first** — `current = upcoming; upcoming = current + upcoming`
  yields 1, 2, 4 and fails, which is the evidence for the swap idiom on the slides.

### Why the spec departs from the house header

Lessons 01, 02 and 05 open their specs with the `package.path` + `require` header.
This lesson deliberately does not. A `require`-based spec loads the module once per
process, so a lesson whose subject *is* mutable module state would need a `reset()`
function (a second graded function whose only real job is test isolation, and whose
TODO masks the real one in the stub), and would still leave the headline topic
ungraded: a global-state solution passes a `require`-based spec, with only `make lint`
objecting.

The cost is four lines of plumbing using `setmetatable` (L10) and `loadfile` with an
environment (L18). Students read but never write them, and the comment labels them as
magic — the same treatment the course already gives busted's internals. **This is a
one-off for Lesson 03; later lessons keep the standard `require` header** unless they
have the same reason.

### `<const>` is taught, not graded

No behavioral test can require `<const>`: a solution without it passes. luacheck 1.2.0
does not flag assignment to a const either (verified) — only Lua does, at load time
("attempt to assign to const variable 'LIMIT'"). It therefore appears on a slide and in
the README, with the error message shown, and the graded solution does not use it.

## Slides (`slides/slides.md`)

~10 slides, `---`-separated, fenced ` ```lua ` blocks, `Note:` where useful.

1. **Title** — "Lesson 03 — Variables & scope" + one-line goal (decide where each
   variable lives).
2. **Globals by default** — `count = 0` without `local` creates a global; a typo
   (`print(countr)`) reads as `nil` silently; any other chunk can overwrite the name
   (demo: another file sets `current = 99` and the sequence breaks).
3. **`local`** — visible from its declaration to the end of its block; the house rule
   is always `local`; `make lint` catches a missing one
   ("setting non-standard global variable").
4. **Blocks and chunks** — a file is a chunk; `do … end` and function bodies are
   blocks; a local dies at its block's `end`
   (`do local secret = 42 end; print(secret)` → `nil`).
5. **Shadowing: declaring vs assigning** — an inner `local x` hides the outer one;
   `local x = x + 1` makes a new variable while `x = x + 1` updates the existing one;
   luacheck says "shadowing definition of variable".
6. **Chunk-level locals keep state** — `local M = {}` from L01 is already one;
   functions declared below a local can see it, and it keeps its value across calls.
7. **`<const>` (5.4)** — `local LIMIT <const> = 10`; assigning to it fails at load
   time with "attempt to assign to const variable 'LIMIT'"; each name needs its own
   attribute (`local a <const>, b = 1, 2` makes only `a` const); luacheck does not
   catch this — Lua does.
8. **Multiple assignment & swap** — `local a, b = 1, 2`; `a, b = b, a` needs no temp;
   the whole right-hand side is evaluated first; extra values are discarded and
   missing ones become `nil` (`local x, y, z = 1, 2` → `z` is `nil`).
9. **The exercise** — too narrow / too wide / just right; the stepping line
   `current, upcoming = upcoming, current + upcoming`;
   `make test-lesson LESSON=03-variables-scope` **and** `make lint`.
10. **What's next** — pointer to Lesson 04 (Operators & expressions).

## README (`README.md`)

Four-file convention sections:

- **Learning goals** — the five bullets above.
- **Prereqs** — Lessons 01–02; toolchain via `make bootstrap`. (`+` is the only
  operator used; operators proper are Lesson 04.)
- **Concepts** — short paragraphs mirroring the deck: globals by default and their
  dangers; `local` and block/chunk visibility; shadowing (declaring vs assigning);
  chunk-level locals as private state that survives between calls; `<const>`;
  multiple assignment and the swap.
- **Exercise brief** — implement `next_fib()` in `exercises/scope.lua` so successive
  calls return 1, 1, 2, 3, 5, 8, …; each number is the sum of the previous two.
  Hint: the last two numbers must survive between calls — where do they live?
  **Definition of done: `make test-lesson` passes AND `make lint` is clean.**
  One sentence notes that the loader at the top of the spec is test plumbing they do
  not need to follow yet.
- **How to run** — `make test-lesson LESSON=03-variables-scope`; REPL exploration from
  `solutions/`
  (`local s = require("scope"); print(s.next_fib(), s.next_fib(), s.next_fib())` → `1 1 2`).
- **Going further** (light, no new graded work) — the `<close>` attribute (5.4) exists
  but needs metatables (L10), so `<close>` itself waits for L13; globals live in the
  table `_G` (L18); `local function f` vs `local f = function` and what that means for
  recursion (L06).

## Verification (success criteria)

- `make test-lesson LESSON=03-variables-scope` → exercise spec FAILS (3 `TODO`
  errors), solution spec PASSES (3 examples), target exit 0.
- **Mistake injection** (scratch dir only, never committed) — the solution spec must
  FAIL for each of: a missing `local`; locals declared inside `next_fib`; stepping one
  variable at a time.
- `make test` → tools + `01-hello` (2) + `02-values-types` (6) + `03-variables-scope`
  (3) + `05-control-flow` (5), in isolated per-lesson processes.
- `make lint` → clean, covering the new lesson.
- `make slides-build` → `dist/index.html` shows `03-variables-scope` as a **link**
  (19 future placeholders remain); `dist/lessons/03-variables-scope/slides/index.html`
  `<title>` is "Lesson 03 — Variables & scope".
- `make slides-dev LESSON=03-variables-scope` → the deck renders.
- CI on the PR is green.

## Non-goals

- Operator mechanics are Lesson 04; `+` is used as an already-known tool.
- No control flow (Lesson 05) — the spec repeats calls instead of looping.
- No multiple **return** values (Lesson 06); the lesson grades multiple *assignment*
  only.
- `<const>` and `<close>` are taught, not graded; `_G`/`_ENV` (L18), metatables (L10)
  and closures/upvalues (L15) are named at most in passing — chunk-level locals are
  framed as lexical visibility, not as closures.
- No changes to the tools, Makefile or `.luacheckrc`.
- The spec's sandbox loader is a Lesson 03 one-off, not a new house pattern.

## Open items deferred to implementation planning

- Exact wording/voice of the slide prose and README concept paragraphs.
- Whether slide 2's "another chunk overwrites your global" demo is written as a REPL
  transcript or as two small files (default: REPL transcript, to stay short).

## Noticed, out of scope for this lesson

- `tools/slides-dev/spec/server_spec.lua` builds temp directory names from `os.time()`,
  so two `make test` runs within the same second fail with "File exists" — a
  pre-existing flaky tool test, worth its own PR.
- The Lesson 02 design doc's non-goals still call Lesson 03 "Control flow", from before
  the renumbering. Historical; left as-is.
