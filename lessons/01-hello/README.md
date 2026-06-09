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
