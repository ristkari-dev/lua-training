# Plan G — Lesson 04 (Operators & expressions) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Author Lesson 04 ("Operators & expressions") — a `page_label(items, per_page)` exercise whose expression-only solution grades `//`, `%`, `==`, `..` and the `a and b or c` idiom twice — with a failing `busted` spec, reference solution, README, and 13-slide deck, so `04-operators` becomes a published lesson and Phase 1's last numbering gap closes.

**Architecture:** Scaffold `lessons/04-operators/` with `make new-lesson`, rename the template's `main`→`operators`, and replace the placeholder content with the `page_label` exercise/solution + specs. `operators.lua` is a pure module with one function and no state. The spec uses the house `package.path` + `require` header (Lesson 03's sandboxed loader was a documented one-off). No harness change — `make lint`/`make fmt` already cover `lessons/`, `make test` already loops lesson `solutions/`, and `tools/build-index/catalog.lua` already lists `04-operators`.

**Tech Stack:** Lua 5.4 (`.lua/bin/lua`), `busted`, `luacheck`, reveal.js slides, GNU Make.

**Spec:** `docs/superpowers/specs/2026-09-22-lesson-04-operators-design.md`

## Global Constraints

- **Lua 5.4** (PUC-Rio, via `.lua/`); `luacheck` `std = "lua54"` is the only static gate.
- **Prerequisite ceiling — the constraint that shapes this lesson:** Lesson 04 precedes Lesson 05, so students know no control flow. The graded solution must be **expression-only**: no `if`, `while`, `repeat`, `for` (L05), no multiple return values or varargs (L06), no tables as data or the table library (L08), no string library including `string.format` (L09), no metatables (L10), no `_G`/`_ENV` (L18), and **no `math` library at all**. Students know: L01 (module + function + `..`), L02 (types, integer/float via `math.type`, truthiness, `x or y`, `tostring`/`tonumber`), L03 (`local` vs global, blocks/chunks, `<const>`, multiple assignment).
- **Four-file lesson convention:** `README.md`, `slides/`, `exercises/`, `solutions/`; the spec file is byte-identical in `exercises/` and `solutions/`.
- **Module name:** `operators` (files `operators.lua`, `operators_spec.lua`); graded function `page_label`.
- **House spec header** (as in Lessons 01/02/05): `debug.getinfo` + `package.path` + `require`. Do NOT use Lesson 03's sandboxed `loadfile` loader.
- **No harness edits:** no changes to `Makefile`, `.luacheckrc`, `tools/`, `shared/`.
- **Definition of done for the lesson:** `make test-lesson LESSON=04-operators` passes AND `make lint` is clean.
- **Deck title must be HTML-escaped:** `<title>Lesson 04 — Operators &amp; expressions</title>`, matching `lessons/02-values-types` and `lessons/03-variables-scope`. The scaffold writes the wrong title and it must be hand-fixed (see Task 2 Step 1).
- **House voice:** short sentences, second person, em dashes, no exclamation marks.
- **Commit messages end with:** `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`

---

## Context for the implementer

- **Working directory:** `/Users/ristkari/code/private/lua-training/`. **Branch:** `lesson-04-operators` (already checked out off merged `main`, which has Plans A + B, the CI fix, and Lessons 01, 02, 03, 05). The design doc is already committed on this branch. Commit here; do NOT push.
- **Toolchain present:** the gitignored `.lua/` tree already exists. Use `.lua/bin/lua`, `.lua/bin/busted`, `.lua/bin/luacheck`, or the `make` targets. Do NOT run `make bootstrap`.
- **Read for house style before writing prose:** `lessons/03-variables-scope/README.md` and `lessons/05-control-flow/slides/slides.md`.
- **Scratch dir for throwaway files (mistake injection):** `/private/tmp/claude-501/-Users-ristkari-code-private-lua-training/f282ee64-4464-42c2-be99-69487673f9f6/scratchpad/l04-impl/`. Nothing there is ever committed.
- **`make test-lesson` output is expected to be noisy:** the `exercises/` run fails by design (6 errors), then the `solutions/` run passes (6 successes); the target exits 0.
- **Every Lua value quoted in this plan was run against the repo's Lua 5.4.4 before the plan was written.** If one of your own runs contradicts the plan, report that rather than silently changing the text.
- **The known, accepted dodge:** `math.ceil(items / per_page)` passes all six examples. This is documented in the design doc and closed in the README's prose, not in the spec. Do not add tests or sandboxing to try to catch it.

## File Structure

```
lessons/04-operators/                    (scaffolded, then hand-authored)
├── README.md                            (Task 2 — rewritten)
├── slides/
│   ├── index.html                       (from scaffold, title WRONG — Task 2 hand-fixes it)
│   ├── slides.md                        (Task 2 — rewritten, 13 slides)
│   └── assets/.gitkeep                  (from scaffold, unchanged)
├── exercises/
│   ├── operators.lua                    (Task 1 — page_label stub; renamed from main.lua)
│   └── operators_spec.lua               (Task 1 — failing spec)
└── solutions/
    ├── operators.lua                    (Task 1 — page_label implemented)
    └── operators_spec.lua               (Task 1 — identical spec, passes)
```

No `Makefile`/`.luacheckrc`/`tools/` changes.

---

## Task 1: Scaffold and author the `page_label` exercise + solution

**Files:**
- Create (via scaffold, then rename/rewrite): `lessons/04-operators/exercises/operators.lua`, `lessons/04-operators/exercises/operators_spec.lua`, `lessons/04-operators/solutions/operators.lua`, `lessons/04-operators/solutions/operators_spec.lua`
- Also created by the scaffold (left for Task 2): `lessons/04-operators/README.md`, `lessons/04-operators/slides/index.html`, `lessons/04-operators/slides/slides.md`, `lessons/04-operators/slides/assets/.gitkeep`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: module `operators` returning a table with one function, `operators.page_label(items, per_page)` → string. Returns `"<n> page"` for exactly one page and `"<n> pages"` otherwise. Task 2's README and slides quote this function name and the commands below.

- [ ] **Step 1: Scaffold the lesson**

Run: `make new-lesson NAME=04-operators`
Expected: prints `created lessons/04-operators`, with `README.md`, `slides/{index.html,slides.md,assets/.gitkeep}`, `exercises/{main.lua,main_spec.lua}`, `solutions/{main.lua,main_spec.lua}`.

- [ ] **Step 2: Rename the template's `main`→`operators` in both dirs**

```bash
mv lessons/04-operators/exercises/main.lua      lessons/04-operators/exercises/operators.lua
mv lessons/04-operators/exercises/main_spec.lua lessons/04-operators/exercises/operators_spec.lua
mv lessons/04-operators/solutions/main.lua      lessons/04-operators/solutions/operators.lua
mv lessons/04-operators/solutions/main_spec.lua lessons/04-operators/solutions/operators_spec.lua
```

- [ ] **Step 3: Write the failing spec (`exercises/operators_spec.lua`)**

Overwrite `lessons/04-operators/exercises/operators_spec.lua` with EXACTLY:

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

- [ ] **Step 4: Write the stub (`exercises/operators.lua`)**

Overwrite `lessons/04-operators/exercises/operators.lua` with EXACTLY:

```lua
local M = {}

function M.page_label(items, per_page)
  error("TODO: implement page_label so the tests pass")
end

return M
```

- [ ] **Step 5: Run the exercise spec to verify it fails**

Run: `.lua/bin/busted lessons/04-operators/exercises`
Expected: `0 successes / 0 failures / 6 errors`, each error reading `TODO: implement page_label so the tests pass`. Exit code 1.

- [ ] **Step 6: Copy the spec into `solutions/` (byte-identical)**

```bash
cp lessons/04-operators/exercises/operators_spec.lua lessons/04-operators/solutions/operators_spec.lua
diff lessons/04-operators/exercises/operators_spec.lua lessons/04-operators/solutions/operators_spec.lua && echo "specs identical"
```
Expected: `specs identical`.

- [ ] **Step 7: Write the reference solution (`solutions/operators.lua`)**

Overwrite `lessons/04-operators/solutions/operators.lua` with EXACTLY:

```lua
local M = {}

function M.page_label(items, per_page)
  local pages = items // per_page + (items % per_page == 0 and 0 or 1)
  return pages .. " page" .. (pages == 1 and "" or "s")
end

return M
```

- [ ] **Step 8: Run the solution spec to verify it passes**

Run: `.lua/bin/busted lessons/04-operators/solutions`
Expected: `6 successes / 0 failures / 0 errors`. Exit code 0.

- [ ] **Step 9: Verify the spec catches every operator mistake**

Throwaway copies in the scratch dir — never commit them. Run:

```bash
SCRATCH=/private/tmp/claude-501/-Users-ristkari-code-private-lua-training/f282ee64-4464-42c2-be99-69487673f9f6/scratchpad/l04-impl
rm -rf "$SCRATCH" && mkdir -p "$SCRATCH"
for d in naive_floor plural_items no_parens_remainder no_parens_plural over_parens slash_div math_ceil; do
  mkdir -p "$SCRATCH/$d"
  cp lessons/04-operators/solutions/operators_spec.lua "$SCRATCH/$d/operators_spec.lua"
done

# no remainder term: floor division alone
cat > "$SCRATCH/naive_floor/operators.lua" <<'LUA'
local M = {}

function M.page_label(items, per_page)
  local pages = items // per_page
  return pages .. " page" .. (pages == 1 and "" or "s")
end

return M
LUA

# plural keyed on the wrong thing
cat > "$SCRATCH/plural_items/operators.lua" <<'LUA'
local M = {}

function M.page_label(items, per_page)
  local pages = items // per_page + (items % per_page == 0 and 0 or 1)
  return pages .. " page" .. (items == per_page and "" or "s")
end

return M
LUA

# no parentheses around the remainder term
cat > "$SCRATCH/no_parens_remainder/operators.lua" <<'LUA'
local M = {}

function M.page_label(items, per_page)
  local pages = items // per_page + items % per_page == 0 and 0 or 1
  return pages .. " page" .. (pages == 1 and "" or "s")
end

return M
LUA

# no parentheses around the plural idiom
cat > "$SCRATCH/no_parens_plural/operators.lua" <<'LUA'
local M = {}

function M.page_label(items, per_page)
  local pages = items // per_page + (items % per_page == 0 and 0 or 1)
  return pages .. " page" .. pages == 1 and "" or "s"
end

return M
LUA

# over-parenthesised idiom
cat > "$SCRATCH/over_parens/operators.lua" <<'LUA'
local M = {}

function M.page_label(items, per_page)
  local pages = items // per_page + (items % per_page == 0 and 0 or 1)
  return pages .. " page" .. (pages == 1 and ("" or "s"))
end

return M
LUA

# float division
cat > "$SCRATCH/slash_div/operators.lua" <<'LUA'
local M = {}

function M.page_label(items, per_page)
  local pages = items / per_page + (items % per_page == 0 and 0 or 1)
  return pages .. " page" .. (pages == 1 and "" or "s")
end

return M
LUA

# the documented dodge — expected to PASS
cat > "$SCRATCH/math_ceil/operators.lua" <<'LUA'
local M = {}

function M.page_label(items, per_page)
  local pages = math.ceil(items / per_page)
  return pages .. " page" .. (pages == 1 and "" or "s")
end

return M
LUA

for d in naive_floor plural_items no_parens_remainder no_parens_plural over_parens slash_div math_ceil; do
  printf '%-22s ' "$d"
  .lua/bin/busted "$SCRATCH/$d" 2>&1 | grep -E "successes" | head -1
done
```

Expected, exactly (these were verified before this plan was written):

| Directory | Expected result |
|---|---|
| `naive_floor` | 3 successes / 3 failures |
| `plural_items` | 5 successes / 1 failure |
| `no_parens_remainder` | 3 successes / 3 failures |
| `no_parens_plural` | 0 successes / 6 failures |
| `over_parens` | 2 successes / 0 failures / 4 errors |
| `slash_div` | 0 successes / 6 failures |
| `math_ceil` | **6 successes** — the documented dodge, closed in prose only |

If any row other than `math_ceil` reports 6 successes, STOP and report it — the spec would not be grading the lesson.

- [ ] **Step 10: Clean up the scratch copies**

```bash
rm -rf /private/tmp/claude-501/-Users-ristkari-code-private-lua-training/f282ee64-4464-42c2-be99-69487673f9f6/scratchpad/l04-impl
git status --porcelain lessons/04-operators
```
Expected: only files under `lessons/04-operators/` are listed as untracked.

- [ ] **Step 11: Lint the new lesson**

Run: `.lua/bin/luacheck --config .luacheckrc lessons/04-operators`
Expected: `0 warnings / 0 errors in 4 files`.

- [ ] **Step 12: Both specs through the make target**

Run: `make test-lesson LESSON=04-operators`
Expected: the `exercises/` run reports 6 errors (by design), the `solutions/` run reports `6 successes`, and the target exits 0.

- [ ] **Step 13: Commit**

```bash
git add lessons/04-operators/exercises lessons/04-operators/solutions
git commit -m "feat(lesson-04): add page_label exercise + solution with busted specs"
```

(The scaffolded `README.md` and `slides/` stay untracked until Task 2.)

---

## Task 2: Author the README and the slide deck

**Files:**
- Modify (rewrite the scaffold placeholders): `lessons/04-operators/README.md`, `lessons/04-operators/slides/slides.md`
- Modify (one line): `lessons/04-operators/slides/index.html`

**Interfaces:**
- Consumes: `operators.page_label(items, per_page)` from Task 1, and the commands `make test-lesson LESSON=04-operators` and `make lint`.
- Produces: prose only; nothing later depends on it except Task 3's verification.

- [ ] **Step 1: Fix the scaffolded deck title**

Run: `grep '<title>' lessons/04-operators/slides/index.html`
Expected (the scaffold is wrong — `tools/new-lesson/new_lesson.lua` title-cases the slug rather than reading the lesson catalog): `<title>Lesson 04 — Operators</title>`.

Edit that one line to EXACTLY:

```html
  <title>Lesson 04 — Operators &amp; expressions</title>
```

The `&amp;` entity is required — it matches `lessons/02-values-types/slides/index.html:6` and `lessons/03-variables-scope/slides/index.html:6`. Change nothing else in the file. If the scaffolded title differs from the expectation above, note it in your report.

- [ ] **Step 2: Write `slides/slides.md`**

Overwrite `lessons/04-operators/slides/slides.md` with EXACTLY the following content. (The outer four-backtick fence is this plan's quoting only — write its *contents*, starting at `## Lesson 04`. The inner ```lua fences are part of the file.)

````markdown
## Lesson 04
### Operators & expressions

Build a whole conditional out of nothing but operators.

Note:
Goal: the arithmetic set, and/or as your only if, .. and #, bitwise, precedence.

---

## Arithmetic

```lua
7 / 2       -- 3.5   (/ is ALWAYS a float)
7 // 2      -- 3     (floor division)
7 % 2       -- 1     (remainder)
-7 // 2     -- -4    (floors toward negative infinity)
-1 % 60     -- 59    (the remainder matches)
```

Note:
// and % agree: the remainder takes the divisor's sign.

---

## ^ is the odd one

```lua
2^3         -- 8.0    (a float, even here)
2^3^2       -- 512.0  (right-associative: 2^(3^2))
-2^2        -- -4.0   (^ binds tighter than unary minus)
(-2)^2      -- 4.0
```

---

## Relational

```lua
"10" == 10  -- false  (different types are never equal)
"10" < 10   -- error: attempt to compare string with number
10 == 10.0  -- true   (same number, different subtype)
```

`==`  `~=`  `<`  `<=`  `>`  `>=`

---

## Logical

```lua
1 and 2     -- 2      (returns an OPERAND, not a boolean)
nil and 2   -- nil    (short-circuits)
nil or 5    -- 5
0 or 5      -- 0      (0 is truthy — only nil and false are falsy)
not 0       -- false  (not always returns a boolean)
```

---

## a and b or c — your only if

```lua
pages == 1 and "" or "s"
```

Reads as: if `pages == 1` then `""` else `"s"`.

Until Lesson 05, this is your whole conditional toolkit.

---

## The idiom's one trap

It only works when the middle value can never be `false` or `nil`.

```lua
local flag = true
flag and false or true    -- true   (not false)
```

Note:
false and nil are exactly the two values the idiom cannot carry. Choose strings or numbers.

---

## .. joins, and coerces

```lua
"a" .. "b" .. "c"   -- "abc"
1 .. 2              -- "12"   (numbers coerce to strings)
"5" + 1             -- 6      (and strings coerce in arithmetic)
```

`..` is right-associative.

---

## # measures bytes

```lua
#"hello"    -- 5
#"Äiti"     -- 5   (4 characters, 5 bytes)
#5          -- error: attempt to get length of a number value
```

Note:
# counts bytes, not characters. utf8.len comes in Lesson 17.

---

## Bitwise (new in 5.3)

```lua
3 & 5       -- 1    (and)
3 | 5       -- 7    (or)
3 ~ 5       -- 6    (xor)
~0          -- -1   (not — unary)
1 << 3      -- 8    (shift left)
16 >> 2     -- 4    (shift right)
3.5 & 1     -- error: number has no integer representation
```

---

## Precedence

From tightest to loosest:

```lua
^
not  #  -  ~      (unary)
*  /  //  %
+  -
..
<<  >>
&
~
|
<  >  <=  >=  ~=  ==
and
or
```

`+` and `..` bind tighter than `and`/`or` — so the idiom needs parentheses.
`&` binds tighter than `~`, which binds tighter than `|`.
`&` binds tighter than `~=`.

---

## The exercise — page_label

```lua
local pages = items // per_page + (items % per_page == 0 and 0 or 1)
return pages .. " page" .. (pages == 1 and "" or "s")
```

Both pairs of parentheses are required. Operators only — no `math`.

```bash
make test-lesson LESSON=04-operators
```

---

## What's next

**Lesson 05 — Control flow.** `if` finally arrives.
````

- [ ] **Step 3: Write `README.md`**

Overwrite `lessons/04-operators/README.md` with EXACTLY the following content. (Again: write the fence's contents, starting at `# Lesson 04`.)

````markdown
# Lesson 04 — Operators & expressions

Every operator Lua has, and what each one returns. You will implement
`page_label()` using nothing but expressions — `if` arrives in Lesson 05.

## Learning goals

- Use the arithmetic operators: `/` always gives a float, `//` floor-divides, `%` is the matching remainder, `^` is a float and right-associative
- Compare with `==`, `~=`, `<`, `<=`, `>`, `>=` — different types are never equal, but ordering them is an error
- Use `and`/`or`, which return an operand rather than a boolean and short-circuit, and `not`, which always returns a boolean; write the `a and b or c` idiom — including when it breaks
- Join with `..` (numbers coerce) and measure with `#` (bytes, not characters)
- Read the bitwise operators `&`, `|`, `~`, `<<`, `>>` — integers only in 5.4
- Know where parentheses are required, and where adding them changes the answer
- Implement `page_label()` to make a failing `busted` spec pass

## Prereqs

- Lessons 01–03. Toolchain via `make bootstrap`.

## Concepts

**Arithmetic.** `/` always produces a float, even when it divides evenly: `6 / 2` is
`3.0`. `//` floor-divides and keeps integers integral, `%` is the matching remainder,
and both round toward negative infinity — `-7 // 2` is `-4` and `-1 % 60` is `59`.
`^` is always a float and right-associative, and it binds tighter than unary minus, so
`-2^2` is `-4.0`.

**Comparison.** Values of different types are never equal, so `"10" == 10` is `false`
— but *ordering* them raises `attempt to compare string with number`. Integers and
floats compare by value: `10 == 10.0` is `true`.

**Logical operators.** `and` and `or` return one of their operands, not a boolean,
and they short-circuit. Since only `nil` and `false` are falsy (Lesson 02), `0 or 5`
is `0`. That gives you the `a and b or c` idiom: `pages == 1 and "" or "s"` reads as
"if `pages == 1` then `""` else `"s"`", and until Lesson 05 it is the only conditional
you have.

**The trap.** The idiom only works when the middle value can never be `false` or
`nil`. `flag and false or true` returns `true` even when `flag` is `true`, because
`and` yields `false` and then `or` discards it. Keep strings and numbers in the middle.

**Joining and measuring.** `..` concatenates and coerces numbers to strings, so
`1 .. 2` is `"12"`; coercion runs the other way in arithmetic too (`"5" + 1` is `6`).
`#` measures a string in **bytes**, not characters: `#"Äiti"` is `5` for four letters.

**Bitwise.** Lua 5.4 has `&`, `|`, `~`, `<<` and `>>`; `~` is binary xor, and written
unary it is bitwise not — `~0` is `-1`. They work on integers only — `3.0 & 1` is fine
because `3.0` has an integer value, but `3.5 & 1` raises `number has no integer
representation`.

**Precedence.** `^` binds tightest and `or` loosest. Two rules matter here: `+` and
`..` both bind tighter than `and`/`or`, so the idiom needs parentheses around it; and
`&` binds tighter than `~=`.

## Exercise brief

Implement `page_label(items, per_page)` in `exercises/operators.lua`. It returns how
many pages the items need, with the noun agreeing: `"1 page"`, `"2 pages"`,
`"0 pages"`.

Count the pages as *whole pages, plus one more if anything is left over* — `//` gives
you the whole ones and `%` tells you whether anything is left. Then pick the suffix
with the `a and b or c` idiom. All six examples in `exercises/operators_spec.lua` must
pass.

**Operators only: no `math` library (Lesson 17) and no `string.format` (Lesson 09).**
`math.ceil(items / per_page)` looks like the obvious answer and the tests cannot tell
— but `//` is exact for every integer, while rounding through a float starts
disagreeing above 2^53. Do it with operators.

You are done when `make test-lesson LESSON=04-operators` passes **and** `make lint` is
clean.

## How to run

```bash
make test-lesson LESSON=04-operators
make lint
```

Explore in the REPL (from the lesson's `solutions/` directory so `require` finds the
file):

```bash
cd lessons/04-operators/solutions
../../../.lua/bin/lua -e 'print(require("operators").page_label(7, 10))'
../../../.lua/bin/lua -e 'print(12 // 10, 12 / 10)'
```

The second line prints `1   1.2` — the difference between the two divisions, which is
also what a failing test will show you.

## Going further

- Once your tests pass, try the other ceiling idiom: `(items + per_page - 1) // per_page`, and the terser `-(-items // per_page)`. Both avoid the remainder term.
- Permissions from bits, all operators: `(flags & 4 ~= 0 and "r" or "-") .. (flags & 2 ~= 0 and "w" or "-") .. (flags & 1 ~= 0 and "x" or "-")` turns `6` into `rw-`. It needs no parentheses around the `&` because `&` binds tighter than `~=`.
- `#` counts bytes, so `#"Äiti"` is `5`. Counting characters needs `utf8.len` (Lesson 17).
````

- [ ] **Step 4: Render the deck locally**

```bash
make slides-dev LESSON=04-operators &
sleep 2
curl -s http://127.0.0.1:8000/ | grep -o "<title>[^<]*</title>"
curl -s -o /dev/null -w "slidesmd=%{http_code}\n" http://127.0.0.1:8000/slides.md
pkill -f "slides-dev/main.lua"
```
Expected: `<title>Lesson 04 — Operators &amp; expressions</title>` and `slidesmd=200`.

- [ ] **Step 5: Check the deck has thirteen slides**

Run: `grep -c '^---$' lessons/04-operators/slides/slides.md`
Expected: `12` (thirteen slides separated by twelve `---` lines).

- [ ] **Step 6: Verify every Lua value the deck and README claim**

The deck and README quote many operator results. Confirm the whole set in one run:

```bash
.lua/bin/lua -e 'print(7/2, 7//2, 7%2, -7//2, -1%60)'        # 3.5  3  1  -4  59
.lua/bin/lua -e 'print(2^3, 2^3^2, -2^2, (-2)^2)'            # 8.0  512.0  -4.0  4.0
.lua/bin/lua -e 'print("10" == 10, 10 == 10.0)'              # false  true
.lua/bin/lua -e 'print(1 and 2, nil or 5, 0 or 5)'           # 2  5  0
.lua/bin/lua -e 'local f = true print(f and false or true)'  # true
.lua/bin/lua -e 'print(1 .. 2, "5" + 1, #"hello", #"Äiti")'  # 12  6  5  5
.lua/bin/lua -e 'print(3 & 5, 3 | 5, 3 ~ 5, ~0, 1 << 3, 16 >> 2)'   # 1  7  6  -1  8  4
.lua/bin/lua -e 'print(12 // 10, 12 / 10)'                   # 1  1.2
.lua/bin/lua -e 'local flags = 6 print((flags & 4 ~= 0 and "r" or "-") .. (flags & 2 ~= 0 and "w" or "-") .. (flags & 1 ~= 0 and "x" or "-"))'   # rw-
.lua/bin/lua -e 'print("10" < 10)'   2>&1 | head -1   # attempt to compare string with number
.lua/bin/lua -e 'print(3.5 & 1)'     2>&1 | head -1   # number has no integer representation
.lua/bin/lua -e 'print(#5)'          2>&1 | head -1   # attempt to get length of a number value
```

Expected: every value matches the comment beside it, and the three error messages match the text quoted in the deck and README. If any differs, fix the prose to match reality and say so in your report — reality wins.

- [ ] **Step 7: Commit**

```bash
git add lessons/04-operators/README.md lessons/04-operators/slides
git commit -m "docs(lesson-04): author the README and slide deck"
```

---

## Task 3: Final verification

No files change in this task — it confirms the lesson is integrated. (Commit only if a step surfaces something to tidy.)

- [ ] **Step 1: Lint the whole repo**

Run: `make lint`
Expected: `0 warnings / 0 errors`. (The stub's unused `items`/`per_page` are allowed by `unused_args = false` in `.luacheckrc`.)

- [ ] **Step 2: Full test suite**

Run: `make test`
Expected: `busted tools` → `42 successes`; `== lessons/01-hello/solutions ==` → `2`; `== lessons/02-values-types/solutions ==` → `6`; `== lessons/03-variables-scope/solutions ==` → `3`; `== lessons/04-operators/solutions ==` → `6`; `== lessons/05-control-flow/solutions ==` → `5`. Exit 0.

If the tools run fails with `File exists` from `tools/slides-dev/spec/server_spec.lua`, that is a known pre-existing flake (temp directory names come from `os.time()`, so two runs in the same second collide). Wait a second, re-run, and note it in your report — do not fix it here.

- [ ] **Step 3: Static build publishes the lesson as a link**

```bash
make slides-build
grep -q '<a class="lesson" href="lessons/04-operators/slides/">' dist/index.html && echo "04 is a link"
grep -c 'class="lesson future"' dist/index.html   # expect 18 (23 total minus 01+02+03+04+05)
grep -o "<title>[^<]*</title>" dist/lessons/04-operators/slides/index.html
rm -rf dist
```
Expected: `04 is a link`, `18`, `<title>Lesson 04 — Operators &amp; expressions</title>`.

- [ ] **Step 4: Formatting matches StyLua (only if StyLua is installed)**

```bash
command -v stylua >/dev/null && stylua --check lessons/04-operators || echo "stylua not installed — skipped"
```
Expected: no output from `--check` (or the skip message). If it reports diffs, run `make fmt`, re-run Task 1 Step 8 and Step 11, and amend the Task 1 commit.

- [ ] **Step 5: Clean check**

Run: `git status --porcelain`
Expected: empty (no `dist/`, no scratch files, no lingering `slides-dev` server — if one lingers, `pkill -f "slides-dev/main.lua"`).

---

## Self-review notes (run before reporting overall)

- `make test-lesson LESSON=04-operators` → exercises error (6), solutions pass (6), exit 0.
- Mistake injection (Task 1 Step 9) → six wrong solutions fail with the counts tabulated there; `math_ceil` passes, as documented.
- `make test` → 42 + 2 + 6 + 3 + 6 + 5.
- `make lint` → 0/0.
- `make slides-build` → `04-operators` is a link; 18 future placeholders; deck title `Lesson 04 — Operators &amp; expressions`.
- Deck has 13 slides; every quoted Lua value and error message re-verified (Task 2 Step 6).
- No tool/Makefile/.luacheckrc changes; `solutions/operators.lua` is expression-only — no control flow, no `math`, no multiple returns.
- Specs byte-identical between `exercises/` and `solutions/`.

## Notes for execution

- No `git push`, no `gcloud`, no `make bootstrap`.
- The exercise spec failing is the deliverable; `make test` runs only `solutions/`.
- Two commits are expected: `feat(lesson-04): …` (Task 1) and `docs(lesson-04): …` (Task 2).
- **Commits are GPG-signed in this repo.** If a commit fails with `gpg: signing failed: Bad PIN`, the agent's cache has expired — report it and stop rather than committing unsigned; the controller will ask the human to unlock it.
- End commit messages with:
  `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`
- After this plan, the lesson is ready for a PR titled "Lesson 04 — Operators & expressions", and Phase 1 has no numbering gaps left. Lesson 06 (Functions & testing) is the next plan.
