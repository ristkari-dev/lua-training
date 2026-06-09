# Plan C — Lesson 01 (Hello, Lua) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Author Lesson 01 ("Hello, Lua") — a pure-module `greet(name)` exercise with a failing `busted` spec, reference solution, README, and slide deck — and extend `make lint`/`make fmt` to cover lessons, so `01-hello` becomes the first published lesson (a link on the landing page).

**Architecture:** Scaffold `lessons/01-hello/` with `make new-lesson`, rename the template's `main`→`hello`, and replace the placeholder content with the `greet` exercise/solution + specs. `hello.lua` is a pure module (`local M = {}; … return M`) with no top-level I/O, because the spec `require`s it and Lua has no `__main__`. Author the README and a ~9-slide deck. A small harness change extends `make lint`/`make fmt` to `lessons/` and sets `unused_args = false` so the exercise stub's unused `name` lints clean.

**Tech Stack:** Lua 5.4 (`.lua/bin/lua`), `busted`, `luacheck` (from Plan A's `.lua/` toolchain), reveal.js slides (Plan A/B), GNU Make.

---

## Context for the implementer

- **Working directory:** `/Users/ristkari/code/private/lua-training/`. **Branch:** `lesson-01-hello` (already checked out, off the merged `main` which has Plan A + Plan B + the CI readline fix). Commit here; do not push.
- **Toolchain is present:** the gitignored `.lua/` tree already exists in the working tree (Lua 5.4.4 + busted + luacheck + lfs). Run `.lua/bin/lua`, `.lua/bin/busted`, `.lua/bin/luacheck`, or the `make` targets that wrap them. Do NOT run `make bootstrap` (not needed).
- **Design:** `docs/superpowers/specs/2026-06-08-lesson-01-hello-design.md` (read for intent; this plan is self-contained).
- **Module/spec resolution:** a lesson spec sits beside its module and prepends its own dir to `package.path` (`local here = debug.getinfo(1,"S").source:match("^@(.*/)"); package.path = here .. "?.lua;" .. package.path`), then `require("hello")`. `make test` runs `exercises/` and `solutions/` in separate `busted` processes, so the shared module name `hello` never collides.
- **`.busted` pattern is `_spec%.lua$`** — only `*_spec.lua` files are collected (the renamed `hello_spec.lua` qualifies).

## File Structure

```
lessons/01-hello/                       (scaffolded, then hand-authored)
├── README.md                           (Task 2 — rewritten)
├── slides/
│   ├── index.html                      (Task 2 — title edited to "Hello, Lua")
│   ├── slides.md                       (Task 2 — rewritten, ~9 slides)
│   └── assets/.gitkeep                 (from scaffold, unchanged)
├── exercises/
│   ├── hello.lua                       (Task 1 — greet stub; renamed from main.lua)
│   └── hello_spec.lua                  (Task 1 — failing spec; renamed from main_spec.lua)
└── solutions/
    ├── hello.lua                       (Task 1 — greet implemented)
    └── hello_spec.lua                  (Task 1 — identical spec, passes)

Makefile                                (Task 3 — lint/fmt cover lessons)
.luacheckrc                             (Task 3 — unused_args = false)
```

---

## Task 1: Scaffold and author the `greet` exercise + solution

**Files:**
- Create (via scaffold, then rename/rewrite): `lessons/01-hello/exercises/hello.lua`, `lessons/01-hello/exercises/hello_spec.lua`, `lessons/01-hello/solutions/hello.lua`, `lessons/01-hello/solutions/hello_spec.lua`

- [ ] **Step 1: Scaffold the lesson**

Run: `make new-lesson NAME=01-hello`
Expected: prints `created lessons/01-hello`. The directory has `README.md`, `slides/{index.html,slides.md,assets/.gitkeep}`, `exercises/{main.lua,main_spec.lua}`, `solutions/{main.lua,main_spec.lua}`.

- [ ] **Step 2: Rename the template's `main`→`hello` in both dirs**

Run:
```bash
mv lessons/01-hello/exercises/main.lua      lessons/01-hello/exercises/hello.lua
mv lessons/01-hello/exercises/main_spec.lua lessons/01-hello/exercises/hello_spec.lua
mv lessons/01-hello/solutions/main.lua      lessons/01-hello/solutions/hello.lua
mv lessons/01-hello/solutions/main_spec.lua lessons/01-hello/solutions/hello_spec.lua
```

- [ ] **Step 3: Write `exercises/hello.lua` (the stub)**

Overwrite `lessons/01-hello/exercises/hello.lua` with EXACTLY:
```lua
local M = {}

function M.greet(name)
  error("TODO: implement greet so the tests pass")
end

return M
```

- [ ] **Step 4: Write `exercises/hello_spec.lua` (the failing spec)**

Overwrite `lessons/01-hello/exercises/hello_spec.lua` with EXACTLY:
```lua
local here = debug.getinfo(1, "S").source:match("^@(.*/)")
package.path = here .. "?.lua;" .. package.path
local hello = require("hello")

describe("greet", function()
  it("greets by name", function()
    assert.are.equal("Hello, Aki!", hello.greet("Aki"))
  end)

  it("greets anyone", function()
    assert.are.equal("Hello, world!", hello.greet("world"))
  end)
end)
```

- [ ] **Step 5: Run the exercise spec to verify it FAILS (by design)**

Run: `.lua/bin/busted lessons/01-hello/exercises`
Expected: the stub raises `TODO: implement greet so the tests pass` → `0 successes / 0 failures / 2 errors` (busted reports `error()` as an error). This is the intended red state students start from.

- [ ] **Step 6: Write `solutions/hello.lua` (the implementation)**

Overwrite `lessons/01-hello/solutions/hello.lua` with EXACTLY:
```lua
local M = {}

function M.greet(name)
  return "Hello, " .. name .. "!"
end

return M
```

- [ ] **Step 7: Write `solutions/hello_spec.lua` (identical spec)**

Overwrite `lessons/01-hello/solutions/hello_spec.lua` with EXACTLY the same content as `exercises/hello_spec.lua` (Step 4) — the `require("hello")` and both assertions are identical.

- [ ] **Step 8: Run the solution spec to verify it PASSES**

Run: `.lua/bin/busted lessons/01-hello/solutions`
Expected: `2 successes / 0 failures / 0 errors`.

- [ ] **Step 9: Run the integrated lesson target**

Run: `make test-lesson LESSON=01-hello`
Expected: exercises run errors (TODO, tolerated by the leading `-`), solutions run passes (2). Target exit 0.

- [ ] **Step 10: Commit**

```bash
git add lessons/01-hello/exercises lessons/01-hello/solutions
git commit -m "feat(lesson-01): add greet exercise + solution with busted specs"
```

---

## Task 2: Author the README and slide deck

**Files:**
- Modify: `lessons/01-hello/README.md` (overwrite)
- Modify: `lessons/01-hello/slides/slides.md` (overwrite)
- Modify: `lessons/01-hello/slides/index.html` (title only)

- [ ] **Step 1: Overwrite `lessons/01-hello/README.md`**

````markdown
# Lesson 01 — Hello, Lua

Your first Lua program. By the end you will have run Lua through the REPL,
written and called a function on a module table, and made a failing `busted`
test pass.

## Learning goals

- Provision the toolchain with `make bootstrap` and open the `lua` REPL
- Run Lua three ways: `lua file.lua`, `lua -e '...'`, and the REPL
- Write and call a function on a module table; build a string with `..`
- Use `print`; know that a Lua module file returns a table you `require`
- Read a `*_spec.lua` file as the spec and make a failing test pass

## Prereqs

- `make bootstrap` run once (see the [repo README](../../README.md)). No earlier lessons required.

## Concepts

**The toolchain.** `make bootstrap` builds a pinned Lua 5.4 into `./.lua` and
installs the test runner. `make test` runs the specs; `lua` opens an interactive
REPL where you can type expressions and see results.

**Functions and strings.** A function is defined with `function`. We hang it on a
table — `local M = {}; function M.greet(name) ... end; return M` — and build the
result by joining strings with `..`: `"Hello, " .. name .. "!"`.

**Modules return tables.** A `.lua` file is a chunk. When another file `require`s
it, Lua runs it once and hands back whatever it `return`s — here, the table `M`.
So `require("hello").greet("Aki")` calls our function. (The full story of
`require`/`package.path` is Lesson 12.)

**Tests are the spec.** Each `*_spec.lua` file says what "done" means. For now,
treat `busted` as a magic test runner that checks your work; we explain it
properly in Lesson 06. Your job: make the failing test pass.

## Exercise brief

Open `exercises/hello.lua` and implement `greet(name)` so it returns a greeting
like `"Hello, Aki!"`. Both examples in `exercises/hello_spec.lua` must pass. Run
the spec first to watch it fail, implement `greet`, then run it again until it is
green.

## How to run

Run the lesson's specs (exercises fail until you implement `greet`; solutions pass):

```bash
make test-lesson LESSON=01-hello
```

Try your function in the REPL (from the lesson's `solutions/` directory so
`require` finds the file):

```bash
cd lessons/01-hello/solutions
../../../.lua/bin/lua -e 'print(require("hello").greet("you"))'
```

## Going further

- Use `string.format("Hello, %s!", name)` instead of `..` (a teaser for Lesson 09).
- `lua -i hello.lua` loads the file, then drops you into the REPL with it available.
````

- [ ] **Step 2: Overwrite `lessons/01-hello/slides/slides.md`**

````markdown
## Lesson 01
### Hello, Lua

Run Lua, write your first function, make a test pass.

Note:
Goal: from zero to a passing busted spec and a greeting in the REPL.

---

## Why Lua

- Small — the whole language fits in your head
- Fast and embeddable — ships inside Neovim, games, OpenResty, Redis
- Portable — a tiny C core, runs almost anywhere

---

## The toolchain

`make bootstrap` installs a pinned Lua 5.4 into `./.lua`.

```bash
make bootstrap      # one time
make test           # run the specs
```

Open the REPL with `lua` and type expressions to try them.

Note:
bootstrap uses hererocks to build Lua + LuaRocks locally; nothing global.

---

## Running Lua

```bash
lua hello.lua             # run a script
lua -e 'print("hi")'      # run a one-liner
lua                       # the REPL (Ctrl-D to exit)
```

Comments: `-- single line`, `--[[ multi-line ]]`.

---

## Your first function

```lua
local M = {}

function M.greet(name)
  return "Hello, " .. name .. "!"
end

return M
```

- `local M = {}` — a table to hold our functions
- `..` joins strings
- `return M` — hand the table to whoever `require`s us

---

## print()

```bash
lua -e 'print(require("hello").greet("world"))'
# Hello, world!
```

`print` writes a line to the screen; strings join with `..`.

---

## Modules return tables

A `.lua` file is a chunk. `require` runs it once and gives you whatever it
`return`s — here, the table `M`.

```lua
local hello = require("hello")
print(hello.greet("Aki"))   -- Hello, Aki!
```

Note:
require/package.path is covered properly in Lesson 12. For now: return a table.

---

## Tests are the spec

```lua
describe("greet", function()
  it("greets by name", function()
    assert.are.equal("Hello, Aki!", hello.greet("Aki"))
  end)
end)
```

For now, busted is a magic test runner. Make the failing spec pass:

```bash
make test-lesson LESSON=01-hello
```

Note:
We explain busted properly in Lesson 06.

---

## Your turn → what's next

- Implement `greet` in `exercises/hello.lua` until the spec is green
- Try it in the REPL: `print(require("hello").greet("you"))`

**Next: Lesson 02 — Values & types.**
````

- [ ] **Step 3: Edit the deck title in `lessons/01-hello/slides/index.html`**

The scaffolder rendered `<title>Lesson 01 — Hello</title>` (slug-derived). Change that one line to:
```html
  <title>Lesson 01 — Hello, Lua</title>
```
Leave the rest of `index.html` unchanged (the absolute `/shared/reveal/...` paths and the `data-markdown="slides.md"` section are correct as scaffolded).

- [ ] **Step 4: Verify the deck serves locally**

Start the dev server in the background, curl it, then stop it:
```bash
make slides-dev LESSON=01-hello >/tmp/lt-l01.log 2>&1 &
sleep 1.5
curl -s http://127.0.0.1:8000/ | grep -o "<title>[^<]*</title>"
curl -s -o /dev/null -w "slidesmd=%{http_code}\n" http://127.0.0.1:8000/slides.md
pkill -f "slides-dev/main.lua"
```
Expected: `<title>Lesson 01 — Hello, Lua</title>` and `slidesmd=200`.

- [ ] **Step 5: Commit**

```bash
git add lessons/01-hello/README.md lessons/01-hello/slides
git commit -m "docs(lesson-01): author the README and slide deck"
```

---

## Task 3: Extend lint/fmt to lessons + final verification

**Files:**
- Modify: `Makefile` (`lint` and `fmt` recipes)
- Modify: `.luacheckrc` (add `unused_args = false`)

- [ ] **Step 1: Extend the `lint` and `fmt` Makefile targets to cover lessons**

In `Makefile`, change the `lint` recipe from `$(LUACHECK) tools` to `$(LUACHECK) tools lessons`, and the `fmt` recipe from `stylua tools` to `stylua tools lessons`. The two target blocks become:
```makefile
.PHONY: lint
lint: ## Run luacheck over the tools and lessons
	$(LUACHECK) tools lessons

.PHONY: fmt
fmt: ## Format Lua with StyLua (install separately: brew install stylua)
	stylua tools lessons
```
(Recipe lines use TABs.)

- [ ] **Step 2: Add `unused_args = false` to `.luacheckrc`**

In `.luacheckrc`, add the line `unused_args = false` directly under the existing `std = "lua54"` line, with a comment. The top of the file becomes:
```lua
-- luacheck configuration for lua-training.
std = "lua54"

-- Exercise stubs intentionally leave function arguments unused
-- (e.g. greet(name) that just errors), so don't warn on unused arguments.
unused_args = false
```
Leave the other existing entries (`max_line_length = false`, `read_globals`, the `files["**/*_spec.lua"]` block) unchanged.

- [ ] **Step 3: Verify `make lint` is clean and now covers the lesson**

Run: `make lint`
Expected: `0 warnings / 0 errors` — luacheck now scans `tools` + `lessons` (the 4 lesson `.lua` files included, the exercise stub's unused `name` no longer warned).

- [ ] **Step 4: Verify the full test suite**

Run: `make test`
Expected: `busted tools` → `42 successes`; then `== lessons/01-hello/solutions ==` → `2 successes`. Exit 0.

- [ ] **Step 5: Verify the static build publishes the lesson as a link**

```bash
make slides-build
grep -q '<a class="lesson" href="lessons/01-hello/slides/">' dist/index.html && echo "01-hello is a link"
grep -c 'class="lesson future"' dist/index.html   # expect 22 (23 total minus the now-published 01-hello)
grep -o "<title>[^<]*</title>" dist/lessons/01-hello/slides/index.html
test -f dist/lessons/01-hello/slides/slides.md && echo "deck copied"
rm -rf dist
```
Expected: `01-hello is a link`, `22`, `<title>Lesson 01 — Hello, Lua</title>`, `deck copied`.

- [ ] **Step 6: Commit**

```bash
git add Makefile .luacheckrc
git commit -m "build: lint/format lessons; allow unused args for exercise stubs"
```

- [ ] **Step 7: Final clean check**

Run: `git status --porcelain`
Expected: empty (no `dist/`, no stray `/tmp` logs, no leftover server). If a `slides-dev` server is still running, stop it (`pkill -f "slides-dev/main.lua"`).

---

## Self-review notes (run before reporting overall)

- `make test-lesson LESSON=01-hello` → exercises error (TODO), solutions pass, exit 0.
- `make test` → 42 tool + 2 solution successes.
- `make lint` → 0/0, covering the lesson.
- `make slides-build` → `01-hello` is a link; 22 future placeholders; deck title "Lesson 01 — Hello, Lua".
- No tool/scaffolder changes; module stays pure (no top-level I/O); single `greet` function.

## Notes for execution

- No `git push`, no `gcloud`, no `make bootstrap`. The `.lua/` toolchain is already in the working tree.
- The exercise spec failing is the *deliverable* (the student's starting point), not a bug — `make test-lesson` tolerates it via the leading `-`; `make test` only runs `solutions/`.
- After this plan, `lessons/01-hello/` is the first published lesson. Lesson 02 is a future plan.
