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
