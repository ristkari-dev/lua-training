# Lesson 04 — Operators & expressions — Design

**Status:** Approved (brainstorming complete, awaiting implementation plan)
**Date:** 2026-09-22
**Owner:** Aki Ristkari

## Summary

The fourth lesson by number, authored after Lessons 01, 02, 03 and 05. It fills the
last Phase 1 gap before Lesson 06. Lesson 04 ("Operators & expressions") covers the
arithmetic set (`//`, `%`, `^`, and `/` always producing a float), relational
operators, the logical operators and the `a and b or c` idiom, `..` and `#`, the
bitwise operators new in 5.4, and precedence.

**The constraint that shapes this lesson:** it precedes Lesson 05, so students do not
yet know `if`, `while`, `repeat` or `for`. The graded solution must be
**expression-only** — which is also the lesson's best teaching moment, because
`a and b or c` is the only conditional students have until control flow arrives.

The exercise is `page_label(items, per_page)`, which returns `"1 page"` / `"4 pages"`:

```lua
local pages = items // per_page + (items % per_page == 0 and 0 or 1)
return pages .. " page" .. (pages == 1 and "" or "s")
```

Two lines in which every operator is load-bearing, and the `and`/`or` idiom appears
twice in two different jobs (choosing a number, choosing a suffix).

The exercise was chosen by a design panel: six candidates — one per operator family
plus a free choice — were built and verified (busted + luacheck + mandatory mistake
injection), then scored by three judges (beginner pedagogy, curriculum coverage and
elegance, technical robustness). The judges split three ways, and each broke the
others' favourites by hand. This exercise is the synthesis the topic-fit judge ranked
first, rebuilt along the line the pedagogy judge argued for: the **remainder route**
(`+ (items % per_page == 0 and 0 or 1)`) instead of the original
`(items + per_page - 1) // per_page` ceiling trick, which no beginner four lessons in
would invent. The ceiling trick moves to "Going further".

Two findings from the panel are baked in below: the sixth example `page_label(7, 10)`
(the judges found that without a singular case arising from a *partial* page, a wrong
plural rule passes 5/5), and the `math.ceil` dodge, which no behavioural test can
catch and which the exercise brief therefore forbids by name.

No harness change is needed: `make lint`/`make fmt` already cover `lessons/`,
`make test` already loops lesson `solutions/`, and `tools/build-index/catalog.lua`
already lists `04-operators`.

## Learning goals

1. Use the arithmetic operators, and know what each returns: `/` is always a float,
   `//` floor-divides (rounding toward negative infinity, so `-7 // 2` is `-4`), `%`
   is the matching remainder (`-1 % 60` is `59`), and `^` is always a float and
   right-associative.
2. Compare with `==`, `~=`, `<`, `<=`, `>`, `>=` — and know that values of different
   types are never equal, while *ordering* them is a runtime error.
3. Use `and`/`or`/`not`, knowing they return an operand rather than a boolean and
   short-circuit; write the `a and b or c` idiom, and state the trap: it is only safe
   when the middle operand can never be `false` or `nil`.
4. Join with `..` (numbers coerce to strings) and measure with `#` (bytes, not
   characters).
5. Read and write the bitwise operators `&`, `|`, `~` (binary xor and unary not),
   `<<`, `>>` — integer-only in 5.4.
6. Predict precedence well enough to know where parentheses are required, and where
   adding them changes the answer.
7. Implement `page_label(items, per_page)` — expression-only — to make a failing
   `busted` spec pass.

## Files

Lesson directory `lessons/04-operators/` (scaffolded via
`make new-lesson NAME=04-operators`, then hand-authored). Rename the template's
`main`→**`operators`**; the exercise function is `page_label`, so calls read
`operators.page_label(items, per_page)`.

```
lessons/04-operators/
├── README.md
├── slides/
│   ├── index.html          # reveal bootstrap; the scaffold writes the WRONG title
│   │                       #   ("Lesson 04 — Operators") — hand-fix it to
│   │                       #   "Lesson 04 — Operators &amp; expressions"
│   ├── slides.md           # the deck (authored, 12 slides)
│   └── assets/.gitkeep
├── exercises/
│   ├── operators.lua       # page_label() stub (errors)
│   └── operators_spec.lua  # failing spec
└── solutions/
    ├── operators.lua       # page_label() implemented
    └── operators_spec.lua  # identical spec, passes
```

**The spec uses the house `package.path` + `require` header** (as in Lessons 01, 02
and 05). Lesson 03's sandboxed loader was a documented one-off for a lesson whose
subject was module state; this lesson has no such need.

### `exercises/operators.lua`

```lua
local M = {}

function M.page_label(items, per_page)
  error("TODO: implement page_label so the tests pass")
end

return M
```

### `exercises/operators_spec.lua`

```lua
local here = debug.getinfo(1, "S").source:match("^@(.*/)")
package.path = here .. "?.lua;" .. package.path
local operators = require("operators")

describe("page_label", function()
  it("says page in the singular for one full page", function()
    assert.are.equal("1 page", operators.page_label(10, 10))
  end)

  it("says page in the singular for one partial page", function()
    assert.are.equal("1 page", operators.page_label(7, 10))
  end)

  it("rounds a partial page up", function()
    assert.are.equal("2 pages", operators.page_label(11, 10))
  end)

  it("counts every partial page, it does not round to nearest", function()
    assert.are.equal("4 pages", operators.page_label(10, 3))
  end)

  it("adds no extra page when the division is exact", function()
    assert.are.equal("3 pages", operators.page_label(9, 3))
  end)

  it("needs no pages for no items", function()
    assert.are.equal("0 pages", operators.page_label(0, 10))
  end)
end)
```

### `solutions/operators.lua`

```lua
local M = {}

function M.page_label(items, per_page)
  local pages = items // per_page + (items % per_page == 0 and 0 or 1)
  return pages .. " page" .. (pages == 1 and "" or "s")
end

return M
```

### `solutions/operators_spec.lua`

Identical to `exercises/operators_spec.lua`. `make test` runs `exercises/` and
`solutions/` in separate `busted` processes, so the shared module name `operators`
never collides.

### Why this shape

Every operator in the two lines is load-bearing, and each one has a failure the spec
catches (all seven verified before this spec was written — see Verification):

- `items // per_page` — `/` instead fails **all six** examples, because `1.0 page` is
  not `1 page`. The integer subtype from L02 becomes visible in the output.
- `items % per_page == 0 and 0 or 1` — "one more page if anything is left over".
  Dropping it fails 3 of 6.
- `(pages == 1 and "" or "s")` — the `a and b or c` idiom. A **letter cannot be
  produced by arithmetic**, which is what makes the idiom unfakeable here. (The
  panel's arithmetic-flavoured candidates all lost their `and`/`or` grading to digit
  tricks: `rest // 10 .. rest % 10` reproduces a zero-padded clock with no logical
  operator at all.)
- **Parentheses, twice, in opposite directions.** Both idioms need them, because `+`
  and `..` bind tighter than `and`/`or`; omitting either breaks the function (3/6 and
  0/6). But `(pages == 1 and ("" or "s"))` raises
  `attempt to concatenate a boolean value`, because `"" or "s"` is always `""`, which
  makes the whole group `false`. Too few parens and too many, side by side.

### The `math.ceil` dodge

`math.ceil(items / per_page)` passes all six examples. No behavioural test can
distinguish it, so the exercise brief forbids the `math` library **by name** (the
panel's pedagogy judge noted that "no library calls" does not read as "not
`math.ceil`" to a beginner), and gives the honest technical reason: `//` is exact for
every integer, while rounding through a float diverges above 2^53. `string.format`
is named the same way.

### What is taught but not graded

`^`, `#` and the bitwise family get no graded coverage. No expression-only exercise
forces them, and bolting them onto `page_label` would turn it into a grab bag. They
are taught on slides, demonstrated in the README's REPL block, and `#` and bitwise
get a "Going further" exercise each. This gap is deliberate and recorded here so a
future reader does not mistake it for an oversight.

## Slides (`slides/slides.md`)

12 slides, `---`-separated, fenced ` ```lua ` blocks, `Note:` where useful. Every
value below was run against the repo's Lua 5.4.4 before this spec was written.

1. **Title** — "Lesson 04 — Operators & expressions" + one-line goal: build a whole
   conditional out of nothing but operators.
2. **Arithmetic** — `7 / 2` → `3.5` (always a float); `7 // 2` → `3`; `7 % 2` → `1`;
   `-7 // 2` → `-4` (floors toward negative infinity) and `-1 % 60` → `59` to match.
3. **`^` is the odd one** — `2^3` → `8.0` (a float even here); right-associative, so
   `2^3^2` → `512.0`; binds tighter than unary minus, so `-2^2` → `-4.0` while
   `(-2)^2` → `4.0`.
4. **Relational** — `==`, `~=`, `<`, `<=`, `>`, `>=`; `"10" == 10` → `false` (different
   types are never equal) but `"10" < 10` is an error,
   `attempt to compare string with number`; `10 == 10.0` → `true` (same number,
   different subtype).
5. **Logical** — `and`/`or` return **an operand, not a boolean**, and short-circuit;
   only `nil`/`false` are falsy, so `0 or 5` → `0`.
6. **`a and b or c` — your only `if`** — `pages == 1 and "" or "s"`; until Lesson 05
   this is the whole conditional toolkit.
7. **The idiom's one trap** — it only holds when the middle operand can never be
   `false`/`nil`: `flag and false or true` returns `true` even when `flag` is `true`.
8. **`..` and coercion** — `1 .. 2` → `"12"`; `"5" + 1` → `6` (an integer — strings
   coerce in arithmetic too); `..` is right-associative.
9. **`#`** — `#"hello"` → `5`; `#"Äiti"` → `5` as well, because `#` counts **bytes**,
   not characters; `#5` is an error (`attempt to get length of a number value`).
10. **Bitwise (5.4)** — `3 & 5` → `1`, `3 | 5` → `7`, `3 ~ 5` → `6` (binary xor),
    `~0` → `-1` (unary not), `1 << 3` → `8`, `16 >> 2` → `4`; integers only, so
    `3.0 & 1` → `1` but `3.5 & 1` errors with
    `number has no integer representation`.
11. **Precedence** — the chain from `^` down to `or`, highlighting the two rules the
    exercise needs: `+` and `..` bind tighter than `and`/`or` (so the idiom needs
    parentheses), and `&` binds tighter than `~=`.
12. **The exercise** — `page_label`, the two paren decisions, the
    `make test-lesson LESSON=04-operators` command — then **What's next: Lesson 05
    (Control flow)**, where `if` finally arrives.

## README (`README.md`)

Four-file convention sections:

- **Learning goals** — the seven bullets above, condensed to six lines.
- **Prereqs** — Lessons 01–03; toolchain via `make bootstrap`.
- **Concepts** — short paragraphs mirroring the deck: the arithmetic set and what each
  returns; relational and the never-equal/cannot-compare split; logical operators, the
  idiom, and its trap; `..`/`#`; bitwise; precedence and where parentheses are
  mandatory.
- **Exercise brief** — implement `page_label(items, per_page)` returning `"1 page"` /
  `"4 pages"`. The remainder route in words: *whole pages, plus one more if anything
  is left over*. **Operators only — no `math` library (Lesson 17), no `string.format`
  (Lesson 09)**, with the 2^53 reason stated. Definition of done:
  `make test-lesson LESSON=04-operators` passes **and** `make lint` is clean.
- **How to run** — `make test-lesson LESSON=04-operators`; REPL exploration from
  `solutions/`, including `print(12 // 10, 12 / 10)` → `1   1.2` so the student
  recognises the float symptom when they hit it.
- **Going further** — the `(items + per_page - 1) // per_page` ceiling trick (and
  `-(-items // per_page)`); the bitwise permission renderer
  `(flags & 4 ~= 0 and "r" or "-") .. (flags & 2 ~= 0 and "w" or "-") .. (flags & 1 ~= 0 and "x" or "-")`
  (verified: `6` → `rw-`), which also shows `&` binding tighter than `~=`; and `#` on
  a multi-byte string as the byte-vs-character demo.

## Verification (success criteria)

- `make test-lesson LESSON=04-operators` → exercise spec FAILS (6 `TODO` errors),
  solution spec PASSES (6 examples), target exit 0.
- **Mistake injection** (scratch only, never committed). All seven were run against
  this exact spec before the spec was written; the implementation must reproduce them:

  | Wrong solution | Result |
  |---|---|
  | `items // per_page` alone (no remainder term) | 3 successes / 3 failures |
  | plural keyed on `items == per_page` | 5 successes / 1 failure (caught only by `(7, 10)`) |
  | no parens around the remainder term | 3 successes / 3 failures |
  | no parens around the plural idiom | 0 successes / 6 failures |
  | over-parenthesised `(pages == 1 and ("" or "s"))` | 2 successes / 4 errors |
  | `/` instead of `//` | 0 successes / 6 failures |
  | `math.ceil(items / per_page)` | **6 successes — the documented dodge** |

- `make test` → tools (42) + `01-hello` (2) + `02-values-types` (6) +
  `03-variables-scope` (3) + `04-operators` (6) + `05-control-flow` (5).
- `make lint` → clean, covering the new lesson.
- `make slides-build` → `dist/index.html` links `04-operators` (18 future
  placeholders remain); the deck's `<title>` is
  `Lesson 04 — Operators &amp; expressions` (HTML-escaped, matching Lessons 02–03).
- `make slides-dev LESSON=04-operators` → the deck renders.
- CI on the PR is green.

## Non-goals

- No control flow — Lesson 05 is next, and the whole point of this lesson's exercise
  is that it has none.
- No multiple return values (L06), no tables as data or the table library (L08), no
  string library including `string.format` (L09), no metatables (L10), no `_G`/`_ENV`
  (L18), and no `math` library at all.
- `^`, `#` and the bitwise operators are taught and demonstrated, never graded.
- No changes to the tools, Makefile or `.luacheckrc`.
- The `math.ceil` dodge is closed in prose, not in the spec. Sandboxing the module's
  environment to remove `math` (the technique Lesson 03 used for globals) would cost
  more clarity than the dodge costs correctness.

## Open items deferred to implementation planning

- Exact wording/voice of the slide prose and README concept paragraphs.
- Whether the precedence slide shows the full operator table or only the four rows the
  exercise needs (default: the full chain, compact, with the two exercise-relevant
  rules called out).

## Noticed, out of scope for this lesson

- `lessons/05-control-flow/slides/slides.md` introduces `%` as if it were new; after
  this lesson it is not. A one-line follow-up PR, deliberately not bundled here.
- `tools/new-lesson` still derives a scaffolded deck's `<title>` by title-casing the
  slug, so `04-operators` scaffolds as "Lesson 04 — Operators" and must be hand-fixed.
  Its own issue, already recorded in the Lesson 03 design.
