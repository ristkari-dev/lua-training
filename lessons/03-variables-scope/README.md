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
the first as `shadowing upvalue 'n'` ("upvalue" means a local from an enclosing
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
