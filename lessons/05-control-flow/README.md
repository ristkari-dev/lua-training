# Lesson 05 — Control flow

Branch with `if`/`elseif`/`else` and loop with `for`. You will implement
FizzBuzz — the classic exercise that needs both.

## Learning goals

- Branch with `if`/`elseif`/`else`
- Loop with the numeric `for`; recognize `while` and `repeat`/`until`
- Recognize the generic `for` (a teaser for Lesson 08) and `break`
- Know Lua has no `continue`, and the idioms for it
- Implement `fizzbuzz(n)` to make a failing `busted` spec pass

## Prereqs

- Lessons 01–02. Toolchain via `make bootstrap`.

## Concepts

**Branching.** `if cond then … elseif cond then … else … end` — no parentheses
around conditions, and every block ends with `end`. Comparisons are `==`, `~=`
(not `!=`), `<`, `<=`, `>`, `>=`. Recall from Lesson 02 that only `nil` and
`false` are falsy, so `if x then` runs even when `x` is `0` or `""`.

**Looping.** Three loops: the numeric `for i = start, stop[, step] do … end`
(runs zero times if `start > stop`); the top-tested `while cond do … end`; and
the bottom-tested `repeat … until cond` (runs at least once). The generic
`for k, v in pairs(t) do` iterates tables — a teaser; the full story is Lesson 08.

**break and continue.** `break` exits the nearest loop. Lua has **no
`continue`** — skip an iteration with an `if`/`else`, or jump to a label at the
loop's end: `if skip then goto next end … ::next::`.

**FizzBuzz ordering.** Check `i % 15 == 0` **before** `% 3` and `% 5` — 15 is a
multiple of both, so a later branch would otherwise win.

## Exercise brief

Implement `fizzbuzz(n)` in `exercises/control_flow.lua` so it returns the
FizzBuzz lines for `1..n` joined by `"\n"`: numbers become themselves, multiples
of 3 become `"Fizz"`, of 5 `"Buzz"`, of 15 `"FizzBuzz"`. All five examples in
`exercises/control_flow_spec.lua` must pass.

## How to run

```bash
make test-lesson LESSON=05-control-flow
```

Explore in the REPL (from the lesson's `solutions/` directory):

```bash
cd lessons/05-control-flow/solutions
../../../.lua/bin/lua -e 'print(require("control_flow").fizzbuzz(15))'
```

## Going further

- Lua has no `continue`; the `goto ::continue::` label idiom fills the gap.
- A numeric `for`'s loop variable is local to the loop — reassigning it inside the body doesn't change the iteration.
- `repeat … until` can reference locals declared inside the body in its `until` condition (unusual scoping).
