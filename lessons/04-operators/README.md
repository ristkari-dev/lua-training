# Lesson 04 — Operators & expressions

Every operator Lua has, and what each one returns. You will implement
`page_label()` using nothing but expressions — `if` arrives in Lesson 05.

## Learning goals

- Use the arithmetic operators: `/` always gives a float, `//` floor-divides, `%` is the matching remainder, `^` is a float and right-associative
- Compare with `==`, `~=`, `<`, `<=`, `>`, `>=` — different types are never equal, but ordering them is an error
- Use `and`/`or`/`not`, which return an operand rather than a boolean, and write the `a and b or c` idiom — including when it breaks
- Join with `..` (numbers coerce) and measure with `#` (bytes, not characters)
- Read the bitwise operators `&`, `|`, `~`, `<<`, `>>` — integers only in 5.4
- Know where parentheses are required, and where adding them changes the answer
- Implement `page_label()` to make a failing `busted` spec pass

## Prereqs

- Lessons 01–03. Toolchain via `make bootstrap`.

## Concepts

**Arithmetic.** `/` always produces a float, even when it divides evenly: `6 / 3` is
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

**Bitwise.** Lua 5.4 has `&`, `|`, `~` (xor as a binary operator, not as a unary one),
`<<` and `>>`. They work on integers only — `3.0 & 1` is fine because `3.0` has an
integer value, but `3.5 & 1` raises `number has no integer representation`.

**Precedence.** `^` binds tightest and `or` loosest. Two rules matter for the
exercise: `+` and `..` both bind tighter than `and`/`or`, so the idiom needs
parentheses around it; and `&` binds tighter than `~=`.

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

- The other ceiling idiom: `(items + per_page - 1) // per_page`, and the terser `-(-items // per_page)`. Both avoid the remainder term.
- Permissions from bits, all operators: `(flags & 4 ~= 0 and "r" or "-") .. (flags & 2 ~= 0 and "w" or "-") .. (flags & 1 ~= 0 and "x" or "-")` turns `6` into `rw-`. It needs no parentheses around the `&` because `&` binds tighter than `~=`.
- `#` counts bytes, so `#"Äiti"` is `5`. Counting characters needs `utf8.len` (Lesson 17).
