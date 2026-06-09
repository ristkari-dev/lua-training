# Lesson 02 — Values & types

Lua's value types, the integer/float distinction new in 5.4, and the truthiness
rule. You will implement `describe(value)` to name any value's type.

## Learning goals

- Name Lua's value types: nil, boolean, number, string, table, function
- Tell integers from floats with `math.type` (a 5.4 distinction)
- State the truthiness rule — only `nil` and `false` are falsy
- Inspect with `type` and convert with `tostring`/`tonumber`
- Make a failing `busted` spec pass by implementing `describe`

## Prereqs

- Lesson 01 (functions, modules, `busted`). Toolchain via `make bootstrap`.

## Concepts

**The value types.** `type(x)` returns a type name: `"nil"`, `"boolean"`,
`"number"`, `"string"`, `"table"`, `"function"`. (`thread` and `userdata` also
exist; we meet them later.)

**Integers and floats.** Lua 5.4 splits `number` into integer and float
subtypes. `3` is an integer, `3.0` a float; `math.type(x)` returns `"integer"`,
`"float"`, or `nil` if `x` is not a number. `/` always produces a float
(`6 / 2` is `3.0`); `//` floor-divides (more in Lesson 04).

**Truthiness.** In a boolean context, only `nil` and `false` are falsy —
**everything else is truthy, including `0` and `""`**. This is why
`math.type(value) or type(value)` works: for non-numbers `math.type` returns
`nil` (falsy), so `or` falls through to `type`.

**Converting.** `tostring(x)` gives a string (handy for printing/joining);
`tonumber(s)` parses a string to a number, or returns `nil` if it can't.

## Exercise brief

Implement `describe(value)` in `exercises/values.lua` so it returns the value's
kind: `"integer"` or `"float"` for numbers, and `"string"`/`"boolean"`/`"nil"`/
`"table"` otherwise. All six examples in `exercises/values_spec.lua` must pass.

## How to run

```bash
make test-lesson LESSON=02-values-types
```

Explore in the REPL (from the lesson's `solutions/` directory so `require` finds
the file):

```bash
cd lessons/02-values-types/solutions
../../../.lua/bin/lua -e 'local v = require("values"); print(v.describe(3), v.describe(3.0), v.describe("hi"))'
```

## Going further

- `tonumber("ff", 16)` parses in another base (→ 255).
- Integers wrap on overflow: `math.maxinteger + 1 == math.mininteger`.
- `string.format("%d", 42)` / `string.format("%g", 3.14)` as a typed alternative to `tostring` (teaser for Lesson 09).
