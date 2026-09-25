# Lesson 06 — Functions & testing

Lua functions take and return any number of values. You will implement
`tally(check, ...)` — and this is the lesson where `busted` stops being magic.

## Learning goals

- Return several values, and know that the caller decides how many to keep
- Know where a call is cut to one value: mid-list, in parentheses, or on the right of a single-name assignment
- Take any number of arguments with `...`, count them with `select("#", ...)`, reach one with `select(i, ...)`
- Pass a function as an argument and call it — functions are values
- Give an argument a default with `name = name or fallback`, and know when that is unsafe
- Read a `busted` spec: `describe`, `it`, `assert`, `before_each`, and spies
- Implement `tally(check, ...)` to make a failing spec pass

## Prereqs

- Lessons 01–05. Toolchain via `make bootstrap`.

## Concepts

**Several values.** `return passed, failed` returns two values, and the caller
decides what to do with them: `local a, b = tally(...)` keeps both, `local a =`
keeps the first, and asking for more than a function returns gives `nil`. Only the
last expression in a list expands — `print(split(), 9)` prints `1  9`, while
`print(9, split())` prints `9  1  2`.

**Parentheses mean one value.** `(split())` is the first value only. The same rule
is why `return (a, b)` will not compile: grouping asks for a single value.

**Varargs.** `function M.tally(check, ...)` accepts anything after `check`. `...` is
not a table — it is the remaining arguments, as values.

**Counting and reaching.** `select("#", ...)` is how many arguments there are,
**including trailing `nil`s**: `select("#", 1, nil, nil)` is `3`. `select(i, ...)`
returns the i-th argument *and every one after it*, so `check((select(i, ...)))` —
or `local value = select(i, ...)` — is what hands over exactly one.

**Functions are values.** A function can live in a local, be passed as an argument,
or be returned by another function. `check` is an ordinary parameter you can call.

**Defaults.** Lua has no default-argument syntax; `check = check or truthy` is the
idiom. It is safe for `0`, which is truthy in Lua, but not for `false` —
`false or "fallback"` is `"fallback"`. When `false` is a legitimate value, write
`if flag == nil then flag = true end` instead.

**busted.** `describe` groups examples, `it` names one behaviour, `assert` decides.
`before_each` runs before every `it` in its block, so each example starts from fresh
state. A **spy** wraps a function and records every call to it, which lets a test
assert *how* your code called something — `was.called(3)`, `was.called_with(5)`,
`was_not.called()` — rather than only what it returned.

## Exercise brief

Implement `tally(check, ...)` in `exercises/functions.lua`. It returns two numbers:
how many of the values passed `check`, and how many failed. With no `check` given, a
value passes when it is truthy.

Two parts of the contract are graded by spies, so they are worth stating outright:
**call `check` once per value, in order — including values that are `nil` — with
exactly one argument.** Watch the truncation rule here: `check(select(i, ...))` hands
the check the i-th value *and every value after it*; `check((select(i, ...)))` or
`local value = select(i, ...)` fixes it.

**Varargs only: no `{...}`, no `table.pack` (both Lesson 08), and no fixed list of
named parameters either — you do not know how many values there will be.**
`table.pack(...).n` gives the same answer and the tests cannot tell — but
`select("#", ...)` costs nothing and is the point of this lesson.

You are done when `make test-lesson LESSON=06-functions-testing` passes **and**
`make lint` is clean.

## How to run

```bash
make test-lesson LESSON=06-functions-testing
make lint
```

Explore in the REPL (from the lesson's `solutions/` directory so `require` finds the
file):

```bash
cd lessons/06-functions-testing/solutions
../../../.lua/bin/lua -e 'print(require("functions").tally(nil, 1, false, "x"))'
```

That prints `2	1` — two values, from one call.

## Going further

- The loop is not the only way. A recursive peel works too: pass the count along, take one value per call, and stop at zero. It never builds a table either.
- `select(-1, ...)` gives the last argument, and negative indexes count back from the end.
- Forwarding matters: `f(1, ...)` passes everything, but `f(..., 1)` cuts `...` down to its first value, because it is no longer last in the list.
