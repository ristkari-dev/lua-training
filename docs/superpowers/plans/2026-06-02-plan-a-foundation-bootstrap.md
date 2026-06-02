# Plan A — Foundation Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bootstrap the `lua-training` repo with a working Lua 5.4 toolchain (`hererocks` + `busted` + `luacheck` + `StyLua`), vendored reveal.js, a custom theme, a lesson scaffolder, a local slides dev server, a Makefile, and contributor docs — so that `make new-lesson NAME=99-demo` produces a working lesson and `make slides-dev LESSON=99-demo` serves it locally.

**Architecture:** No package-manager workspace (Lua has no `uv`/`cargo` equivalent). A repo-local Lua 5.4 + LuaRocks tree is provisioned by `hererocks` into `./.lua/` via `scripts/bootstrap`; the pinned dev rocks (`busted`, `luacheck`, `luafilesystem`, `luasocket`) install into that tree. Two small Lua programs live under `tools/`: `new-lesson` (generates a lesson folder from an on-disk template tree) and `slides-dev` (a `luasocket`-based static server that mounts the lesson's `slides/` plus the shared `reveal/` assets). Each tool is a plain module + a thin CLI + `busted` specs. Reveal.js 5.1.0 is vendored under `shared/reveal/` and shared across all decks. A single Makefile is the canonical entry point. No npm, no Node — Lua + vendored static assets only.

**Tech Stack:** Lua 5.4.7 (PUC-Rio), LuaRocks 3.11.1 (via `hererocks`), `busted` 2.2.0, `luacheck` 1.2.0, `luafilesystem` 1.8.0, `luasocket` 3.1.0, StyLua (separate binary), reveal.js 5.1.0 (vendored), GNU Make.

---

## File Structure

After this plan completes, the repo contains:

```
lua-training/
├── README.md                                   (Task 10)
├── CONTRIBUTING.md                             (Task 10)
├── Makefile                                    (Task 9)
├── .gitignore                                  (Task 1)
├── .editorconfig                               (Task 1)
├── .luacheckrc                                 (Task 1)
├── stylua.toml                                 (Task 1)
├── .busted                                     (Task 1)
├── scripts/
│   └── bootstrap                               (Task 1; executable)
│
├── shared/
│   └── reveal/                                 (Task 2)
│       ├── LICENSE
│       ├── VERSION
│       ├── dist/                               (vendored reveal.js distributables)
│       ├── plugin/                             (vendored reveal.js plugins)
│       └── theme/
│           └── lua-training.css                (Task 3)
│
├── tools/
│   ├── new-lesson/
│   │   ├── new_lesson.lua                      (Task 5; the module)
│   │   ├── main.lua                            (Task 6; the CLI)
│   │   ├── spec/
│   │   │   └── new_lesson_spec.lua             (Task 5)
│   │   └── template/                           (Task 4)
│   │       ├── README.md.tmpl
│   │       ├── slides/
│   │       │   ├── index.html.tmpl
│   │       │   ├── slides.md.tmpl
│   │       │   └── assets/
│   │       │       └── .gitkeep
│   │       ├── exercises/
│   │       │   ├── main.lua.tmpl
│   │       │   └── main_spec.lua.tmpl
│   │       └── solutions/
│   │           ├── main.lua.tmpl
│   │           └── main_spec.lua.tmpl
│   └── slides-dev/
│       ├── server.lua                          (Task 7; the module)
│       ├── main.lua                            (Task 8; the CLI)
│       └── spec/
│           └── server_spec.lua                 (Task 7)
│
├── lessons/                                    (created empty in Task 9; .gitkeep)
│
└── docs/
    └── superpowers/
        ├── specs/                              (already exists)
        └── plans/                              (already exists; this file)
```

### Decomposition rationale

- `new_lesson.lua` holds two responsibilities as functions on a returned table: `parse_name` (input validation + title derivation) and `scaffold` (filesystem + template rendering). `main.lua` is thin CLI wiring (`os.exit`). Each is testable in isolation; the module fits on one screen.
- `slides-dev/server.lua` keeps the pure logic — `resolve_lesson`, `resolve`, `guess_content_type` — separate from `main.lua`'s socket accept-loop, so the routing logic is unit-tested without binding a socket. The live socket path is exercised by a `curl` smoke test in Task 11.
- Templates live under `tools/new-lesson/template/` and are resolved at runtime relative to the module's own file (via `debug.getinfo`). `.tmpl` files are rendered with a tiny `${var}` substitution; non-`.tmpl` files (e.g. `.gitkeep`) are copied verbatim.

### How modules are found at runtime (no package manager)

Lua resolves `require("x")` via `package.path`. Because there is no workspace installer, each entry point prepends its own directory to `package.path` before requiring siblings:

- A **CLI** computes its directory from `arg[0]`: `local here = arg[0]:match("^(.*/)") or "./"`.
- A **spec** computes its directory from `debug.getinfo(1, "S").source`.

This makes `require("new_lesson")` / `require("server")` / `require("main")` resolve regardless of the current working directory. Module *names* are unique per process, so `busted tools` (one process for both tools) is safe. Lesson specs reuse the name `main` across `exercises/` and `solutions/`, so those are always run in **separate `busted` processes** (one per lesson directory) — the Makefile enforces this.

---

## Conventions used by this plan

- **Working directory:** `/Users/ristkari/code/private/lua-training/` for every command. Do not `cd` elsewhere unless a step says so.
- **Commit messages:** Conventional Commits (`feat:`, `chore:`, `docs:`, `test:`, `build:`).
- **Toolchain prerequisite:** `hererocks` must be installed once on the machine (`pipx install hererocks`, or `python3 -m pip install --user hererocks`). It builds Lua from source, so a C compiler + `make` must be present (on macOS: `xcode-select --install`). Versions are pinned in `scripts/bootstrap` and can be bumped there.
- **Run tools/tests through the bootstrapped binaries:** `.lua/bin/lua`, `.lua/bin/busted`, `.lua/bin/luacheck`. The Makefile wraps these. `make bootstrap` (Task 1) must succeed before Tasks 5–11.
- **StyLua** is installed separately (`brew install stylua`); it is not a rock.
- **Repo state at start:** one commit (`73bafb9`) containing only `docs/superpowers/specs/2026-06-02-lua-course-design.md`, on branch `main`. The `.claude/` directory exists and is left untouched (not committed by this plan).
- **Reveal.js version:** 5.1.0 — pinned. Already vendored in the sibling `python-training` repo at `/Users/ristkari/code/private/python-training/shared/reveal/`; copying from there is the recommended path in Task 2.

---

## Task 1: Base config files and the bootstrap toolchain

**Files:**
- Create: `.gitignore`
- Create: `.editorconfig`
- Create: `.luacheckrc`
- Create: `stylua.toml`
- Create: `.busted`
- Create: `scripts/bootstrap` (executable)

- [ ] **Step 1: Create `.gitignore`**

```gitignore
# hererocks-managed Lua 5.4 + LuaRocks toolchain
/.lua/

# generated static slide site (Plan B)
/dist/

# test/coverage artifacts
luacov.*.out

# macOS
.DS_Store
```

- [ ] **Step 2: Create `.editorconfig`**

```ini
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = space
indent_size = 2

[Makefile]
indent_style = tab
```

- [ ] **Step 3: Create `stylua.toml`**

```toml
column_width = 100
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferDouble"
call_parentheses = "Always"
```

- [ ] **Step 4: Create `.luacheckrc`**

```lua
-- luacheck configuration for lua-training.
std = "lua54"

-- The standalone interpreter provides `arg`; tools read it.
read_globals = { "arg" }

-- busted spec files use describe/it/assert/before_each/... globals.
files["**/*_spec.lua"] = {
  std = "+busted",
}
```

- [ ] **Step 5: Create `.busted`**

```lua
-- busted default configuration.
-- The Makefile passes explicit ROOT directories (per-lesson isolation), so this
-- only fixes the spec filename pattern and per-file insulation.
--
-- The pattern matches files ENDING in "_spec.lua" (anchored with $), NOT the
-- looser default "_spec". This matters because the new-lesson template ships
-- `main_spec.lua.tmpl` files: the loose pattern would match those and busted
-- would try to load a .tmpl as Lua (it contains `${number}`) and crash.
return {
  default = {
    pattern = "_spec%.lua$",
    ["auto-insulate"] = true,
  },
}
```

- [ ] **Step 6: Create `scripts/bootstrap`**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Provision a repo-local Lua 5.4 + LuaRocks toolchain via hererocks, then install
# the pinned dev rocks. Re-runnable: hererocks recreates the env, luarocks no-ops
# rocks that are already at the requested version.

LUA_VERSION="${LUA_VERSION:-5.4.7}"
LUAROCKS_VERSION="${LUAROCKS_VERSION:-3.11.1}"
ENV_DIR="${ENV_DIR:-.lua}"

BUSTED_VERSION="${BUSTED_VERSION:-2.2.0}"
LUACHECK_VERSION="${LUACHECK_VERSION:-1.2.0}"
LFS_VERSION="${LFS_VERSION:-1.8.0}"
LUASOCKET_VERSION="${LUASOCKET_VERSION:-3.1.0}"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }

if ! command -v hererocks >/dev/null 2>&1; then
  bold "hererocks not found. Install it once, then re-run 'make bootstrap':"
  echo "  pipx install hererocks                 # recommended"
  echo "  # or: python3 -m pip install --user hererocks"
  exit 1
fi

bold "Installing Lua ${LUA_VERSION} + LuaRocks ${LUAROCKS_VERSION} into ${ENV_DIR}/"
hererocks "${ENV_DIR}" --lua "${LUA_VERSION}" --luarocks "${LUAROCKS_VERSION}"

ROCKS="${ENV_DIR}/bin/luarocks"
bold "Installing pinned rocks"
"${ROCKS}" install busted "${BUSTED_VERSION}"
"${ROCKS}" install luacheck "${LUACHECK_VERSION}"
"${ROCKS}" install luafilesystem "${LFS_VERSION}"
"${ROCKS}" install luasocket "${LUASOCKET_VERSION}"

bold "Done."
echo "Toolchain installed in ${ENV_DIR}/bin (lua, luarocks, busted, luacheck)."
echo "StyLua is a separate binary — install with: brew install stylua"
```

- [ ] **Step 7: Make the bootstrap script executable**

Run: `chmod +x scripts/bootstrap`
Then verify it parses: `bash -n scripts/bootstrap && echo "syntax ok"`
Expected: `syntax ok`.

- [ ] **Step 8: Run the bootstrap**

Run: `make bootstrap` is not available yet (the Makefile lands in Task 9), so run the script directly:
`./scripts/bootstrap`

Expected: hererocks builds Lua 5.4.7 and installs LuaRocks under `.lua/`, then the four rocks install. Takes ~1–3 minutes. If it prints "hererocks not found", install hererocks (`pipx install hererocks`) and re-run.

- [ ] **Step 9: Verify the toolchain**

Run: `.lua/bin/lua -v`
Expected: `Lua 5.4.7  Copyright ...`.

Run: `.lua/bin/busted --version`
Expected: prints a version (e.g. `2.2.0`).

Run: `.lua/bin/luacheck --version`
Expected: prints a version (e.g. `1.2.0`).

Run: `.lua/bin/lua -e "require('lfs'); require('socket'); print('rocks ok')"`
Expected: `rocks ok`.

- [ ] **Step 10: Commit (the `.lua/` tree is gitignored, so it is not added)**

```bash
git add .gitignore .editorconfig .luacheckrc stylua.toml .busted scripts/bootstrap
git commit -m "chore: add Lua 5.4 toolchain bootstrap and tool configs"
```

---

## Task 2: Vendor reveal.js 5.1.0

**Files:**
- Create: `shared/reveal/dist/...`
- Create: `shared/reveal/plugin/...`
- Create: `shared/reveal/LICENSE`
- Create: `shared/reveal/VERSION`

The sibling `python-training` repo at `/Users/ristkari/code/private/python-training/shared/reveal/` already contains the vendored reveal.js 5.1.0 tree. Copy from there.

- [ ] **Step 1: Verify the source exists**

Run: `ls /Users/ristkari/code/private/python-training/shared/reveal/`
Expected: lists `LICENSE`, `VERSION`, `dist`, `plugin`, `theme`.

Run: `head -1 /Users/ristkari/code/private/python-training/shared/reveal/VERSION`
Expected: starts with `reveal.js 5.1.0`.

- [ ] **Step 2: Copy `dist/`, `plugin/`, `LICENSE` into `shared/reveal/`**

Run:
```bash
mkdir -p shared/reveal
cp -R /Users/ristkari/code/private/python-training/shared/reveal/dist shared/reveal/
cp -R /Users/ristkari/code/private/python-training/shared/reveal/plugin shared/reveal/
cp /Users/ristkari/code/private/python-training/shared/reveal/LICENSE shared/reveal/LICENSE
```

> **Do not copy `theme/`** — that holds the python-training theme; we ship our own in Task 3.

- [ ] **Step 3: Write `shared/reveal/VERSION`**

```
reveal.js 5.1.0
Source: https://github.com/hakimel/reveal.js/releases/tag/5.1.0
Vendored: 2026-06-02
Upgrade: re-download the tarball, replace dist/ and plugin/, update this file.
```

- [ ] **Step 4: Spot-check key files**

Run: `ls shared/reveal/dist/`
Expected: includes `reveal.css`, `reveal.js`, `reveal.esm.js`, `reset.css`, `theme/`.

Run: `ls shared/reveal/plugin/`
Expected: includes `markdown`, `highlight`, `notes`, `search`.

- [ ] **Step 5: Commit**

```bash
git add shared/reveal/
git commit -m "build: vendor reveal.js 5.1.0 under shared/reveal/"
```

---

## Task 3: Add the custom slide theme

**Files:**
- Create: `shared/reveal/theme/lua-training.css`

Minimal functional theme: imports reveal.js's `black` base, overrides the accent palette to Lua's deep blue (`#000080`) with a lighter blue highlight (`#5577c9`), and enlarges code blocks for live coding. Theme polish is intentionally deferred.

- [ ] **Step 1: Create `shared/reveal/theme/lua-training.css`**

```css
/*
 * lua-training reveal.js theme — Lua-branded dark
 *
 * Minimal baseline: imports the upstream `black` theme and overrides the accent
 * palette + code-block typography for readability during live coding. Theme
 * polish (custom fonts, slide patterns) is deferred to a later plan.
 *
 * The @import is relative to THIS file's location (shared/reveal/theme/),
 * so it works whether served by slides-dev or from the built dist/.
 */

@import url("../dist/theme/black.css");

:root {
  --lua-blue: #000080;
  --lua-accent: #5577c9;
}

.reveal {
  --r-link-color: var(--lua-accent);
  --r-link-color-hover: #ffffff;
  --r-selection-background-color: var(--lua-accent);
  --r-selection-color: #ffffff;
  --r-heading-color: #ffffff;
}

.reveal h1,
.reveal h2,
.reveal h3 {
  text-transform: none;
  letter-spacing: -0.01em;
}

.reveal pre {
  font-size: 0.7em;
  line-height: 1.4;
  box-shadow: none;
  border-left: 4px solid var(--lua-accent);
}

.reveal pre code {
  padding: 1em 1.2em;
  max-height: 600px;
}

.reveal code {
  background: rgba(85, 119, 201, 0.12);
  border-radius: 3px;
  padding: 0.1em 0.3em;
}
```

- [ ] **Step 2: Verify the file is non-empty and readable**

Run: `.lua/bin/lua -e "local f=assert(io.open('shared/reveal/theme/lua-training.css')); assert(#f:read('*a') > 0); f:close(); print('ok')"`
Expected: `ok`.

- [ ] **Step 3: Commit**

```bash
git add shared/reveal/theme/lua-training.css
git commit -m "feat(theme): add minimal lua-training reveal.js theme"
```

---

## Task 4: Create the `new-lesson` template tree

**Files:**
- Create: `tools/new-lesson/template/README.md.tmpl`
- Create: `tools/new-lesson/template/slides/index.html.tmpl`
- Create: `tools/new-lesson/template/slides/slides.md.tmpl`
- Create: `tools/new-lesson/template/slides/assets/.gitkeep`
- Create: `tools/new-lesson/template/exercises/main.lua.tmpl`
- Create: `tools/new-lesson/template/exercises/main_spec.lua.tmpl`
- Create: `tools/new-lesson/template/solutions/main.lua.tmpl`
- Create: `tools/new-lesson/template/solutions/main_spec.lua.tmpl`

Templated files use `${name}`, `${number}`, `${title}` placeholders (substituted by `scaffold` in Task 5). The `.tmpl` suffix is stripped on render. Non-`.tmpl` files (`.gitkeep`) are copied verbatim.

- [ ] **Step 1: Create `tools/new-lesson/template/README.md.tmpl`**

````markdown
# Lesson ${number} — ${title}

## Learning goals

- TODO: 3-5 bullets.

## Prereqs

- TODO: links to earlier lessons.

## Concepts

TODO: 1-3 paragraphs mirroring the deck narrative for self-study.

## Exercise brief

TODO: what students build; what `busted` should show when done.

## How to run

```bash
make test-lesson LESSON=${name}
```

## Going further

- TODO: optional advanced material (e.g. LuaLS `---@` annotation practice).
````

- [ ] **Step 2: Create `tools/new-lesson/template/slides/index.html.tmpl`**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
  <title>Lesson ${number} — ${title}</title>
  <link rel="stylesheet" href="/shared/reveal/dist/reveal.css">
  <link rel="stylesheet" href="/shared/reveal/theme/lua-training.css">
  <link rel="stylesheet" href="/shared/reveal/plugin/highlight/monokai.css">
</head>
<body>
  <div class="reveal">
    <div class="slides">
      <section data-markdown="slides.md"
               data-separator="^---$"
               data-separator-vertical="^--$"
               data-separator-notes="^Note:"></section>
    </div>
  </div>
  <script type="module">
    import Reveal from "/shared/reveal/dist/reveal.esm.js";
    import Markdown from "/shared/reveal/plugin/markdown/markdown.esm.js";
    import Highlight from "/shared/reveal/plugin/highlight/highlight.esm.js";
    import Notes from "/shared/reveal/plugin/notes/notes.esm.js";
    import Search from "/shared/reveal/plugin/search/search.esm.js";
    Reveal.initialize({
      hash: true,
      plugins: [Markdown, Highlight, Notes, Search]
    });
  </script>
</body>
</html>
```

> **Absolute `/shared/...` paths** are deliberate: the same `index.html` is served at `/` by `slides-dev` and at `/lessons/NN-slug/slides/` in the deployed site, and absolute paths resolve correctly in both. `data-markdown="slides.md"` stays relative so it loads from the deck's own directory.

- [ ] **Step 3: Create `tools/new-lesson/template/slides/slides.md.tmpl`**

```markdown
## Lesson ${number}
### ${title}

One-line learning goal goes here.

Note:
Speaker notes go here.

---

## What's next

A pointer to the next lesson.
```

- [ ] **Step 4: Create `tools/new-lesson/template/slides/assets/.gitkeep`**

(Empty file. Tracks the otherwise-empty assets directory.)

- [ ] **Step 5: Create `tools/new-lesson/template/exercises/main.lua.tmpl`**

```lua
local M = {}

function M.hello()
  error("TODO: implement lesson ${number} exercise")
end

return M
```

- [ ] **Step 6: Create `tools/new-lesson/template/exercises/main_spec.lua.tmpl`**

```lua
local here = debug.getinfo(1, "S").source:match("^@(.*/)")
package.path = here .. "?.lua;" .. package.path
local main = require("main")

describe("lesson ${number}", function()
  it("hello returns the greeting", function()
    assert.are.equal("hello from lesson ${number}", main.hello())
  end)
end)
```

- [ ] **Step 7: Create `tools/new-lesson/template/solutions/main.lua.tmpl`**

```lua
local M = {}

function M.hello()
  return "hello from lesson ${number}"
end

return M
```

- [ ] **Step 8: Create `tools/new-lesson/template/solutions/main_spec.lua.tmpl`**

```lua
local here = debug.getinfo(1, "S").source:match("^@(.*/)")
package.path = here .. "?.lua;" .. package.path
local main = require("main")

describe("lesson ${number}", function()
  it("hello returns the greeting", function()
    assert.are.equal("hello from lesson ${number}", main.hello())
  end)
end)
```

- [ ] **Step 9: Verify the template tree shape**

Run: `find tools/new-lesson/template -type f | sort`
Expected (8 files):
```
tools/new-lesson/template/README.md.tmpl
tools/new-lesson/template/exercises/main.lua.tmpl
tools/new-lesson/template/exercises/main_spec.lua.tmpl
tools/new-lesson/template/slides/assets/.gitkeep
tools/new-lesson/template/slides/index.html.tmpl
tools/new-lesson/template/slides/slides.md.tmpl
tools/new-lesson/template/solutions/main.lua.tmpl
tools/new-lesson/template/solutions/main_spec.lua.tmpl
```

- [ ] **Step 10: Commit**

```bash
git add tools/new-lesson/template
git commit -m "feat(new-lesson): add lesson template tree"
```

---

## Task 5: Implement `new_lesson.lua` with specs

**Files:**
- Create: `tools/new-lesson/new_lesson.lua`
- Create: `tools/new-lesson/spec/new_lesson_spec.lua`

Two responsibilities on the returned table:
- `parse_name(raw)` → `name, number, title`. Validates `"NN-kebab-name"` (two digits, hyphen, lowercase kebab slug starting with a letter), derives the title by title-casing each hyphen-separated word. Raises on invalid input.
- `scaffold(name, lessons_dir[, template_dir])` → path. Copies the template tree into `lessons_dir/name`, substitutes `${name}/${number}/${title}` in `.tmpl` files (stripping the suffix), copies other files verbatim, refuses to overwrite an existing folder. `template_dir` defaults to the module-relative `template/`.

- [ ] **Step 1: Write the failing spec**

Path: `tools/new-lesson/spec/new_lesson_spec.lua`

```lua
local here = debug.getinfo(1, "S").source:match("^@(.*/)")
package.path = here .. "../?.lua;" .. package.path
local new_lesson = require("new_lesson")
local lfs = require("lfs")

local TEMPLATE_DIR = here .. "../template"

local _counter = 0
local function tmpdir()
  _counter = _counter + 1
  local base = (os.getenv("TMPDIR") or "/tmp"):gsub("/+$", "")
  local path = string.format("%s/lua-training-newlesson-%d-%d", base, os.time(), _counter)
  assert(lfs.mkdir(path))
  return path
end

local function read_file(path)
  local f = assert(io.open(path, "rb"))
  local data = f:read("*a")
  f:close()
  return data
end

describe("parse_name", function()
  it("splits a valid two-digit name", function()
    local name, number, title = new_lesson.parse_name("01-hello")
    assert.are.equal("01-hello", name)
    assert.are.equal("01", number)
    assert.are.equal("Hello", title)
  end)

  it("title-cases a multi-word kebab slug", function()
    local name, number, title = new_lesson.parse_name("16-coroutines-deep")
    assert.are.equal("16-coroutines-deep", name)
    assert.are.equal("16", number)
    assert.are.equal("Coroutines Deep", title)
  end)

  it("rejects invalid names", function()
    local bad = {
      "1-hello", -- one digit
      "001-hello", -- three digits
      "01_hello", -- underscore
      "01-Hello", -- uppercase slug
      "hello", -- no number
      "01-", -- empty slug
      "01--x", -- double hyphen
      "01-x-", -- trailing hyphen
      "",
    }
    for _, raw in ipairs(bad) do
      assert.has_error(function()
        new_lesson.parse_name(raw)
      end)
    end
  end)
end)

describe("scaffold", function()
  it("creates the lesson directory", function()
    local lessons = tmpdir() .. "/lessons"
    local target = new_lesson.scaffold("99-demo", lessons, TEMPLATE_DIR)
    assert.are.equal(lessons .. "/99-demo", target)
    assert.are.equal("directory", lfs.attributes(target, "mode"))
  end)

  it("renders templated README with number and title", function()
    local lessons = tmpdir() .. "/lessons"
    local target = new_lesson.scaffold("99-demo", lessons, TEMPLATE_DIR)
    local readme = read_file(target .. "/README.md")
    assert.is_truthy(readme:find("Lesson 99", 1, true))
    assert.is_truthy(readme:find("Demo", 1, true))
    -- the .tmpl suffix is stripped
    assert.is_nil(lfs.attributes(target .. "/README.md.tmpl"))
  end)

  it("renders the deck index.html title", function()
    local lessons = tmpdir() .. "/lessons"
    local target = new_lesson.scaffold("99-demo", lessons, TEMPLATE_DIR)
    local index = read_file(target .. "/slides/index.html")
    assert.is_truthy(index:find("<title>Lesson 99 — Demo</title>", 1, true))
  end)

  it("renders exercises and solutions", function()
    local lessons = tmpdir() .. "/lessons"
    local target = new_lesson.scaffold("99-demo", lessons, TEMPLATE_DIR)
    local ex = read_file(target .. "/exercises/main.lua")
    local sol = read_file(target .. "/solutions/main.lua")
    assert.is_truthy(ex:find("lesson 99", 1, true))
    assert.is_truthy(sol:find("hello from lesson 99", 1, true))
  end)

  it("copies non-template files verbatim", function()
    local lessons = tmpdir() .. "/lessons"
    local target = new_lesson.scaffold("99-demo", lessons, TEMPLATE_DIR)
    assert.are.equal("file", lfs.attributes(target .. "/slides/assets/.gitkeep", "mode"))
  end)

  it("refuses to overwrite an existing lesson", function()
    local lessons = tmpdir() .. "/lessons"
    new_lesson.scaffold("99-demo", lessons, TEMPLATE_DIR)
    assert.has_error(function()
      new_lesson.scaffold("99-demo", lessons, TEMPLATE_DIR)
    end)
  end)
end)
```

- [ ] **Step 2: Run the spec to verify it fails**

Run: `.lua/bin/busted tools/new-lesson/spec`
Expected: errors — `module 'new_lesson' not found` (the module doesn't exist yet).

- [ ] **Step 3: Implement `tools/new-lesson/new_lesson.lua`**

```lua
-- Scaffold a new lua-training lesson from the template tree.
local lfs = require("lfs")

local M = {}

local function read_file(path)
  local f = assert(io.open(path, "rb"))
  local data = f:read("*a")
  f:close()
  return data
end

local function write_file(path, data)
  local f = assert(io.open(path, "wb"))
  f:write(data)
  f:close()
end

local function attr_mode(path)
  return lfs.attributes(path, "mode")
end

local function mkdir_p(path)
  local prefix = ""
  if path:sub(1, 1) == "/" then
    prefix = "/"
    path = path:sub(2)
  end
  local accum = ""
  for segment in path:gmatch("[^/]+") do
    accum = (accum == "") and segment or (accum .. "/" .. segment)
    local full = prefix .. accum
    if attr_mode(full) ~= "directory" then
      local ok, err = lfs.mkdir(full)
      if not ok and attr_mode(full) ~= "directory" then
        error(("could not create directory %q: %s"):format(full, tostring(err)), 0)
      end
    end
  end
end

local function render(text, subs)
  return (text:gsub("%${([%w_]+)}", function(key)
    local value = subs[key]
    if value == nil then
      error("unknown template variable: " .. key, 0)
    end
    return value
  end))
end

local function module_dir()
  return (debug.getinfo(1, "S").source:match("^@(.*/)") or "./")
end

local function copy_with_substitution(source, target, subs)
  mkdir_p(target)
  for entry in lfs.dir(source) do
    if entry ~= "." and entry ~= ".." then
      local src = source .. "/" .. entry
      local mode = attr_mode(src)
      if mode == "directory" then
        copy_with_substitution(src, target .. "/" .. entry, subs)
      elseif mode == "file" then
        if entry:sub(-5) == ".tmpl" then
          write_file(target .. "/" .. entry:sub(1, -6), render(read_file(src), subs))
        else
          write_file(target .. "/" .. entry, read_file(src))
        end
      end
    end
  end
end

function M.parse_name(raw)
  local number, slug = string.match(raw, "^(%d%d)%-(.+)$")
  if not number then
    error(
      ("invalid lesson name %q: expected 'NN-kebab-name' (e.g. '01-hello', '16-coroutines')"):format(
        raw
      ),
      0
    )
  end
  if not string.match(slug, "^%l") then
    error(("invalid lesson name %q: slug must start with a lowercase letter"):format(raw), 0)
  end
  -- Split on hyphens (the trailing "-" makes the final segment match too). Any
  -- empty segment means a leading/trailing/double hyphen, which is invalid.
  for segment in (slug .. "-"):gmatch("(.-)%-") do
    if not string.match(segment, "^[%l%d]+$") then
      error(("invalid lesson name %q: expected a lowercase kebab slug"):format(raw), 0)
    end
  end
  local words = {}
  for word in slug:gmatch("[^-]+") do
    words[#words + 1] = word:sub(1, 1):upper() .. word:sub(2)
  end
  return raw, number, table.concat(words, " ")
end

function M.scaffold(name, lessons_dir, template_dir)
  local parsed_name, number, title = M.parse_name(name)
  local target = lessons_dir .. "/" .. parsed_name
  if attr_mode(target) ~= nil then
    error(("lesson already exists: %s"):format(target), 0)
  end
  template_dir = template_dir or (module_dir() .. "template")
  copy_with_substitution(template_dir, target, { name = parsed_name, number = number, title = title })
  return target
end

return M
```

> **Why `error(msg, 0)`:** level 0 omits the `file:line:` prefix, so the message the CLI prints (and the spec asserts) is clean.

- [ ] **Step 4: Run the spec to verify it passes**

Run: `.lua/bin/busted tools/new-lesson/spec`
Expected: all examples pass (3 `parse_name` + 6 `scaffold` = 9 successes, 0 failures).

- [ ] **Step 5: Lint**

Run: `.lua/bin/luacheck tools/new-lesson`
Expected: `Total: 0 warnings / 0 errors ...`.

- [ ] **Step 6: Commit**

```bash
git add tools/new-lesson/new_lesson.lua tools/new-lesson/spec
git commit -m "feat(new-lesson): implement parse_name and scaffold with specs"
```

---

## Task 6: Wire up the `new-lesson` CLI

**Files:**
- Create: `tools/new-lesson/main.lua`

- [ ] **Step 1: Write the CLI**

Path: `tools/new-lesson/main.lua`

```lua
-- CLI entry point: lua tools/new-lesson/main.lua NN-slug [--lessons-dir DIR]
local here = arg[0]:match("^(.*/)") or "./"
package.path = here .. "?.lua;" .. package.path

local new_lesson = require("new_lesson")

local USAGE = "usage: lua tools/new-lesson/main.lua NN-slug [--lessons-dir DIR]"

local function main(argv)
  local name, lessons_dir = nil, "lessons"
  local i = 1
  while i <= #argv do
    local a = argv[i]
    if a == "--lessons-dir" then
      lessons_dir = argv[i + 1]
      i = i + 2
    elseif a == "--help" or a == "-h" then
      print(USAGE)
      return 0
    elseif a:sub(1, 1) == "-" then
      io.stderr:write("error: unknown option: " .. a .. "\n")
      return 1
    elseif not name then
      name = a
      i = i + 1
    else
      io.stderr:write("error: unexpected argument: " .. a .. "\n")
      return 1
    end
  end

  if not name then
    io.stderr:write(USAGE .. "\n")
    return 1
  end

  local ok, result = pcall(new_lesson.scaffold, name, lessons_dir)
  if not ok then
    io.stderr:write("error: " .. tostring(result) .. "\n")
    return 1
  end
  print("created " .. result)
  return 0
end

os.exit(main(arg))
```

- [ ] **Step 2: Smoke-test `--help`**

Run: `.lua/bin/lua tools/new-lesson/main.lua --help`
Expected: prints the usage line; exit 0.

- [ ] **Step 3: Smoke-test a real scaffold into a temp dir**

Run:
```bash
.lua/bin/lua tools/new-lesson/main.lua 99-demo --lessons-dir /tmp/lt-newlesson
find /tmp/lt-newlesson -type f | sort
```
Expected: prints `created /tmp/lt-newlesson/99-demo`, and the file list includes `README.md`, `slides/index.html`, `slides/slides.md`, `slides/assets/.gitkeep`, `exercises/main.lua`, `exercises/main_spec.lua`, `solutions/main.lua`, `solutions/main_spec.lua`.

- [ ] **Step 4: Verify the scaffolded lesson behaves as designed**

Run: `.lua/bin/busted /tmp/lt-newlesson/99-demo/exercises`
Expected: 1 failure — the exercise stub raises `TODO: implement lesson 99 exercise`.

Run: `.lua/bin/busted /tmp/lt-newlesson/99-demo/solutions`
Expected: 1 success.

- [ ] **Step 5: Smoke-test the rejection paths**

Run: `.lua/bin/lua tools/new-lesson/main.lua 99-demo --lessons-dir /tmp/lt-newlesson`
Expected: prints `error: lesson already exists: /tmp/lt-newlesson/99-demo` to stderr; exit 1.

Run: `.lua/bin/lua tools/new-lesson/main.lua BAD_NAME --lessons-dir /tmp/lt-newlesson`
Expected: prints `error: invalid lesson name ...` to stderr; exit 1.

- [ ] **Step 6: Clean up the temp dir**

Run: `rm -rf /tmp/lt-newlesson`

- [ ] **Step 7: Lint**

Run: `.lua/bin/luacheck tools/new-lesson`
Expected: 0 warnings / 0 errors.

- [ ] **Step 8: Commit**

```bash
git add tools/new-lesson/main.lua
git commit -m "feat(new-lesson): add CLI entry point"
```

---

## Task 7: Implement `slides-dev/server.lua` with specs

**Files:**
- Create: `tools/slides-dev/server.lua`
- Create: `tools/slides-dev/spec/server_spec.lua`

Three pure functions on the returned table:
- `resolve_lesson(repo_root, lesson)` → lesson dir, or raises if `slides/` is missing.
- `resolve(path, slides_root, shared_root)` → an absolute filepath to serve, or `nil`. Maps `""`/`"index.html"` → the deck index, `shared/reveal/*` → shared assets, everything else → the deck's own files. Rejects any path containing a `..` segment.
- `guess_content_type(name)` → a MIME string from the file extension.

- [ ] **Step 1: Write the failing spec**

Path: `tools/slides-dev/spec/server_spec.lua`

```lua
local here = debug.getinfo(1, "S").source:match("^@(.*/)")
package.path = here .. "../?.lua;" .. package.path
local server = require("server")
local lfs = require("lfs")

local _counter = 0
local function tmpdir()
  _counter = _counter + 1
  local base = (os.getenv("TMPDIR") or "/tmp"):gsub("/+$", "")
  local path = string.format("%s/lua-training-slides-%d-%d", base, os.time(), _counter)
  assert(lfs.mkdir(path))
  return path
end

local function mkpath(path)
  local accum = ""
  for segment in path:gmatch("[^/]+") do
    accum = accum .. "/" .. segment
    if lfs.attributes(accum, "mode") ~= "directory" then
      assert(lfs.mkdir(accum))
    end
  end
end

local function write_file(path, data)
  local f = assert(io.open(path, "wb"))
  f:write(data)
  f:close()
end

-- A minimal repo skeleton: one lesson deck + shared/reveal.
local function make_repo()
  local root = tmpdir()
  mkpath(root .. "/lessons/01-hello/slides")
  write_file(root .. "/lessons/01-hello/slides/index.html", "<html>hello deck</html>")
  write_file(root .. "/lessons/01-hello/slides/slides.md", "# slides")
  mkpath(root .. "/shared/reveal/dist")
  write_file(root .. "/shared/reveal/dist/reveal.css", "/* reveal */")
  return root
end

describe("resolve_lesson", function()
  it("returns the lesson dir when slides/ exists", function()
    local root = make_repo()
    assert.are.equal(root .. "/lessons/01-hello", server.resolve_lesson(root, "01-hello"))
  end)

  it("errors when the lesson has no slides/", function()
    local root = make_repo()
    mkpath(root .. "/lessons/02-empty")
    assert.has_error(function()
      server.resolve_lesson(root, "02-empty")
    end)
  end)

  it("errors when the lesson is missing", function()
    local root = make_repo()
    assert.has_error(function()
      server.resolve_lesson(root, "99-missing")
    end)
  end)
end)

describe("resolve", function()
  local root, slides_root, shared_root
  before_each(function()
    root = make_repo()
    slides_root = root .. "/lessons/01-hello/slides"
    shared_root = root .. "/shared/reveal"
  end)

  it("maps empty path to the deck index", function()
    assert.are.equal(slides_root .. "/index.html", server.resolve("", slides_root, shared_root))
  end)

  it("maps 'index.html' to the deck index", function()
    assert.are.equal(
      slides_root .. "/index.html",
      server.resolve("index.html", slides_root, shared_root)
    )
  end)

  it("serves slides.md from the deck", function()
    assert.are.equal(
      slides_root .. "/slides.md",
      server.resolve("slides.md", slides_root, shared_root)
    )
  end)

  it("maps shared/reveal/* to the shared tree", function()
    assert.are.equal(
      shared_root .. "/dist/reveal.css",
      server.resolve("shared/reveal/dist/reveal.css", slides_root, shared_root)
    )
  end)

  it("returns nil for an unknown file", function()
    assert.is_nil(server.resolve("nope.txt", slides_root, shared_root))
  end)

  it("rejects path traversal", function()
    assert.is_nil(server.resolve("../../etc/passwd", slides_root, shared_root))
    assert.is_nil(server.resolve("shared/reveal/../../../etc/passwd", slides_root, shared_root))
  end)
end)

describe("guess_content_type", function()
  it("maps .css", function()
    assert.are.equal("text/css; charset=utf-8", server.guess_content_type("reveal.css"))
  end)

  it("maps .mjs to javascript", function()
    assert.are.equal("text/javascript; charset=utf-8", server.guess_content_type("reveal.esm.mjs"))
  end)

  it("maps .svg", function()
    assert.are.equal("image/svg+xml", server.guess_content_type("diagram.svg"))
  end)

  it("defaults to octet-stream for unknown extensions", function()
    assert.are.equal("application/octet-stream", server.guess_content_type("mystery.xyz"))
  end)
end)
```

- [ ] **Step 2: Run the spec to verify it fails**

Run: `.lua/bin/busted tools/slides-dev/spec`
Expected: errors — `module 'server' not found`.

- [ ] **Step 3: Implement `tools/slides-dev/server.lua`**

```lua
-- Pure routing/MIME logic for the local slides dev server.
-- The socket accept-loop lives in main.lua; everything here is unit-testable.
local lfs = require("lfs")

local M = {}

local CONTENT_TYPES = {
  html = "text/html; charset=utf-8",
  md = "text/markdown; charset=utf-8",
  css = "text/css; charset=utf-8",
  js = "text/javascript; charset=utf-8",
  mjs = "text/javascript; charset=utf-8",
  json = "application/json; charset=utf-8",
  svg = "image/svg+xml",
  png = "image/png",
  jpg = "image/jpeg",
  jpeg = "image/jpeg",
  gif = "image/gif",
  ico = "image/x-icon",
  woff = "font/woff",
  woff2 = "font/woff2",
  ttf = "font/ttf",
  otf = "font/otf",
  map = "application/json",
}

local SHARED_PREFIX = "shared/reveal/"

local function is_dir(path)
  return lfs.attributes(path, "mode") == "directory"
end

local function is_file(path)
  return lfs.attributes(path, "mode") == "file"
end

local function has_traversal(path)
  for segment in path:gmatch("[^/]+") do
    if segment == ".." then
      return true
    end
  end
  return false
end

function M.guess_content_type(name)
  local ext = name:match("%.([%a%d]+)$")
  if ext then
    return CONTENT_TYPES[ext:lower()] or "application/octet-stream"
  end
  return "application/octet-stream"
end

function M.resolve_lesson(repo_root, lesson)
  local lesson_dir = repo_root .. "/lessons/" .. lesson
  if not is_dir(lesson_dir .. "/slides") then
    error(("no slides for lesson %q (expected %s/slides)"):format(lesson, lesson_dir), 0)
  end
  return lesson_dir
end

function M.resolve(path, slides_root, shared_root)
  if path == "" or path == "index.html" then
    local candidate = slides_root .. "/index.html"
    return is_file(candidate) and candidate or nil
  end
  if has_traversal(path) then
    return nil
  end
  local candidate
  if path:sub(1, #SHARED_PREFIX) == SHARED_PREFIX then
    candidate = shared_root .. "/" .. path:sub(#SHARED_PREFIX + 1)
  else
    candidate = slides_root .. "/" .. path
  end
  return is_file(candidate) and candidate or nil
end

return M
```

- [ ] **Step 4: Run the spec to verify it passes**

Run: `.lua/bin/busted tools/slides-dev/spec`
Expected: all examples pass (3 + 6 + 4 = 13 successes, 0 failures).

- [ ] **Step 5: Lint**

Run: `.lua/bin/luacheck tools/slides-dev`
Expected: 0 warnings / 0 errors.

- [ ] **Step 6: Commit**

```bash
git add tools/slides-dev/server.lua tools/slides-dev/spec
git commit -m "feat(slides-dev): implement resolve_lesson/resolve/guess_content_type with specs"
```

---

## Task 8: Wire up the `slides-dev` CLI (socket server)

**Files:**
- Create: `tools/slides-dev/main.lua`

The CLI parses args, resolves the lesson, binds a `luasocket` TCP server, and serves requests in an accept-loop using `server.resolve` + `server.guess_content_type`.

- [ ] **Step 1: Write the CLI**

Path: `tools/slides-dev/main.lua`

```lua
-- CLI entry point: lua tools/slides-dev/main.lua --lesson NN-slug [--repo-root .]
--                                                 [--port 8000] [--host 127.0.0.1]
local here = arg[0]:match("^(.*/)") or "./"
package.path = here .. "?.lua;" .. package.path

local socket = require("socket")
local server = require("server")

local USAGE = "usage: lua tools/slides-dev/main.lua --lesson NN-slug "
  .. "[--repo-root .] [--port 8000] [--host 127.0.0.1]"

local function parse_args(argv)
  local opts = { repo_root = ".", port = 8000, host = "127.0.0.1" }
  local i = 1
  while i <= #argv do
    local a = argv[i]
    if a == "--lesson" then
      opts.lesson = argv[i + 1]
      i = i + 2
    elseif a == "--repo-root" then
      opts.repo_root = argv[i + 1]
      i = i + 2
    elseif a == "--port" then
      opts.port = tonumber(argv[i + 1])
      i = i + 2
    elseif a == "--host" then
      opts.host = argv[i + 1]
      i = i + 2
    elseif a == "--help" or a == "-h" then
      opts.help = true
      i = i + 1
    else
      error("unknown argument: " .. tostring(a), 0)
    end
  end
  return opts
end

local function read_bytes(path)
  local f = assert(io.open(path, "rb"))
  local data = f:read("*a")
  f:close()
  return data
end

local function send_404(client)
  local body = "404 Not Found\n"
  client:send(
    "HTTP/1.1 404 Not Found\r\n"
      .. "Content-Type: text/plain; charset=utf-8\r\n"
      .. ("Content-Length: %d\r\n"):format(#body)
      .. "Connection: close\r\n\r\n"
      .. body
  )
end

local function send_file(client, path)
  local data = read_bytes(path)
  local header = table.concat({
    "HTTP/1.1 200 OK",
    "Content-Type: " .. server.guess_content_type(path),
    ("Content-Length: %d"):format(#data),
    "Connection: close",
    "",
    "",
  }, "\r\n")
  client:send(header .. data)
end

local function handle(client, slides_root, shared_root)
  local request_line = client:receive("*l")
  if not request_line then
    client:close()
    return
  end
  -- Drain the remaining request headers up to the blank line.
  repeat
    local line = client:receive("*l")
  until not line or line == ""

  local method, raw_path = request_line:match("^(%u+)%s+(%S+)")
  local target
  if method == "GET" and raw_path then
    local path = raw_path:gsub("%?.*$", ""):gsub("^/+", "")
    target = server.resolve(path, slides_root, shared_root)
  end

  if target then
    send_file(client, target)
  else
    send_404(client)
  end
  client:close()
end

local function main(argv)
  local ok, opts = pcall(parse_args, argv)
  if not ok then
    io.stderr:write("error: " .. tostring(opts) .. "\n" .. USAGE .. "\n")
    return 1
  end
  if opts.help then
    print(USAGE)
    return 0
  end
  if not opts.lesson then
    io.stderr:write("error: --lesson is required\n" .. USAGE .. "\n")
    return 1
  end

  local resolved, lesson_dir = pcall(server.resolve_lesson, opts.repo_root, opts.lesson)
  if not resolved then
    io.stderr:write("error: " .. tostring(lesson_dir) .. "\n")
    return 1
  end

  local slides_root = lesson_dir .. "/slides"
  local shared_root = opts.repo_root .. "/shared/reveal"

  local listener, err = socket.bind(opts.host, opts.port)
  if not listener then
    io.stderr:write("error: cannot bind " .. opts.host .. ":" .. opts.port .. ": " .. tostring(err) .. "\n")
    return 1
  end

  print(
    ("serving lesson %s on http://%s:%d (Ctrl-C to stop)"):format(opts.lesson, opts.host, opts.port)
  )
  while true do
    local client = listener:accept()
    if client then
      handle(client, slides_root, shared_root)
    end
  end
end

os.exit(main(arg))
```

- [ ] **Step 2: Smoke-test `--help` and the error path**

Run: `.lua/bin/lua tools/slides-dev/main.lua --help`
Expected: prints the usage line; exit 0.

Run: `.lua/bin/lua tools/slides-dev/main.lua --lesson 99-missing`
Expected: prints `error: no slides for lesson "99-missing" ...` to stderr; exit 1.

- [ ] **Step 3: Live smoke-test against a scaffolded deck**

Scaffold a sandbox lesson, start the server in the background, curl it, then stop it:
```bash
.lua/bin/lua tools/new-lesson/main.lua 99-demo
.lua/bin/lua tools/slides-dev/main.lua --lesson 99-demo --repo-root "$(pwd)" --port 8123 &
SERVER_PID=$!
sleep 1
curl -s -o /dev/null -w "root=%{http_code}\n" http://127.0.0.1:8123/
curl -s http://127.0.0.1:8123/ | grep -o "<title>[^<]*</title>"
curl -s -o /dev/null -w "slidesmd=%{http_code}\n" http://127.0.0.1:8123/slides.md
curl -s -o /dev/null -w "revealcss=%{http_code}\n" http://127.0.0.1:8123/shared/reveal/dist/reveal.css
curl -s -o /dev/null -w "notfound=%{http_code}\n" http://127.0.0.1:8123/nope.txt
kill "$SERVER_PID"
rm -rf lessons/99-demo
```
Expected: `root=200`, `<title>Lesson 99 — Demo</title>`, `slidesmd=200`, `revealcss=200`, `notfound=404`.

- [ ] **Step 4: Lint**

Run: `.lua/bin/luacheck tools/slides-dev`
Expected: 0 warnings / 0 errors.

- [ ] **Step 5: Commit**

```bash
git add tools/slides-dev/main.lua
git commit -m "feat(slides-dev): add luasocket-based CLI server"
```

---

## Task 9: Write the Makefile

**Files:**
- Create: `Makefile`
- Create: `lessons/.gitkeep`

- [ ] **Step 1: Create the empty `lessons/` directory tracker**

Run: `mkdir -p lessons && touch lessons/.gitkeep`

- [ ] **Step 2: Write the Makefile** (recipe lines MUST use real TABs)

```makefile
SHELL := /bin/bash
.DEFAULT_GOAL := help

REPO_ROOT := $(shell pwd)
LUA_ENV := .lua
LUA := $(LUA_ENV)/bin/lua
BUSTED := $(LUA_ENV)/bin/busted
LUACHECK := $(LUA_ENV)/bin/luacheck

.PHONY: help
help: ## List available targets
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: bootstrap
bootstrap: ## Install pinned Lua 5.4 + LuaRocks + rocks into ./.lua (via hererocks)
	./scripts/bootstrap

.PHONY: test
test: ## Run tool specs + every lesson's solution specs (the always-green set)
	$(BUSTED) tools
	@for d in $$(find lessons -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort); do \
		if [ -d "$$d/solutions" ]; then \
			echo "== $$d/solutions =="; \
			$(BUSTED) "$$d/solutions" || exit 1; \
		fi; \
	done

.PHONY: test-exercises
test-exercises: ## Run exercise specs (these fail by design until students complete them)
	@for d in $$(find lessons -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort); do \
		if [ -d "$$d/exercises" ]; then \
			echo "== $$d/exercises =="; \
			$(BUSTED) "$$d/exercises" || true; \
		fi; \
	done

.PHONY: test-lesson
test-lesson: ## Run one lesson's specs, exercises then solutions (LESSON=NN-slug)
	@test -n "$(LESSON)" || (echo "usage: make test-lesson LESSON=NN-slug" && exit 1)
	-$(BUSTED) lessons/$(LESSON)/exercises
	$(BUSTED) lessons/$(LESSON)/solutions

.PHONY: lint
lint: ## Run luacheck over the tools
	$(LUACHECK) tools

.PHONY: fmt
fmt: ## Format Lua with StyLua (install separately: brew install stylua)
	stylua tools

.PHONY: new-lesson
new-lesson: ## Scaffold a new lesson (NAME=NN-slug)
	@test -n "$(NAME)" || (echo "usage: make new-lesson NAME=NN-slug" && exit 1)
	$(LUA) tools/new-lesson/main.lua $(NAME)

.PHONY: slides-dev
slides-dev: ## Serve one lesson's deck locally on http://localhost:8000 (LESSON=NN-slug)
	@test -n "$(LESSON)" || (echo "usage: make slides-dev LESSON=NN-slug" && exit 1)
	$(LUA) tools/slides-dev/main.lua --lesson $(LESSON) --repo-root $(REPO_ROOT)
```

> **Per-lesson process isolation:** `make test` runs `busted` once per lesson `solutions/` directory. Lesson modules are named `main`, so running multiple lessons (or exercises + solutions) in one `busted` process would collide in `package.loaded`. Separate invocations keep each lesson hermetic. **`make lint` scopes to `tools`** because `lessons/` is empty in Plan A and `luacheck` does not read `.gitignore` (so a bare `luacheck .` would scan the `.lua/` toolchain tree). Lesson directories get folded into `lint`/`fmt` by the lesson plans.

- [ ] **Step 3: Verify `make help` lists every target**

Run: `make help`
Expected: lists `help`, `bootstrap`, `test`, `test-exercises`, `test-lesson`, `lint`, `fmt`, `new-lesson`, `slides-dev`.

- [ ] **Step 4: Verify `make lint` and `make test` are green**

Run: `make lint`
Expected: luacheck reports 0 warnings / 0 errors.

Run: `make test`
Expected: `busted tools` passes (9 + 13 = 22 successes); then the lesson loop prints nothing (no lesson dirs yet) and exits 0.

- [ ] **Step 5: Commit**

```bash
git add Makefile lessons/.gitkeep
git commit -m "build: add Makefile (bootstrap/test/lint/fmt/new-lesson/slides-dev) and lessons/ placeholder"
```

---

## Task 10: Write README.md and CONTRIBUTING.md

**Files:**
- Create: `README.md`
- Create: `CONTRIBUTING.md`

- [ ] **Step 1: Create `README.md`**

````markdown
# Lua Training

A Lua programming course delivered as code + per-lesson reveal.js slide decks.
Targets **Lua 5.4** (the PUC-Rio reference). The arc starts at programming-101
and finishes with the language's distinctive endgame: coroutines, performance,
packaging with LuaRocks, and embedding (running Lua inside a host, and
extending Lua from a host).

## Prerequisites

- A C compiler + `make` (to build Lua). On macOS: `xcode-select --install`.
- [`hererocks`](https://github.com/luarocks/hererocks) — provisions a pinned,
  repo-local Lua 5.4 + LuaRocks toolchain under `./.lua/`:
  ```bash
  pipx install hererocks          # recommended
  # or: python3 -m pip install --user hererocks
  ```
- [`StyLua`](https://github.com/JohnnyMorganz/StyLua) for `make fmt`:
  ```bash
  brew install stylua
  ```

## Quick start

Clone the repo, then from the repo root:

```bash
make help                       # list every available command
make bootstrap                  # install Lua 5.4 + rocks into ./.lua
make new-lesson NAME=99-demo    # scaffold a sandbox lesson
make slides-dev LESSON=99-demo  # serve its deck on http://localhost:8000
make test                       # run all tool + solution specs
```

## Repository layout

```
lessons/NN-slug/
├── README.md       self-study notes for the lesson
├── slides/         reveal.js deck (index.html + slides.md)
├── exercises/      starter code + failing *_spec.lua tests (the spec)
└── solutions/      reference implementation

shared/reveal/      vendored reveal.js + custom theme (do not edit by hand)
tools/              developer tooling in Lua (new-lesson, slides-dev, build-index)
docs/               design docs and implementation plans
```

## Design

See [`docs/superpowers/specs/2026-06-02-lua-course-design.md`](docs/superpowers/specs/2026-06-02-lua-course-design.md)
for the course design.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the lesson conventions and dev workflow.
````

- [ ] **Step 2: Create `CONTRIBUTING.md`**

````markdown
# Contributing to lua-training

## Adding a new lesson

```bash
make new-lesson NAME=NN-kebab-name      # e.g. 04-operators
make slides-dev LESSON=NN-kebab-name    # http://localhost:8000
make test-lesson LESSON=NN-kebab-name
```

The scaffolder enforces the `NN-kebab-name` format (two-digit number, lowercase
kebab slug) and refuses to overwrite an existing folder.

## The four-file convention

Every lesson directory contains exactly four parts:

- `README.md` — learning goals, prereqs, concepts, exercise brief, how to run, going further.
- `slides/` — `index.html` (reveal.js bootstrap), `slides.md` (markdown), `assets/`.
- `exercises/` — runnable but incomplete code + failing `*_spec.lua` busted tests that are the spec.
- `solutions/` — fully-implemented reference; the same specs pass.

The scaffolder creates all four with sensible placeholders.

## Slide style

- Markdown with HTML escape hatches; `---` separates horizontal slides, `--` separates vertical ones (used sparingly).
- Code-heavy slides: keep to ~15 visible lines. Split longer examples across slides.
- Code in fenced ` ```lua ` blocks.
- First slide: lesson number, title, one-line learning goal. Last slide: pointer to the next lesson.
- Diagrams: SVG only. Never images of code.
- Speaker notes via `Note:` blocks at the bottom of a slide.

## Code style

- `make fmt` (StyLua) before committing.
- `make lint` (luacheck) must pass. There is no enforced type checker — Lua is
  dynamically typed. LuaLS `---@` annotations are taught as documentation
  (lesson 13 onward) but never gate the build.

## Conventions for Lua source

- Module files lowercase `snake_case.lua`; test files always `*_spec.lua`.
- Lesson directories use 1-based, idiomatic Lua. No cross-lesson `require`s —
  each lesson is self-contained.
- Each lesson's specs run in their own `busted` process (the Makefile handles
  this), because lesson modules share the name `main`.

## Commit messages

Conventional Commits: `feat(lesson-04): ...`, `fix(slides-dev): ...`, `docs: ...`, etc.

## Tests as spec

`exercises/*_spec.lua` files define what "done" means. Students make those
specs pass; the `solutions/` copy keeps the same specs green.
````

- [ ] **Step 3: Commit**

```bash
git add README.md CONTRIBUTING.md
git commit -m "docs: add README and CONTRIBUTING"
```

---

## Task 11: End-to-end smoke test

Confirm the whole bootstrap works the way the README promises. Run from the repo root.

- [ ] **Step 1: `make help` lists every target**

Run: `make help`
Expected: lists all nine targets.

- [ ] **Step 2: Scaffold a sandbox lesson**

Run: `make new-lesson NAME=99-demo`
Expected: prints `created lessons/99-demo`. The directory exists with `README.md`, `slides/index.html`, `slides/slides.md`, `slides/assets/.gitkeep`, `exercises/main.lua`, `exercises/main_spec.lua`, `solutions/main.lua`, `solutions/main_spec.lua`.

- [ ] **Step 3: Solution specs pass; exercise specs fail by design**

Run: `make test-lesson LESSON=99-demo`
Expected: the exercises run FAILS (`TODO: implement lesson 99 exercise`); the solutions run passes. The Makefile swallows the exercise failure (leading `-`), so the target exits 0.

- [ ] **Step 4: `make test` includes the new lesson's solutions**

Run: `make test`
Expected: `busted tools` passes (22), then `== lessons/99-demo/solutions ==` runs and passes (1). Exit 0.

- [ ] **Step 5: Slides dev server serves the deck**

Run (background the server, then curl):
```bash
make slides-dev LESSON=99-demo &
SERVER_PID=$!
sleep 1
curl -s http://127.0.0.1:8000/ | grep -o "<title>[^<]*</title>"
curl -s -o /dev/null -w "slidesmd=%{http_code}\n" http://127.0.0.1:8000/slides.md
curl -s -o /dev/null -w "revealcss=%{http_code}\n" http://127.0.0.1:8000/shared/reveal/dist/reveal.css
kill "$SERVER_PID"
```
Expected: `<title>Lesson 99 — Demo</title>`, `slidesmd=200`, `revealcss=200`.

- [ ] **Step 6: Tear down the sandbox**

Run: `rm -rf lessons/99-demo`
Expected: `lessons/99-demo` is gone; `git status --porcelain lessons/` shows nothing (only the gitkeep remains, already tracked).

- [ ] **Step 7: Full quality bar**

```bash
make lint
make test
```
Expected: lint reports 0 warnings / 0 errors; tests pass (22, no lesson dirs). Both exit 0.

- [ ] **Step 8: Confirm no stray artifacts are tracked**

Run: `git status --porcelain`
Expected: clean. `.lua/` and `dist/` are gitignored; no sandbox lesson remains.

- [ ] **Step 9: Push (only if the remote is configured and the owner approves)**

This plan creates no remote and runs no `git push`. Pushing and creating the GitHub repo are owner steps, done when the owner is ready.

---

## Notes for execution

- **`make bootstrap` is the gate.** Tasks 5–11 require the `.lua/` toolchain. If `hererocks` is missing, install it (`pipx install hererocks`) and re-run Task 1 Step 8 before continuing.
- **No `gcloud`, no deploy, no `git push`** in Plan A. The deploy story (Docker, Cloud Run, CI/CD) is Plan B; lessons are Plan C onward.
- **After this plan**, `lessons/` is empty (only `.gitkeep`). The static-site builder and landing page (showing all 23 lessons as faded placeholders) arrive in Plan B.
- **Spec ↔ plan deviations to note for Plan B:** the spec lists `tools/build-index/` with a `catalog.lua` of all 23 lessons, plus `deploy/` and `.github/workflows/` — all of that is Plan B, not Plan A.
