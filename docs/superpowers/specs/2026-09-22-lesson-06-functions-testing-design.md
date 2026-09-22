# Lesson 06 — Functions & testing — Design

**Status:** Approved (brainstorming complete, awaiting implementation plan)
**Date:** 2026-09-22
**Owner:** Aki Ristkari

## Summary

The sixth lesson, and the first with a complete toolkit behind it: students have had
control flow since Lesson 05, so the graded solution can finally use a loop. Lesson 06
covers multiple return values, varargs (`...`), `select`, default-argument idioms and
functions as first-class values — and it is where **`busted` stops being magic**:
`describe`/`it`/`assert`, `before_each` and spies get taught properly, after five
lessons of "you don't need to follow this yet".

The exercise is `tally(check, ...)`, which answers with two numbers — how many values
passed the check, and how many failed:

```lua
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
```

Nine lines carrying five clauses of the curriculum line: `...` holds the values,
`select("#", ...)` counts them **including trailing nils**, `select(i, ...)` reaches
one, the inner parentheses truncate it to exactly one argument, `check` is a function
received as a value, `check = check or truthy` is the default-argument idiom, and
`return passed, failed` is multiple returns.

The exercise came from a design panel: six candidates — one per sub-topic plus a free
choice — were built, verified and mistake-injected, then scored by three judges. The
two strongest independently converged on the same `tally` shape, and the judges then
broke both. This design is the synthesis, with every fix they converged on applied and
re-verified (see Verification).

No harness change is needed: `make lint`/`make fmt` already cover `lessons/`,
`make test` already loops lesson `solutions/`, and `tools/build-index/catalog.lua`
already lists `06-functions-testing`. Since PR #9, `make new-lesson` also takes the
deck title from that catalog, so this is the first lesson whose scaffolded
`<title>` needs no hand-fix.

## Learning goals

1. Return more than one value, and know that the **caller** decides how many to keep:
   missing values become `nil`, extra ones are dropped.
2. Know where a call is adjusted to one value — in the middle of an argument list, in
   parentheses `(f())`, and on the right of a single-name assignment — and where it
   expands (last in a list).
3. Accept any number of arguments with `...`, count them with `select("#", ...)`
   (trailing `nil`s included), and reach one with `select(i, ...)`.
4. Pass a function as an argument and call it — functions are values.
5. Supply a default with `name = name or fallback`, knowing it is safe for `0` but not
   for `false`.
6. Read a `busted` spec: `describe`/`it`/`assert`, what `before_each` is for, and what
   a spy records.
7. Implement `tally(check, ...)` to make a failing spec pass.

## Files

Lesson directory `lessons/06-functions-testing/` (scaffolded via
`make new-lesson NAME=06-functions-testing`, then hand-authored). Rename the
template's `main`→**`functions`**; the exercise function is `tally`, so calls read
`functions.tally(check, ...)`.

```
lessons/06-functions-testing/
├── README.md
├── slides/
│   ├── index.html          # reveal bootstrap; since PR #9 the scaffold writes the
│   │                       #   correct escaped title — verify, do not hand-edit
│   ├── slides.md           # the deck (authored, 14 slides)
│   └── assets/.gitkeep
├── exercises/
│   ├── functions.lua       # tally() stub (errors)
│   └── functions_spec.lua  # failing spec
└── solutions/
    ├── functions.lua       # tally() implemented
    └── functions_spec.lua  # identical spec, passes
```

The spec uses the house `package.path` + `require` header (Lesson 03's sandboxed
loader remains a one-off).

### `exercises/functions.lua`

```lua
local M = {}

function M.tally(check, ...)
  error("TODO: implement tally so the tests pass")
end

return M
```

### `exercises/functions_spec.lua`

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

### `solutions/functions.lua`

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

### `solutions/functions_spec.lua`

Identical to `exercises/functions_spec.lua`.

### Why this shape, and what each fix closes

The panel's two strongest candidates both landed on `tally`; the judges then found
holes in each, and every fix below was applied and re-verified before this spec was
written:

- **`passed, failed`, not `passed, total`.** With `total`, a solution that skips the
  check for `nil` arguments passes every test (the judges verified 8/8). With
  `failed`, every value must be judged, and skipping nils fails two tests.
- **Ten values in one test.** With a widest call of four or five, a positional unroll
  (`local a, b, c, d, e = ...` plus `if n >= k` dispatch) passes — it was a dodge
  against *every* proposal in the panel. Ten values price it out.
- **The reference writes `check((select(i, ...)))`.** Writing
  `local value = select(i, ...)` truncates just as well, but then the student who
  gets it *right* never meets the parenthesis rule — only the student who gets it
  wrong does. The explicit form puts the idiom in the code students are shown; the
  README gives the assignment form as the alternative.
- **A nil-safe default check.** In the panel's version the trailing-`nil` test relied
  on the default idiom, because a spy wrapping `value % 2 == 0` errors on `nil`. The
  two sharpest tests now stand independently.
- **An exact-arity assertion** (`select("#", functions.tally(nil, 1, 2))` is `2`),
  which is the only test that catches a helpfully-returned third value.
- **Spy tests in a nested `describe`** with its own `before_each`, separating "what it
  returns" from "how it calls" and teaching scoped setup for free.
- **A closing test with no spy at all** — a hand-written recorder asserting
  `"a|nil|b|"`. Two lines saying *a spy is just a function that keeps notes*, which is
  the demystification this lesson is named for.

### The `table.pack` dodge

`table.pack(...)` with `values.n` passes all nine tests. `table.pack` records the true
count in `.n`, so unlike plain `{...}` it survives the trailing-`nil` test, and no
behavioural spec can distinguish it. The exercise brief therefore bans it by name,
exactly as Lesson 04 bans `math.ceil`: **varargs only — no `{...}`, no `table.pack`
(both Lesson 08); `table.pack(...).n` gives the same answer and the tests cannot tell,
but `select("#", ...)` is the point of this lesson.**

Note that plain `{...}` + `#` does **not** pass — it misses the trailing `nil` — so
the only table route that works is the one that has already understood the lesson's
central fact: the argument count is a separate piece of information from the values.

### Nine examples, against a house norm of two to six

Deliberate. This lesson grades two halves — the function topics and the `busted`
machinery — and it is the first spec students are meant to *read* as a document rather
than scan as a checklist. The nested `describe` keeps it navigable. Recorded here so a
future reader sees a decision rather than drift.

## Slides (`slides/slides.md`)

14 slides. Every value below was run against the repo's Lua 5.4.4 and busted 2.2.0
before this spec was written.

1. **Title** — "Lesson 06 — Functions & testing"; goal: functions that take and return
   any number of values, and the tests that prove it.
2. **Returning more than one value** — `return passed, failed`; `local a, b = two()`
   → `1  2`; asking two values of a one-value function gives `nil`.
3. **The caller decides how many** — `print(two())` → `1  2`; `print(two(), 9)` →
   `1  9` (cut to one in the middle of a list); `print(9, two())` → `9  1  2`.
4. **Parentheses truncate** — `(two())` is `1`; and `return (a, b)` is a syntax error,
   `')' expected near ','`, because grouping means one value.
5. **Varargs** — `function M.tally(check, ...)`; `...` is the rest of the arguments,
   not a table.
6. **Counting them** — `select("#", 1, nil, nil)` → `3`; `select("#")` → `0`. Counting
   includes trailing `nil`s, which is why `#{...}` cannot do this job (tables arrive
   in Lesson 08).
7. **Reaching one** — `select(2, "a", "b", "c")` → `b  c`: it returns value *i* and
   everything after it, so `check((select(i, ...)))` or
   `local value = select(i, ...)` is what hands over exactly one.
8. **Functions are values** — held in a local, passed as an argument, returned from a
   function; `check` is an ordinary parameter that happens to be callable.
9. **Default arguments** — `check = check or truthy`; safe for `0` (truthy in Lua:
   `0 or "d"` → `0`), unsafe for `false` (`false or "d"` → `"d"`), so
   `if x == nil then x = … end` when `false` is a legitimate value.
10. **busted: describe / it / assert** — the header every lesson has carried since
    Lesson 01, finally explained.
11. **`before_each`** — fresh state per example; share one spy across tests and the
    counts pile up.
12. **Spies** — `spy.new(f)` records calls; `assert.spy(s).was.called(3)`,
    `.was.called_with(5)`, `.was_not.called()`. A spy is a **callable table**, so
    `type(s)` is `"table"` — worth knowing before someone type-checks a callback. A
    spy answers *how* your code was called, which a return value never shows.
13. **The exercise** — `tally`, the contract the spies grade, and
    `make test-lesson LESSON=06-functions-testing`.
14. **What's next** — Lesson 07, the Phase 1 capstone.

## README (`README.md`)

Four-file convention sections:

- **Learning goals** — the seven bullets above.
- **Prereqs** — Lessons 01–05; toolchain via `make bootstrap`.
- **Concepts** — short paragraphs mirroring the deck.
- **Exercise brief** — implement `tally(check, ...)` returning passes then failures.
  States the contract the spy grades: **call `check` once per value, with exactly one
  argument**. Names the truncation bug verbatim: `check(select(i, ...))` hands the
  check the i-th value *and every one after it*; `check((select(i, ...)))` or
  `local value = select(i, ...)` fixes it. Bans `{...}` and `table.pack` by name, with
  the reason above. Definition of done: `make test-lesson` passes **and** `make lint`
  is clean.
- **How to run** — `make test-lesson LESSON=06-functions-testing`; a REPL line from
  `solutions/`; and `make test-lesson … -- --shuffle` as a way to see `before_each`
  earning its keep.
- **Going further** — the recursive peel (`walk(check, select("#", ...), ...)`) as the
  table-free alternative to the loop; `select(-1, ...)` for the last value; and the
  forwarding rule that `f(1, ...)` passes everything while `f(..., 1)` cuts `...` to
  one value.

## Verification (success criteria)

- `make test-lesson LESSON=06-functions-testing` → exercise spec FAILS (9 `TODO`
  errors), solution spec PASSES (9 examples), target exit 0.
- `busted --shuffle` on five seeds → 9/9 each, which is what proves `before_each`
  does its job.
- **Mistake injection** (scratch only, never committed). All eight rows were run
  against this exact spec before it was written; the implementation must reproduce
  them:

  | Wrong solution | Result | Caught by |
  |---|---|---|
  | skips the check for `nil` values | 7 successes / 2 failures | spy call count, and the recorder test |
  | positional unroll (`local a, b, c, d, e = ...`) | 8 / 1 | the ten-value test |
  | `check(select(i, ...))` — spills the tail | 8 / 1 | `called_with` |
  | returns `failed, passed` | 6 / 3 | three value tests |
  | returns a third value as well | 8 / 1 | the arity assertion |
  | no default for `check` | 6 successes / 3 errors | the no-check tests |
  | `{...}` with `#` | 8 / 1 | the trailing-`nil` test |
  | `table.pack(...)` with `.n` | **9 / 0** | nothing — banned in prose |

- `make test` → tools (49) + `01-hello` (2) + `02-values-types` (6) +
  `03-variables-scope` (3) + `04-operators` (6) + `05-control-flow` (5) +
  `06-functions-testing` (9).
- `make lint` → clean.
- `make slides-build` → `dist/index.html` links `06-functions-testing` (17 future
  placeholders remain); the deck's `<title>` is
  `Lesson 06 — Functions &amp; testing`, which the scaffolder now produces without a
  hand-fix.
- `make slides-dev LESSON=06-functions-testing` → the deck renders.
- CI on the PR is green.

## Non-goals

- No tables as data structures or the table library (Lesson 08) — which is exactly
  why `select` carries this lesson.
- No string library (L09), no metatables (L10), no `pcall`/error handling (L13), no
  iterators (L14), no `math`/`os`/`io` (L17).
- Closures stay shallow: `truthy` captures nothing, and returning a function is a
  "Going further" tease. Upvalue mechanics belong to Lesson 15.
- Students **read** a spec but do not write one. Authoring tests is taught by example
  here; grading student-written tests is out of scope for the course's harness.
- `stub` and `mock` are named as the spy's siblings, never used.
- No changes to the tools, Makefile or `.luacheckrc`.
- The `table.pack` dodge is closed in prose, not in the spec.

## Open items deferred to implementation planning

- Exact wording/voice of the slide prose and README concept paragraphs.
- Whether slide 12 shows `#s.calls` (a spy's call record is an ordinary table) or
  keeps to the assertion API (default: keep to the API; the call record is a Lesson 08
  shape).

## Noticed, out of scope for this lesson

- The Deploy workflow has been red on every push to `main` since Plan B because the
  three GCP secrets were unset. They were set on 2026-09-22; the next Deploy run is
  the first that can succeed, and `deploy/README.md` steps 3–5 (service
  materialisation, domain mapping, Cloudflare CNAME) may still be outstanding.
