# Lesson 05 — Control flow — Design

**Status:** Approved (brainstorming complete, awaiting implementation plan)
**Date:** 2026-06-09
**Owner:** Aki Ristkari

## Summary

Authored ahead of Lessons 03–04 (it is Lesson 05 in the curriculum) and built on the merged foundation and Lessons 01–02. Lesson 05 ("Control flow") is the first lesson where students write a real algorithm: branching with `if`/`elseif`/`else` and looping with the numeric `for`. The exercise is the canonical **FizzBuzz** — `fizzbuzz(n)` returns the FizzBuzz lines for `1..n` joined by newlines — which exercises a numeric `for` loop *and* an `if`/`elseif`/`else` ladder in one function. The deck and README also cover `while`, `repeat`/`until`, the generic `for` (a teaser; full treatment in Lesson 08), `break`, and Lua's missing `continue` (and the `goto`/label idiom for it).

No harness change is needed — `make lint`/`make fmt` already cover `lessons/` and `make test` already loops lesson `solutions/` (since Lesson 01).

## Learning goals

1. Branch with `if`/`elseif`/`else`.
2. Loop with the numeric `for` (`for i = 1, n do`), and recognize `while` and `repeat`/`until`.
3. Recognize the generic `for` (`for k, v in pairs(t)`) — a teaser for Lesson 08 — and `break`.
4. Know Lua has no `continue` keyword, and the idioms for it (`if`/`else`, or `goto` a `::continue::` label).
5. Implement `fizzbuzz(n)` to make a failing `busted` spec pass.

## Files

Lesson directory `lessons/05-control-flow/` (scaffolded via `make new-lesson NAME=05-control-flow`, then hand-authored). Rename the template's `main`→**`control_flow`** (matching the slug); the exercise function is `fizzbuzz`, so calls read `control_flow.fizzbuzz(n)`.

```
lessons/05-control-flow/
├── README.md
├── slides/
│   ├── index.html          # reveal bootstrap (from scaffold; deck title authored to "Control flow")
│   ├── slides.md           # the deck (authored)
│   └── assets/.gitkeep
├── exercises/
│   ├── control_flow.lua        # fizzbuzz() stub (errors)
│   └── control_flow_spec.lua   # failing spec
└── solutions/
    ├── control_flow.lua        # fizzbuzz() implemented
    └── control_flow_spec.lua   # identical spec, passes
```

### `exercises/control_flow.lua`

```lua
local M = {}

function M.fizzbuzz(n)
  error("TODO: implement fizzbuzz so the tests pass")
end

return M
```

### `exercises/control_flow_spec.lua`

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

### `solutions/control_flow.lua`

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

### `solutions/control_flow_spec.lua`

Identical to `exercises/control_flow_spec.lua`. `make test` runs `exercises/` and `solutions/` in separate `busted` processes, so the shared module name `control_flow` never collides.

### Notes on the solution

- The order of the `if` ladder matters: `% 15` must be checked **before** `% 3` and `% 5`, or 15 would match "Fizz" first. This is a teaching point about `elseif` order.
- The `if i == 1` guard avoids a leading newline — itself a small control-flow exercise (a conditional inside the loop). Building a string with `..` in a loop is fine at this scale; `table.concat` is the better tool, introduced in Lesson 08.
- `fizzbuzz(0)` returns `""` because `for i = 1, 0` never executes — a useful demonstration that a numeric `for` with `start > stop` runs zero times.

## Slides (`slides/slides.md`)

~9 slides, `---`-separated, fenced ` ```lua ` blocks, `Note:` where useful.

1. **Title** — "Lesson 05 — Control flow" + one-line goal.
2. **`if` / `elseif` / `else`** — the conditional ladder; no parentheses needed; `then`/`end`.
3. **Conditions** — comparison `==`, `~=`, `<`, `<=`, `>`, `>=`; truthiness recap (only `nil`/`false` falsy, from L02).
4. **Numeric `for`** — `for i = 1, n do … end`; optional step `for i = 10, 1, -1`; `start > stop` runs zero times.
5. **`while` and `repeat`/`until`** — top-tested vs bottom-tested; `repeat` runs at least once.
6. **Generic `for` (teaser)** — `for k, v in pairs(t) do` / `for i, v in ipairs(t) do`; full story in Lesson 08.
7. **`break` and the missing `continue`** — `break` exits a loop; Lua has no `continue` — use `if/else`, or `goto` a `::continue::` label at the loop's end.
8. **The exercise** — FizzBuzz: a numeric `for` + an `if`/`elseif`/`else` ladder (check `% 15` first!); `make test-lesson LESSON=05-control-flow`.
9. **What's next** — pointer to Lesson 06 (Functions & testing).

## README (`README.md`)

Four-file convention sections:

- **Learning goals** — the five bullets above.
- **Prereqs** — Lessons 01–02; toolchain via `make bootstrap`.
- **Concepts** — 1–3 short paragraphs mirroring the deck: `if`/`elseif`/`else` + conditions; the three loops (numeric `for`, `while`, `repeat`/`until`) and the generic-`for` teaser; `break` and the no-`continue` idioms; the `% 15`-first ordering point.
- **Exercise brief** — implement `fizzbuzz(n)` in `exercises/control_flow.lua` so all five examples pass; remember to test `% 15` before `% 3`/`% 5`.
- **How to run** — `make test-lesson LESSON=05-control-flow`; REPL exploration from `solutions/` (`print(require("control_flow").fizzbuzz(5))`).
- **Going further** (light) — the `goto ::continue::` idiom; the scope quirk where `repeat`'s `until` can see locals declared in the body; numeric `for` with a fractional/negative step.

## Verification (success criteria)

- `make test-lesson LESSON=05-control-flow` → exercise spec FAILS (`TODO` error, 5 errors), solution spec PASSES (5 examples), exit 0.
- `make test` → tools (42) + `01-hello` (2) + `02-values-types` (6) + `05-control-flow` (5), in isolated per-lesson processes.
- `make lint` → clean, covering the new lesson.
- `make slides-build` → `dist/index.html` shows `05-control-flow` as a **link** (20 future placeholders remain); `dist/lessons/05-control-flow/slides/index.html` `<title>` is "Lesson 05 — Control flow".
- `make slides-dev LESSON=05-control-flow` → the deck renders.
- CI on the PR is green.

## Non-goals

- Operator mechanics are Lesson 04 (which precedes this lesson); `%` and comparisons are used as already-known tools.
- No tables-as-data-structure depth (Lesson 08); the generic `for` is only a teaser (no graded use).
- No `match`/pattern matching — Lua has no `match` statement; `if`/`elseif` is the tool here.
- Only one `fizzbuzz` function — `while`/`repeat`/generic-`for`/`break`/`goto` are taught and demonstrated but not graded.
- No changes to tools or the Makefile/.luacheckrc.

## Open items deferred to implementation planning

- Exact wording/voice of the slide prose and README concept paragraphs.
- Whether the `break`/`continue` slide shows a full `goto ::continue::` loop example or just names the idiom (default: name it + a 3-line example; keep it light since `goto` is rarely the right tool).
