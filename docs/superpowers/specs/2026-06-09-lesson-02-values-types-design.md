# Lesson 02 — Values & types — Design

**Status:** Approved (brainstorming complete, awaiting implementation plan)
**Date:** 2026-06-09
**Owner:** Aki Ristkari

## Summary

The second course lesson, built on the merged foundation (Plans A + B) and Lesson 01. Lesson 02 ("Values & types") introduces Lua's value types and the things you do with them before control flow and operators arrive: the types (`nil`, `boolean`, `number`, `string`, `table`, `function`), the **integer vs float number subtype** new in 5.4 (`math.type`), truthiness (only `nil` and `false` are falsy — so `0` and `""` are truthy), and inspection/conversion via `type`, `tostring`, `tonumber`. Students implement a single `describe(value)` function — `math.type(value) or type(value)` — which ties all three threads (values, the integer/float subtype, and truthiness) into one elegant line.

No harness change is needed: `make lint`/`make fmt` already cover `lessons/` and `make test` already loops lesson `solutions/` (both from Lesson 01). This lesson just adds `lessons/02-values-types/`.

## Learning goals

1. Name Lua's value types: `nil`, `boolean`, `number`, `string`, `table`, `function`.
2. Distinguish the **integer** and **float** number subtypes (5.4) with `math.type`.
3. State Lua's truthiness rule — only `nil` and `false` are falsy — and recognize that `0` and `""` are truthy.
4. Inspect a value with `type` and convert with `tostring`/`tonumber` (and know `tonumber` returns `nil` on failure).
5. Make a failing `busted` spec pass by implementing `describe`.

## Files

Lesson directory `lessons/02-values-types/` (scaffolded via `make new-lesson NAME=02-values-types`, then hand-authored). The scaffolder emits `main.lua`/`main_spec.lua`; rename to **`values.lua`/`values_spec.lua`** (meaningful name matching the lesson, mirroring Lesson 01's `hello`).

```
lessons/02-values-types/
├── README.md
├── slides/
│   ├── index.html          # reveal bootstrap (from scaffold; deck title authored to "Values & types")
│   ├── slides.md           # the deck (authored)
│   └── assets/.gitkeep
├── exercises/
│   ├── values.lua          # describe() stub (errors)
│   └── values_spec.lua     # failing spec
└── solutions/
    ├── values.lua          # describe() implemented
    └── values_spec.lua     # identical spec, passes
```

### `exercises/values.lua`

```lua
local M = {}

function M.describe(value)
  error("TODO: implement describe so the tests pass")
end

return M
```

### `exercises/values_spec.lua`

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

### `solutions/values.lua`

```lua
local M = {}

function M.describe(value)
  return math.type(value) or type(value)
end

return M
```

### `solutions/values_spec.lua`

Identical to `exercises/values_spec.lua` (same `require("values")`, same six assertions). The spec sits beside its `values.lua`; `make test` runs `exercises/` and `solutions/` in separate `busted` processes, so the shared module name `values` never collides.

### Why `math.type(value) or type(value)`

This one line is the lesson:

- `math.type(value)` returns `"integer"` for `3`, `"float"` for `3.0`, and **`nil`** for anything that is not a number — the 5.4 integer/float distinction.
- For non-numbers, `math.type` returns `nil`, which is **falsy**, so the `or` falls through to `type(value)` — yielding `"string"`, `"boolean"`, `"nil"`, `"table"`, etc.

So the exercise demonstrates the value types, the integer/float subtype, AND truthiness (the `or`-fallback works *because* `nil` is falsy) in a single expression. `tostring`/`tonumber` are taught in the README/slides and "going further", not graded here.

## Slides (`slides/slides.md`)

~9 slides, `---`-separated, code in fenced ` ```lua ` blocks, ~15 visible lines max, `Note:` where useful.

1. **Title** — "Lesson 02 — Values & types" + one-line goal.
2. **The value types** — `nil`, `boolean`, `number`, `string`, `table`, `function`; `type(x)` names them.
3. **Numbers: integer & float** — `3` is an integer, `3.0` a float (5.4); `math.type(3)` → `"integer"`, `math.type(3.0)` → `"float"`; `/` always gives a float, `//` floor-divides (a teaser for L04).
4. **Strings** — `"..."`/`'...'`/`[[...]]` literals; `..` joins (recap from L01); `#s` is the byte length.
5. **Truthiness** — only `nil` and `false` are falsy; **everything else is truthy, including `0` and `""`** (a common surprise).
6. **`type()` and `math.type()`** — inspect any value; `math.type` returns `nil` for non-numbers.
7. **Converting** — `tostring(x)` for printing/joining; `tonumber("42")` → `42`, `tonumber("nope")` → `nil` (nil on failure).
8. **The exercise** — `describe(value)` = `math.type(value) or type(value)`; walk through why the `or` reaches `type` for non-numbers (falsy `nil`). `make test-lesson LESSON=02-values-types`.
9. **What's next** — pointer to Lesson 03 (Control flow).

## README (`README.md`)

Four-file convention sections:

- **Learning goals** — the five bullets above.
- **Prereqs** — Lesson 01; toolchain via `make bootstrap`.
- **Concepts** — 1–3 short paragraphs mirroring the deck: the value types; integer vs float + `math.type`; truthiness (only `nil`/`false` falsy; `0`/`""` truthy); `type`/`tostring`/`tonumber` (nil on failure); how `describe` combines them.
- **Exercise brief** — implement `describe(value)` in `exercises/values.lua` so all six examples pass; observe how `math.type … or type …` handles every value kind.
- **How to run** — `make test-lesson LESSON=02-values-types`; REPL exploration from `solutions/` (`print(require("values").describe(3))` etc.).
- **Going further** (light, no new graded work) — `tonumber("ff", 16)` (bases), integer overflow + `math.maxinteger`/`math.mininteger`, `string.format("%d"/"%g", …)` as a `tostring` alternative (teaser for L09).

## Verification (success criteria)

- `make test-lesson LESSON=02-values-types` → exercise spec FAILS (`TODO` error), solution spec PASSES (6 examples), target exit 0.
- `make test` → tools (42) + `01-hello` solutions (2) + `02-values-types` solutions (6), in isolated per-lesson processes.
- `make lint` → clean, covering the new lesson (no harness change needed).
- `make slides-build` → `dist/index.html` shows `02-values-types` as a **link** (21 future placeholders remain); `dist/lessons/02-values-types/slides/index.html` exists with `<title>` "Lesson 02 — Values & types".
- `make slides-dev LESSON=02-values-types` → the deck renders locally.
- CI on the PR is green.

## Non-goals

- No control flow / `if` (Lesson 03) — `describe` needs none.
- No systematic operator coverage (Lesson 04); the incidental `or` in `describe` is the truthiness demonstration, not an operators lesson.
- `tostring`/`tonumber` are taught but not graded (kept to one `describe` function to stay gentle).
- No tables-as-data-structure depth (Lesson 08) — `{}` appears only as a value `type` returns `"table"` for.
- No changes to the `new-lesson`/`slides-dev`/`build-index` tools or the Makefile/.luacheckrc (the Lesson 01 harness change already covers lessons).

## Open items deferred to implementation planning

- Exact wording/voice of the slide prose and README concept paragraphs.
- Whether to mention `function`/`thread`/`userdata` types on the "value types" slide (default: list `nil`/`boolean`/`number`/`string`/`table`/`function`; mention `thread`/`userdata` exist only in "going further" or not at all, to stay gentle).
