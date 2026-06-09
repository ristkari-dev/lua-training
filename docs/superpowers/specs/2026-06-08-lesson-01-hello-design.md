# Lesson 01 — Hello, Lua — Design

**Status:** Approved (brainstorming complete, awaiting implementation plan)
**Date:** 2026-06-08
**Owner:** Aki Ristkari

## Summary

The first course lesson, built on the Plan A foundation + Plan B slide pipeline (both merged). Lesson 01 ("Hello, Lua") is the gentlest possible introduction: students implement a single `greet(name)` function on a module table to make a failing `busted` spec pass. Lua has no `__main__`, and the spec `require`s the module, so the module stays **pure** (no top-level I/O) — `print`, the REPL, and running scripts are taught in the README/slides and exercised interactively (`lua`, `lua -e`), not via a runnable block in the module. This lesson doubles as the first end-to-end validation of the lesson workflow (scaffold → author → test → build → publish): once it lands, `01-hello` lights up as a link on the landing page instead of a faded placeholder.

No test-harness fix is needed (unlike the sibling python course): Plan A's Makefile already runs each lesson's specs in isolated `busted` processes, so same-named lesson modules never collide.

## Learning goals

1. Provision and verify the toolchain with `make bootstrap`; open the `lua` REPL.
2. Run Lua three ways: a script (`lua file.lua`), a one-liner (`lua -e`), and the REPL.
3. Write and call a function on a module table; build a string with concatenation (`..`).
4. Use `print` to write output; know that a Lua module file returns a table you `require`.
5. Read a `*_spec.lua` file as the spec and make a failing `busted` test pass.

## Files

Lesson directory `lessons/01-hello/` (scaffolded via `make new-lesson NAME=01-hello`, then hand-authored). The scaffolder emits `main.lua`/`main_spec.lua` with a no-arg `hello()`; lesson 01 **renames these to `hello.lua`/`hello_spec.lua`** and uses the `greet` exercise below (meaningful names match the family convention — python used `hello.py`).

```
lessons/01-hello/
├── README.md
├── slides/
│   ├── index.html          # reveal.js bootstrap (from scaffold; deck title authored to "Hello, Lua")
│   ├── slides.md           # the deck (authored)
│   └── assets/.gitkeep
├── exercises/
│   ├── hello.lua           # greet() stub (errors)
│   └── hello_spec.lua      # failing busted spec for greet()
└── solutions/
    ├── hello.lua           # greet() implemented
    └── hello_spec.lua      # identical spec, passes
```

### `exercises/hello.lua`

```lua
local M = {}

function M.greet(name)
  error("TODO: implement greet so the tests pass")
end

return M
```

### `exercises/hello_spec.lua`

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

### `solutions/hello.lua`

```lua
local M = {}

function M.greet(name)
  return "Hello, " .. name .. "!"
end

return M
```

### `solutions/hello_spec.lua`

Identical to `exercises/hello_spec.lua` (same `require("hello")`, same two assertions). The spec sits beside its `hello.lua`, so `package.path = here .. "?.lua"` resolves `require("hello")` within the same directory; `make test` runs `exercises/` and `solutions/` in separate `busted` processes, so the shared module name `hello` never collides.

### Modules, not `__main__`

Python's lesson 01 used the same file as both importable and runnable via `if __name__ == "__main__":`. Lua has no equivalent, and `require("hello")` executes the whole chunk — so a top-level `print`/`io.read` would run during the test. Therefore `hello.lua` is a **pure module**: it defines `greet` and returns the table, nothing more. The "running Lua" concepts are taught and demonstrated outside the module:

- **REPL:** `lua` → `local hello = require("hello"); print(hello.greet("you"))` (run from inside `lessons/01-hello/solutions/` so `require("hello")` finds the file).
- **One-liner:** `lua -e 'print(require("hello").greet("world"))'` (same cwd).
- The deeper module mechanics (`require` runs a file once and caches its returned table; `package.path`) are introduced lightly here and covered fully in Lesson 12.

## Slides (`slides/slides.md`)

~9 slides, `---`-separated, code in fenced ` ```lua ` blocks, ~15 visible lines max per code slide, `Note:` speaker notes where useful.

1. **Title** — "Lesson 01 — Hello, Lua" + one-line goal.
2. **Why Lua** — small, fast, embeddable, everywhere (Neovim, games, OpenResty, Redis) — brief.
3. **The toolchain** — `make bootstrap` provisions Lua 5.4 into `./.lua`; the `lua` REPL; `make test`.
4. **Running Lua** — `lua file.lua`, `lua -e '...'`, the REPL; comments (`--`, `--[[ ]]`).
5. **Your first function** — `local M = {}; function M.greet(name) return "Hello, " .. name .. "!" end; return M`; covers `local`, defining a function on a table, `..` concatenation.
6. **`print`** — `lua -e 'print("hi")'`; printing the greeting.
7. **Modules return tables** — a `.lua` file returns a table; `require` runs it once and gives you that table (brief; full story in Lesson 12).
8. **Tests are the spec** — show `hello_spec.lua`, `describe`/`it`/`assert.are.equal`; "busted is a magic test runner for now" (explained in Lesson 06); `make test-lesson LESSON=01-hello`.
9. **The exercise + what's next** — make the failing spec pass; pointer to Lesson 02 (Values & types).

## README (`README.md`)

Sections per the four-file convention:

- **Learning goals** — the five bullets above.
- **Prereqs** — `make bootstrap` run once (link to the repo root README); no prior lessons.
- **Concepts** — 1–3 short paragraphs mirroring the deck: the toolchain + REPL; `local` + functions on a table + `..`; `print`; modules return tables (`require`); busted as the spec ("magic test runner", explained in Lesson 06).
- **Exercise brief** — implement `greet` in `exercises/hello.lua` so both specs pass; then call it in the REPL to see it work.
- **How to run:**
  - Tests: `make test-lesson LESSON=01-hello` (or `cd lessons/01-hello && ../../.lua/bin/busted exercises`).
  - REPL: from `lessons/01-hello/solutions/`, `../../../.lua/bin/lua` then `print(require("hello").greet("you"))` — or `lua -e '...'` if a system `lua` is on PATH.
- **Going further** — kept light, no new graded work: `string.format("Hello, %s!", name)` as an alternative to `..` (teaser for Lesson 09), `lua -i` to load a file then drop into the REPL.

## Harness adjustment (the first lesson landing)

Plan A scoped `make lint`/`make fmt` to `tools/` only (there were no lessons yet, and `luacheck .` would scan the gitignored `.lua/` toolchain). With the first lesson, extend them to cover lesson code:

- **`Makefile`:** `lint` → `$(LUACHECK) tools lessons`; `fmt` → `stylua tools lessons`.
- **`.luacheckrc`:** add `unused_args = false`. The exercise stub `function M.greet(name) error(...) end` has an intentionally-unused `name`; without this, `luacheck` would warn. Disabling unused-argument warnings is a common, reasonable setting for a teaching repo full of stubs (the tools currently have no unused args, so this doesn't change their results).

No `ci.yml` change is needed: it already runs `make lint`, `make test` (which loops lesson `solutions/`), and `make slides-build`, so the lesson is automatically linted, its solution gated green, and its deck built.

## Verification (success criteria)

- `make test-lesson LESSON=01-hello` → exercise spec FAILS (`TODO` error from the stub), solution spec PASSES (2 examples), target exit 0 (exercise failure tolerated by the leading `-`).
- `make test` → tools suite (42) passes and `01-hello` solutions (2) pass, in isolated per-lesson processes.
- `make lint` → clean, now covering `lessons/01-hello`.
- `make slides-build` → `dist/index.html` shows `01-hello` as a **link** (no longer a faded "future" placeholder); `dist/lessons/01-hello/slides/index.html` exists and its `<title>` is "Lesson 01 — Hello, Lua".
- `make slides-dev LESSON=01-hello` → the deck renders locally.
- CI on the PR is green (bootstrap → lint → test → slides-build).

## Non-goals

- No top-level I/O / runnable block in the module (Lua has no `__main__`; the module stays pure for the test).
- No control flow / `if` in the exercise (Lesson 03).
- No `string.format` in the exercise — concatenation with `..` is the lesson-01 idiom (`string.format` and patterns are Lesson 09).
- No formal busted teaching (`before_each`, spies) — that is Lesson 06; here busted is a "magic test runner".
- No changes to the `new-lesson`, `slides-dev`, or `build-index` tools.
- No multiple functions or a second exercise — one `greet` keeps lesson 01 the gentlest.

## Open items deferred to implementation planning

- Exact wording/voice of the slide prose and README concept paragraphs.
- Whether the README's REPL instructions reference the repo-local `.lua/bin/lua` explicitly or assume a system `lua` on PATH (default: show the `.lua/bin/lua` form, since that is what `make bootstrap` provides and is guaranteed present).
