# Plan B — Slides Build & Deploy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the static slide-site builder (`tools/build-index`, written in Lua), wire `make slides-build` / `make slides-docker`, and ship the full deploy story (two-stage Docker image, Cloud Run config, idempotent GCP bootstrap, GitHub Actions CI + deploy) so a push to `main` publishes the decks at `https://lua.ristkari.dev/`.

**Architecture:** `build-index` is a third Lua tool under `tools/`, mirroring `new-lesson`/`slides-dev`: a `catalog.lua` (pure data — all 23 lessons), a `template.lua` (landing-page HTML head/tail constants), a `builder.lua` (filesystem + HTML rendering, using `luafilesystem`), and a `main.lua` CLI, with `busted` specs. The landing page lists every lesson; those whose `slides/` directory exists on disk render as links, the rest as faded "future" placeholders, so the page is complete from day one and CI has stable content to assert. The deploy path mirrors the sibling `python-training`/`go-training` repos exactly with lua-augmented resource names: a two-stage Dockerfile (Alpine + `lua5.4` + `lua5.4-filesystem` builder → `nginx-unprivileged` runtime) produces a static `dist/`, pushed to Artifact Registry and deployed to Cloud Run via Workload Identity Federation (no long-lived keys).

**Tech Stack:** Lua 5.4 + `luafilesystem`, `busted`, `luacheck` (all from Plan A's `.lua/` toolchain), Alpine `lua5.4`/`lua5.4-filesystem`, `nginx-unprivileged`, Docker, Google Cloud Run + Artifact Registry, GitHub Actions, GCP Workload Identity Federation.

---

## Context for the implementer

- **Repo state:** Plan A is merged to `main`. The repo has the `.lua/` toolchain (Lua 5.4.4 + busted/luacheck/luafilesystem/luasocket via `hererocks` — run `make bootstrap` if `.lua/` is absent), two Lua tools (`tools/new-lesson`, `tools/slides-dev`), vendored reveal.js at `shared/reveal/` + theme `lua-training.css`, and a Makefile. `lessons/` contains only `.gitkeep` (no lessons authored yet) — the build MUST handle zero lessons gracefully.
- **Run Lua through the bootstrapped binaries:** `.lua/bin/lua`, `.lua/bin/busted`, `.lua/bin/luacheck` (the Makefile wraps these as `$(LUA)`, `$(BUSTED)`, `$(LUACHECK)`).
- **Module/spec resolution (no package manager):** every entry point prepends its own directory to `package.path`. CLIs use `local here = arg[0]:match("^(.*/)") or "./"`; specs use `debug.getinfo(1, "S").source:match("^@(.*/)")`. `build-index`'s specs live in `tools/build-index/spec/` so they prepend `../?.lua`; once a spec or `main.lua` prepends `tools/build-index/`, `require("catalog")`/`require("template")`/`require("builder")` all resolve. Module names (`catalog`, `template`, `builder`, plus `new_lesson`/`server` from Plan A) are unique, so `busted tools` runs everything in one process safely.
- **`.busted` pattern is `_spec%.lua$`** (Plan A) — only files ending in `_spec.lua` are collected.
- **Sibling references:** `/Users/ristkari/code/private/python-training/deploy/` and `.github/workflows/` implement this exact deploy pattern. The full content is inlined below (renamed for Lua); you generally do NOT need to read those repos.

## Conventions used by this plan

- **Working directory:** `/Users/ristkari/code/private/lua-training/` for every command.
- **Branch:** `plan-b-slides-build-deploy` (already created off the merged `main`). Commit here; do not push or open a PR until the plan is complete and the controller decides.
- **Commit messages:** Conventional Commits (`feat:`, `build:`, `ci:`, `test:`, `docs:`).
- **GCP resource names (lua-augmented, shared `ristkari-dev` project):**
  - Region: `europe-north1`
  - Artifact Registry repo: `lua-training`
  - Cloud Run service: `lua-training-slides`
  - Deploy service account: `github-deploy-lua@ristkari-dev.iam.gserviceaccount.com`
  - WIF pool: `github-actions` (shared, already exists from sibling repos)
  - WIF provider: `github-lua-training` (repo-suffixed; the pool is shared, each provider scoped to one repo)
  - GitHub repo: `ristkari-dev/lua-training`
  - Custom domain: `lua.ristkari.dev` (Cloudflare CNAME → `ghs.googlehosted.com`, DNS-only)
- **Do NOT run any `gcloud` commands, do NOT push, do NOT set secrets.** This plan only writes files and runs local builds/tests. The actual GCP bootstrap (`./deploy/setup.sh`), secret-setting, and DNS are the owner's manual one-time steps, documented in `deploy/README.md`.

---

## File Structure

After this plan completes, the repo gains:

```
lua-training/
├── Makefile                                    (MODIFY: add slides-build, slides-docker)
├── tools/
│   └── build-index/                            (NEW Lua tool)
│       ├── catalog.lua                          (PHASES + LESSONS — 23 lessons; dir_name)
│       ├── template.lua                         (HEAD / TAIL landing-page HTML constants)
│       ├── builder.lua                          (escape_html, collect_published, copy_tree, rmtree, render_index, build)
│       ├── main.lua                             (CLI)
│       └── spec/
│           ├── catalog_spec.lua
│           └── builder_spec.lua
├── deploy/                                      (NEW)
│   ├── Dockerfile
│   ├── nginx.conf.template
│   ├── cloudrun.yaml
│   ├── setup.sh                                 (executable)
│   └── README.md
└── .github/
    └── workflows/                              (NEW)
        ├── ci.yml
        └── deploy.yml
```

### Decomposition rationale

- `catalog.lua` is pure data (the lesson list) so editing the curriculum never touches logic.
- `template.lua` isolates the large HTML+CSS blob so `builder.lua` stays focused on filesystem + rendering and reads in one screen.
- `builder.lua` holds the testable functions; `main.lua` is thin CLI wiring.
- Specs split by concern: catalog integrity vs. build behaviour.

---

## Task 1: Add the lesson catalog with specs

**Files:**
- Create: `tools/build-index/catalog.lua`
- Create: `tools/build-index/spec/catalog_spec.lua`

The catalog is the master list of all 23 lessons across 4 phases, from the course design spec (`docs/superpowers/specs/2026-06-02-lua-course-design.md`). Published-or-not is decided at build time by disk; the catalog itself lists every lesson.

- [ ] **Step 1: Write the failing spec**

Path: `tools/build-index/spec/catalog_spec.lua`

```lua
local here = debug.getinfo(1, "S").source:match("^@(.*/)")
package.path = here .. "../?.lua;" .. package.path
local catalog = require("catalog")

describe("catalog", function()
  it("has 23 lessons", function()
    assert.are.equal(23, #catalog.LESSONS)
  end)

  it("numbers are sequential two-digit 01..23", function()
    for i, lesson in ipairs(catalog.LESSONS) do
      assert.are.equal(string.format("%02d", i), lesson.number)
    end
  end)

  it("defines four phases", function()
    local nums = {}
    for _, phase in ipairs(catalog.PHASES) do
      nums[#nums + 1] = phase[1]
    end
    assert.are.same({ 1, 2, 3, 4 }, nums)
  end)

  it("every lesson's phase is a defined phase", function()
    local defined = {}
    for _, phase in ipairs(catalog.PHASES) do
      defined[phase[1]] = true
    end
    for _, lesson in ipairs(catalog.LESSONS) do
      assert.is_true(defined[lesson.phase] == true)
    end
  end)

  it("has the expected phase boundaries", function()
    local by_number = {}
    for _, lesson in ipairs(catalog.LESSONS) do
      by_number[lesson.number] = lesson.phase
    end
    assert.are.equal(1, by_number["01"])
    assert.are.equal(1, by_number["07"])
    assert.are.equal(2, by_number["08"])
    assert.are.equal(2, by_number["13"])
    assert.are.equal(3, by_number["14"])
    assert.are.equal(3, by_number["18"])
    assert.are.equal(4, by_number["19"])
    assert.are.equal(4, by_number["23"])
  end)

  it("slugs are kebab-case", function()
    -- Lua patterns cannot quantify a capture group, so validate per segment:
    -- a lowercase-leading slug split on "-" must have only [a-z0-9]+ segments.
    for _, lesson in ipairs(catalog.LESSONS) do
      local slug = lesson.slug
      assert.is_truthy(slug:match("^%l"), "slug must start lowercase: " .. slug)
      for segment in (slug .. "-"):gmatch("(.-)%-") do
        assert.is_truthy(segment:match("^[%l%d]+$"), "bad slug segment in: " .. slug)
      end
    end
  end)

  it("dir_name combines number and slug", function()
    local first = catalog.LESSONS[1]
    assert.are.equal(first.number .. "-" .. first.slug, catalog.dir_name(first))
  end)
end)
```

- [ ] **Step 2: Run the spec to verify it fails**

Run: `.lua/bin/busted tools/build-index/spec/catalog_spec.lua`
Expected: error — `module 'catalog' not found`.

- [ ] **Step 3: Implement `catalog.lua`**

Path: `tools/build-index/catalog.lua`

```lua
-- The master catalog of every lesson in the course.
--
-- A lesson appears on the landing page as a faded "future" placeholder until its
-- lessons/NN-slug/slides/ directory exists on disk, at which point it lights up
-- as a link. Editing this list is how the curriculum is reflected on the page.

local M = {}

-- { phase_number, phase_name }
M.PHASES = {
  { 1, "Foundations" },
  { 2, "The Heart of Lua" },
  { 3, "Idiomatic & Advanced Lua" },
  { 4, "Packaging & Embedding" },
}

-- Each lesson: { number, slug, title, blurb, phase }
M.LESSONS = {
  -- Phase 1 — Foundations
  { number = "01", slug = "hello", title = "Hello, Lua", blurb = "lua · REPL · print · busted", phase = 1 },
  { number = "02", slug = "values-types", title = "Values & types", blurb = "nil·boolean·number·string · truthiness", phase = 1 },
  { number = "03", slug = "variables-scope", title = "Variables & scope", blurb = "local vs global · <const>", phase = 1 },
  { number = "04", slug = "operators", title = "Operators & expressions", blurb = "// · and·or · .. · # · bitwise", phase = 1 },
  { number = "05", slug = "control-flow", title = "Control flow", blurb = "if·elseif · while · repeat · for · goto", phase = 1 },
  { number = "06", slug = "functions-testing", title = "Functions & testing", blurb = "multiple returns · varargs · busted", phase = 1 },
  { number = "07", slug = "capstone-cli", title = "Phase 1 capstone — CLI", blurb = "arg · io · multi-function", phase = 1 },
  -- Phase 2 — The Heart of Lua
  { number = "08", slug = "tables", title = "Tables: the one data structure", blurb = "arrays (1-based) · maps · table · pairs", phase = 2 },
  { number = "09", slug = "strings-patterns", title = "Strings & patterns", blurb = "Lua patterns · match·gsub · format", phase = 2 },
  { number = "10", slug = "metatables", title = "Metatables & metamethods", blurb = "__index · __newindex · __call", phase = 2 },
  { number = "11", slug = "oop", title = "OOP in Lua", blurb = "metatables · : and self · inheritance", phase = 2 },
  { number = "12", slug = "modules", title = "Modules & require", blurb = "require · package.path · module table", phase = 2 },
  { number = "13", slug = "errors", title = "Errors & robustness", blurb = "pcall·error · nil,err · <close>", phase = 2 },
  -- Phase 3 — Idiomatic & Advanced Lua
  { number = "14", slug = "iterators", title = "Iterators & the generic for", blurb = "stateless·stateful · next · closures", phase = 3 },
  { number = "15", slug = "closures", title = "Closures & functional Lua", blurb = "upvalues · higher-order · memoize", phase = 3 },
  { number = "16", slug = "coroutines", title = "Coroutines", blurb = "create·resume·yield · generators", phase = 3 },
  { number = "17", slug = "stdlib-io", title = "Standard library & I/O", blurb = "os · io · math · utf8 · load", phase = 3 },
  { number = "18", slug = "environments-gc", title = "Environments, GC & performance", blurb = "_ENV · GC · weak tables · perf", phase = 3 },
  -- Phase 4 — Packaging & Embedding
  { number = "19", slug = "luarocks", title = "LuaRocks & writing a module", blurb = "rockspec · install · publish · semver", phase = 4 },
  { number = "20", slug = "embedding", title = "Embedding Lua (host provided)", blurb = "lua_State · stack · call Lua from C", phase = 4 },
  { number = "21", slug = "extending", title = "Extending Lua (host API)", blurb = "lua_CFunction · luaL_newlib · .so", phase = 4 },
  { number = "22", slug = "sandboxing", title = "Sandboxing & plugin patterns", blurb = "_ENV sandbox · debug.sethook", phase = 4 },
  { number = "23", slug = "capstone", title = "Capstone: embeddable scripting host", blurb = "plugins · config DSL · wrap-up", phase = 4 },
}

function M.dir_name(lesson)
  return lesson.number .. "-" .. lesson.slug
end

return M
```

- [ ] **Step 4: Run the spec to verify it passes**

Run: `.lua/bin/busted tools/build-index/spec/catalog_spec.lua`
Expected: `7 successes / 0 failures / 0 errors`.

- [ ] **Step 5: Lint**

Run: `.lua/bin/luacheck tools/build-index`
Expected: 0 warnings / 0 errors.

> The `LESSONS` rows exceed 100 columns; `luacheck` does not enforce line length, so this is fine. (StyLua would reformat them, but `make fmt` is not run here.)

- [ ] **Step 6: Commit**

```bash
git add tools/build-index/catalog.lua tools/build-index/spec/catalog_spec.lua
git commit -m "feat(build-index): add 23-lesson catalog with integrity specs"
```

---

## Task 2: Add the landing-page HTML template

**Files:**
- Create: `tools/build-index/template.lua`

Holds the Lua-branded landing-page HTML head/tail as string constants (long-bracket `[==[ ]==]` literals). `builder.lua` concatenates `HEAD .. <generated body> .. TAIL`. Palette matches the slide theme: deep blue on dark.

- [ ] **Step 1: Create `tools/build-index/template.lua`**

```lua
-- HTML head/tail constants for the generated landing page.
--
-- The body (phase headers + lesson cards) is generated in builder.lua and
-- inserted between HEAD and TAIL.

local M = {}

M.HEAD = [==[<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Lua Training</title>
  <style>
    :root {
      --bg: #0f1722;
      --border: rgba(91, 141, 239, 0.30);

      --fg: #e8eef5;
      --fg-muted: rgba(232, 238, 245, 0.65);
      --fg-subtle: rgba(232, 238, 245, 0.42);

      --lua-blue: #5b8def;
      --lua-light: #9cc2ff;
      --accent-soft: rgba(91, 141, 239, 0.12);
      --accent-strong: rgba(156, 194, 255, 0.55);

      --font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      --font-mono: "JetBrains Mono", "SF Mono", "Source Code Pro", Menlo, Consolas, monospace;
    }

    * { box-sizing: border-box; }
    html, body { margin: 0; padding: 0; background: var(--bg); color: var(--fg); }
    body { font-family: var(--font-sans); font-size: 16px; line-height: 1.55; }

    main { max-width: 960px; margin: 0 auto; padding: 60px 28px 100px; }

    h1 {
      font-size: 2.6rem;
      font-weight: 700;
      color: var(--lua-light);
      letter-spacing: -0.025em;
      margin: 0 0 0.3rem;
    }
    p.lead {
      font-size: 1.1rem;
      color: var(--fg-muted);
      margin: 0 0 2.5rem;
      max-width: 640px;
    }

    .phase {
      font-family: var(--font-mono);
      font-size: 0.75rem;
      font-weight: 600;
      letter-spacing: 0.12em;
      text-transform: uppercase;
      color: var(--lua-blue);
      margin: 2.5rem 0 1rem;
      display: flex;
      align-items: center;
      gap: 0.7rem;
    }
    .phase::after {
      content: "";
      flex: 1;
      height: 1px;
      background: var(--border);
    }

    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
      gap: 0.7rem;
    }

    .lesson {
      background: var(--accent-soft);
      border: 1px solid var(--border);
      border-radius: 10px;
      padding: 0.95rem 1rem 1rem;
      text-decoration: none;
      color: inherit;
      transition: transform 150ms ease, border-color 150ms ease, background 150ms ease;
      display: block;
    }
    .lesson:hover {
      transform: translateY(-2px);
      border-color: var(--accent-strong);
      background: rgba(91, 141, 239, 0.18);
    }
    .lesson:focus-visible {
      outline: 2px solid var(--lua-light);
      outline-offset: 3px;
    }
    .lesson .num {
      font-family: var(--font-mono);
      font-size: 0.7rem;
      font-weight: 600;
      color: var(--lua-light);
      letter-spacing: 0.05em;
    }
    .lesson .title {
      font-size: 1.05rem;
      font-weight: 600;
      color: var(--fg);
      letter-spacing: -0.01em;
      margin-top: 0.25rem;
      line-height: 1.25;
    }
    .lesson .blurb {
      font-family: var(--font-mono);
      font-size: 0.78rem;
      color: var(--fg-muted);
      margin-top: 0.45rem;
      line-height: 1.4;
    }

    .lesson.future {
      background: rgba(255, 255, 255, 0.02);
      border: 1px dashed rgba(255, 255, 255, 0.08);
      opacity: 0.42;
      cursor: default;
    }
    .lesson.future:hover {
      transform: none;
      background: rgba(255, 255, 255, 0.02);
      border-color: rgba(255, 255, 255, 0.08);
    }
    .lesson.future .num,
    .lesson.future .title { color: var(--fg-muted); }
    .lesson.future .blurb { color: var(--fg-subtle); }

    footer {
      margin-top: 4rem;
      padding-top: 1.5rem;
      border-top: 1px solid rgba(255,255,255,0.06);
      font-size: 0.9rem;
      color: var(--fg-subtle);
    }
    footer a { color: var(--lua-light); text-decoration: none; }
    footer a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <main>
    <h1>Lua Training</h1>
    <p class="lead">A Lua 5.4 programming course delivered as code + per-lesson reveal.js slide decks. Starts at programming-101 and finishes with coroutines, performance, packaging with LuaRocks, and embedding.</p>

]==]

M.TAIL = [==[
    <footer>
      Source: <a href="https://github.com/ristkari-dev/lua-training">github.com/ristkari-dev/lua-training</a>
    </footer>
  </main>
</body>
</html>
]==]

return M
```

- [ ] **Step 2: Verify the module loads and constants are non-empty**

Run: `.lua/bin/lua -e 'package.path="tools/build-index/?.lua;"..package.path; local t=require("template"); assert(t.HEAD:find("Lua Training", 1, true)); assert(t.TAIL:find("</html>", 1, true)); print("ok")'`
Expected: `ok`.

- [ ] **Step 3: Lint**

Run: `.lua/bin/luacheck tools/build-index`
Expected: 0 warnings / 0 errors.

- [ ] **Step 4: Commit**

```bash
git add tools/build-index/template.lua
git commit -m "feat(build-index): add Lua-branded landing-page HTML template"
```

---

## Task 3: Implement the builder with specs

**Files:**
- Create: `tools/build-index/builder.lua`
- Create: `tools/build-index/spec/builder_spec.lua`

Functions:
- `escape_html(s)` — escape `&`, `<`, `>` (in that order).
- `collect_published(lessons_dir)` — a set (`{ [dir_name]=true }`) of directory names under `lessons_dir` that contain a `slides/` subdir; empty table if `lessons_dir` is missing.
- `copy_tree(src, dst)` — recursively mirror `src` into `dst`, creating dirs; no-op if `src` missing; binary-safe.
- `rmtree(path)` — recursively delete a file or directory tree; no-op if missing.
- `render_index(published)` — `HEAD` + phase/lesson body + `TAIL`; published lessons become `<a>` links, others `<div class="lesson future">`.
- `build(lessons_dir, shared_dir, out_dir)` — clear `out_dir`, copy each published lesson's `slides/` to `out_dir/lessons/<name>/slides/`, copy `shared_dir` to `out_dir/shared/reveal/`, write `out_dir/index.html`.

- [ ] **Step 1: Write the failing spec**

Path: `tools/build-index/spec/builder_spec.lua`

```lua
local here = debug.getinfo(1, "S").source:match("^@(.*/)")
package.path = here .. "../?.lua;" .. package.path
local builder = require("builder")
local lfs = require("lfs")

local _counter = 0
local function tmpdir()
  _counter = _counter + 1
  local base = (os.getenv("TMPDIR") or "/tmp"):gsub("/+$", "")
  local path = string.format("%s/lua-training-build-%d-%d", base, os.time(), _counter)
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

local function read_file(path)
  local f = assert(io.open(path, "rb"))
  local data = f:read("*a")
  f:close()
  return data
end

local function count(haystack, needle)
  local n, pos = 0, 1
  while true do
    local s = haystack:find(needle, pos, true)
    if not s then
      return n
    end
    n = n + 1
    pos = s + #needle
  end
end

describe("escape_html", function()
  it("escapes &, <, >", function()
    assert.are.equal("a &amp; b &lt; c &gt; d", builder.escape_html("a & b < c > d"))
  end)
end)

describe("collect_published", function()
  it("finds lessons with a slides/ subdir", function()
    local root = tmpdir()
    mkpath(root .. "/01-hello/slides")
    mkpath(root .. "/02-values-types") -- no slides/
    local pub = builder.collect_published(root)
    assert.is_true(pub["01-hello"])
    assert.is_nil(pub["02-values-types"])
  end)

  it("is empty when the dir is missing", function()
    assert.are.same({}, builder.collect_published(tmpdir() .. "/nope"))
  end)

  it("ignores files at the top level", function()
    local root = tmpdir()
    mkpath(root .. "/01-hello/slides")
    write_file(root .. "/stray.txt", "x")
    local pub = builder.collect_published(root)
    assert.is_true(pub["01-hello"])
    assert.is_nil(pub["stray.txt"])
  end)
end)

describe("copy_tree", function()
  it("copies files and directories", function()
    local root = tmpdir()
    mkpath(root .. "/src/sub")
    write_file(root .. "/src/a.txt", "a")
    write_file(root .. "/src/sub/b.txt", "b")
    builder.copy_tree(root .. "/src", root .. "/dst")
    assert.are.equal("a", read_file(root .. "/dst/a.txt"))
    assert.are.equal("b", read_file(root .. "/dst/sub/b.txt"))
  end)

  it("is a no-op when src is missing", function()
    local root = tmpdir()
    builder.copy_tree(root .. "/nope", root .. "/dst")
    assert.is_nil(lfs.attributes(root .. "/dst", "mode"))
  end)
end)

describe("render_index", function()
  it("renders a published lesson as a link", function()
    local html = builder.render_index({ ["01-hello"] = true })
    assert.is_truthy(html:find('<a class="lesson" href="lessons/01-hello/slides/">', 1, true))
  end)

  it("renders an unpublished lesson as a future placeholder", function()
    local html = builder.render_index({})
    assert.is_truthy(html:find('<div class="lesson future" aria-disabled="true">', 1, true))
  end)

  it("contains the title and phase headers", function()
    local html = builder.render_index({})
    assert.is_truthy(html:find("<title>Lua Training</title>", 1, true))
    assert.is_truthy(html:find("Phase 1 · Foundations", 1, true))
    assert.is_truthy(html:find("Phase 3 · Idiomatic &amp; Advanced Lua", 1, true))
  end)

  it("lists lesson titles", function()
    local html = builder.render_index({})
    assert.is_truthy(html:find("Hello, Lua", 1, true))
    assert.is_truthy(html:find("Capstone: embeddable scripting host", 1, true))
  end)
end)

describe("build", function()
  it("produces index.html and copies slides + shared", function()
    local root = tmpdir()
    mkpath(root .. "/lessons/01-hello/slides")
    write_file(root .. "/lessons/01-hello/slides/index.html", "deck")
    mkpath(root .. "/shared/reveal/dist")
    write_file(root .. "/shared/reveal/dist/reveal.css", "/* css */")
    local out = root .. "/dist"

    builder.build(root .. "/lessons", root .. "/shared/reveal", out)

    assert.are.equal("deck", read_file(out .. "/lessons/01-hello/slides/index.html"))
    assert.are.equal("/* css */", read_file(out .. "/shared/reveal/dist/reveal.css"))
    local index = read_file(out .. "/index.html")
    assert.is_truthy(index:find("<title>Lua Training</title>", 1, true))
    assert.is_truthy(index:find('<a class="lesson" href="lessons/01-hello/slides/">', 1, true))
  end)

  it("overwrites a stale out dir", function()
    local root = tmpdir()
    mkpath(root .. "/lessons/01-hello/slides")
    mkpath(root .. "/shared/reveal")
    local out = root .. "/dist"
    mkpath(out)
    write_file(out .. "/stale.txt", "stale")

    builder.build(root .. "/lessons", root .. "/shared/reveal", out)

    assert.is_nil(lfs.attributes(out .. "/stale.txt", "mode"))
    assert.is_truthy(lfs.attributes(out .. "/index.html", "mode"))
  end)

  it("handles zero published lessons (all 23 are future placeholders)", function()
    local root = tmpdir()
    local out = root .. "/dist"
    builder.build(root .. "/lessons", root .. "/shared/reveal", out)
    local index = read_file(out .. "/index.html")
    assert.is_truthy(index:find("<title>Lua Training</title>", 1, true))
    assert.are.equal(23, count(index, 'class="lesson future"'))
  end)
end)
```

- [ ] **Step 2: Run the spec to verify it fails**

Run: `.lua/bin/busted tools/build-index/spec/builder_spec.lua`
Expected: error — `module 'builder' not found`.

- [ ] **Step 3: Implement `builder.lua`**

Path: `tools/build-index/builder.lua`

```lua
-- Filesystem operations and HTML rendering for the static slide site.
local lfs = require("lfs")
local catalog = require("catalog")
local template = require("template")

local M = {}

local function attr_mode(path)
  return lfs.attributes(path, "mode")
end

local function read_file(path)
  local f, err = io.open(path, "rb")
  if not f then
    error(("cannot read %q: %s"):format(path, tostring(err)), 0)
  end
  local data = f:read("*a")
  f:close()
  return data
end

local function write_file(path, data)
  local f, err = io.open(path, "wb")
  if not f then
    error(("cannot write %q: %s"):format(path, tostring(err)), 0)
  end
  f:write(data)
  f:close()
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

function M.escape_html(text)
  local out = text:gsub("&", "&amp;")
  out = out:gsub("<", "&lt;")
  out = out:gsub(">", "&gt;")
  return out
end

function M.collect_published(lessons_dir)
  local published = {}
  if attr_mode(lessons_dir) ~= "directory" then
    return published
  end
  for entry in lfs.dir(lessons_dir) do
    if entry ~= "." and entry ~= ".." then
      if attr_mode(lessons_dir .. "/" .. entry .. "/slides") == "directory" then
        published[entry] = true
      end
    end
  end
  return published
end

function M.copy_tree(src, dst)
  if attr_mode(src) == nil then
    return
  end
  mkdir_p(dst)
  for entry in lfs.dir(src) do
    if entry ~= "." and entry ~= ".." then
      local sp = src .. "/" .. entry
      local dp = dst .. "/" .. entry
      local mode = attr_mode(sp)
      if mode == "directory" then
        M.copy_tree(sp, dp)
      elseif mode == "file" then
        write_file(dp, read_file(sp))
      end
    end
  end
end

function M.rmtree(path)
  local mode = attr_mode(path)
  if mode == nil then
    return
  end
  if mode == "directory" then
    for entry in lfs.dir(path) do
      if entry ~= "." and entry ~= ".." then
        M.rmtree(path .. "/" .. entry)
      end
    end
    lfs.rmdir(path)
  else
    os.remove(path)
  end
end

local function render_lesson(lesson, published)
  local title = M.escape_html(lesson.title)
  local blurb = M.escape_html(lesson.blurb)
  local number = lesson.number
  local dir = catalog.dir_name(lesson)
  if published[dir] then
    return ('      <a class="lesson" href="lessons/%s/slides/">\n'):format(dir)
      .. ('        <div class="num">%s</div>\n'):format(number)
      .. ('        <div class="title">%s</div>\n'):format(title)
      .. ('        <div class="blurb">%s</div>\n'):format(blurb)
      .. "      </a>\n"
  end
  return '      <div class="lesson future" aria-disabled="true">\n'
    .. ('        <div class="num">%s</div>\n'):format(number)
    .. ('        <div class="title">%s</div>\n'):format(title)
    .. ('        <div class="blurb">%s</div>\n'):format(blurb)
    .. "      </div>\n"
end

function M.render_index(published)
  local parts = {}
  for _, phase in ipairs(catalog.PHASES) do
    local num, name = phase[1], phase[2]
    parts[#parts + 1] =
      ('    <div class="phase">Phase %d · %s</div>\n'):format(num, M.escape_html(name))
    parts[#parts + 1] = '    <div class="grid">\n'
    for _, lesson in ipairs(catalog.LESSONS) do
      if lesson.phase == num then
        parts[#parts + 1] = render_lesson(lesson, published)
      end
    end
    parts[#parts + 1] = "    </div>\n"
  end
  return template.HEAD .. table.concat(parts) .. template.TAIL
end

function M.build(lessons_dir, shared_dir, out_dir)
  M.rmtree(out_dir)
  mkdir_p(out_dir)
  local published = M.collect_published(lessons_dir)
  for name in pairs(published) do
    M.copy_tree(lessons_dir .. "/" .. name .. "/slides", out_dir .. "/lessons/" .. name .. "/slides")
  end
  M.copy_tree(shared_dir, out_dir .. "/shared/reveal")
  write_file(out_dir .. "/index.html", M.render_index(published))
end

return M
```

- [ ] **Step 4: Run the spec to verify it passes**

Run: `.lua/bin/busted tools/build-index/spec/builder_spec.lua`
Expected: `13 successes / 0 failures / 0 errors` (1 + 3 + 2 + 4 + 3).

- [ ] **Step 5: Lint**

Run: `.lua/bin/luacheck tools/build-index`
Expected: 0 warnings / 0 errors.

- [ ] **Step 6: Commit**

```bash
git add tools/build-index/builder.lua tools/build-index/spec/builder_spec.lua
git commit -m "feat(build-index): implement escape_html/collect_published/copy_tree/rmtree/render_index/build"
```

---

## Task 4: Add the `build-index` CLI

**Files:**
- Create: `tools/build-index/main.lua`

- [ ] **Step 1: Write the CLI**

Path: `tools/build-index/main.lua`

```lua
-- CLI: lua tools/build-index/main.lua [--lessons DIR] [--shared DIR] [--out DIR]
local here = arg[0]:match("^(.*/)") or "./"
package.path = here .. "?.lua;" .. package.path

local builder = require("builder")

local USAGE =
  "usage: lua tools/build-index/main.lua [--lessons DIR] [--shared DIR] [--out DIR]"

local function main(argv)
  local opts = { lessons = "lessons", shared = "shared/reveal", out = "dist" }
  local i = 1
  while i <= #argv do
    local a = argv[i]
    if a == "--lessons" then
      opts.lessons = argv[i + 1]
      i = i + 2
    elseif a == "--shared" then
      opts.shared = argv[i + 1]
      i = i + 2
    elseif a == "--out" then
      opts.out = argv[i + 1]
      i = i + 2
    elseif a == "--help" or a == "-h" then
      print(USAGE)
      return 0
    else
      io.stderr:write("error: unknown argument: " .. tostring(a) .. "\n")
      return 1
    end
  end
  builder.build(opts.lessons, opts.shared, opts.out)
  print("built " .. opts.out)
  return 0
end

os.exit(main(arg))
```

- [ ] **Step 2: Smoke `--help`**

Run: `.lua/bin/lua tools/build-index/main.lua --help`
Expected: prints the usage line; exit 0.

- [ ] **Step 3: Smoke a real build (zero lessons currently) into a temp out dir**

Run:
```bash
.lua/bin/lua tools/build-index/main.lua --out /tmp/lt-dist-smoke
test -f /tmp/lt-dist-smoke/index.html && echo "index ok"
grep -q "Lua Training" /tmp/lt-dist-smoke/index.html && echo "title ok"
grep -c 'class="lesson future"' /tmp/lt-dist-smoke/index.html   # expect 23
test -f /tmp/lt-dist-smoke/shared/reveal/dist/reveal.css && echo "reveal copied"
rm -rf /tmp/lt-dist-smoke
```
Expected: prints `built /tmp/lt-dist-smoke`, then `index ok`, `title ok`, `23`, `reveal copied`.

- [ ] **Step 4: Lint**

Run: `.lua/bin/luacheck tools/build-index`
Expected: 0 warnings / 0 errors.

- [ ] **Step 5: Commit**

```bash
git add tools/build-index/main.lua
git commit -m "feat(build-index): add CLI entry point"
```

---

## Task 5: Wire `slides-build` and `slides-docker` into the Makefile

**Files:**
- Modify: `Makefile`

- [ ] **Step 1: Append the two targets**

Add to the END of `Makefile` (after `slides-dev`). Recipe lines MUST use real TABs.

```makefile
.PHONY: slides-build
slides-build: ## Build the static slides site into dist/
	$(LUA) tools/build-index/main.lua --lessons lessons --shared shared/reveal --out dist

.PHONY: slides-docker
slides-docker: ## Build the deploy image and run it locally on http://localhost:8080
	docker build -t lua-training-slides:local -f deploy/Dockerfile .
	@echo "starting container on http://localhost:8080  (Ctrl-C to stop)"
	docker run --rm -p 8080:8080 -e PORT=8080 lua-training-slides:local
```

- [ ] **Step 2: Verify the targets list and `slides-build` works**

Run: `make help | grep -E 'slides-build|slides-docker'`
Expected: both lines appear with descriptions.

Run: `make slides-build`
Expected: prints `built dist`. Then:
```bash
test -f dist/index.html && grep -q "Lua Training" dist/index.html && echo "dist ok"
```
Expected: `dist ok`.

- [ ] **Step 3: Confirm `dist/` is gitignored**

Run: `git status --porcelain dist/`
Expected: NO output (`dist/` is ignored by the root-anchored `/dist/` rule from Plan A). If `dist/` shows as untracked, STOP and report.

- [ ] **Step 4: Clean the build artifact and commit only the Makefile**

```bash
rm -rf dist
git add Makefile
git commit -m "build: add slides-build and slides-docker make targets"
```

---

## Task 6: Add the deploy Dockerfile

**Files:**
- Create: `deploy/Dockerfile`

Two stages: an Alpine builder with `lua5.4` + `lua5.4-filesystem` that runs `build-index` to produce `/dist`; then an `nginx-unprivileged` runtime that serves `/dist`. The runtime image contains no Lua.

- [ ] **Step 1: Create `deploy/Dockerfile`**

```dockerfile
# syntax=docker/dockerfile:1.7

# --- Stage 1: build the static dist/ with Lua + LuaFileSystem ---
FROM alpine:3.20 AS builder
RUN apk add --no-cache lua5.4 lua5.4-filesystem
WORKDIR /src

# Copy the whole repo; build-index needs lessons/, shared/, and the tool.
COPY . .

# Render the landing page + copy decks + vendored reveal.js into /dist.
RUN lua5.4 tools/build-index/main.lua \
    --lessons /src/lessons \
    --shared /src/shared/reveal \
    --out /dist

# --- Stage 2: serve dist/ with non-root nginx ---
FROM nginxinc/nginx-unprivileged:alpine
USER root
COPY deploy/nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=builder /dist /usr/share/nginx/html
# Drop back to the unprivileged user the image ships with (UID 101).
USER 101
EXPOSE 8080
```

> **Why no luarocks in the image:** Alpine ships `lua5.4-filesystem` (LuaFileSystem) as a package on `lua5.4`'s default module path, so `build-index`'s `require("lfs")` resolves with just two `apk` packages — no compiler, no luarocks. `build-index` needs only `lfs` (not `luasocket`, which is dev-server-only). **Fallback if `lua5.4-filesystem` is unavailable in the chosen Alpine tag:** replace the `apk add` line with `apk add --no-cache lua5.4 lua5.4-dev luarocks5.4 build-base` and add `RUN luarocks-5.4 install luafilesystem` before the build step. Verify the actual build in Task 12.

- [ ] **Step 2: Shape-check the Dockerfile**

Run: `grep -q "nginx-unprivileged" deploy/Dockerfile && grep -q "build-index" deploy/Dockerfile && echo "dockerfile shape ok"`
Expected: `dockerfile shape ok`. (A full `docker build` is exercised in Task 12.)

- [ ] **Step 3: Commit**

```bash
git add deploy/Dockerfile
git commit -m "build: add two-stage deploy Dockerfile (lua builder -> nginx runtime)"
```

---

## Task 7: Add the nginx config template

**Files:**
- Create: `deploy/nginx.conf.template`

`nginx-unprivileged` substitutes `${PORT}` from the environment at container start (Cloud Run injects `PORT`, default 8080). Static assets cache for an hour; HTML/markdown are no-cache so deploys propagate immediately.

- [ ] **Step 1: Create `deploy/nginx.conf.template`**

```nginx
server {
    listen ${PORT} default_server;
    listen [::]:${PORT} default_server;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    # Static assets: cache for an hour
    location ~* \.(?:js|mjs|css|svg|woff2?|ttf|otf|png|jpg|jpeg|gif|ico|map)$ {
        expires 1h;
        add_header Cache-Control "public, max-age=3600";
        try_files $uri =404;
    }

    # HTML and markdown: no cache (so deploys propagate immediately)
    location ~* \.(?:html|md)$ {
        add_header Cache-Control "no-cache";
        try_files $uri =404;
    }

    # Default: try the file, then a directory's index.html, else 404
    location / {
        try_files $uri $uri/ =404;
    }

    # Favicon shouldn't 404 noisily if missing
    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add deploy/nginx.conf.template
git commit -m "build: add nginx config template for the slides runtime"
```

---

## Task 8: Add the Cloud Run service spec

**Files:**
- Create: `deploy/cloudrun.yaml`

A Knative-style service definition checked in for reproducibility. `__IMAGE__` is replaced by the deploy workflow with the freshly-pushed image reference.

- [ ] **Step 1: Create `deploy/cloudrun.yaml`**

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: lua-training-slides
  labels:
    cloud.googleapis.com/location: europe-north1
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/minScale: "0"
        autoscaling.knative.dev/maxScale: "2"
        run.googleapis.com/cpu-throttling: "true"
    spec:
      containerConcurrency: 80
      timeoutSeconds: 30
      containers:
        - image: __IMAGE__
          ports:
            - name: http1
              containerPort: 8080
          resources:
            limits:
              cpu: "1"
              memory: 256Mi
  traffic:
    - percent: 100
      latestRevision: true
```

- [ ] **Step 2: Commit**

```bash
git add deploy/cloudrun.yaml
git commit -m "build: add Cloud Run service spec (lua-training-slides)"
```

---

## Task 9: Add the idempotent GCP bootstrap script

**Files:**
- Create: `deploy/setup.sh` (executable)

Re-runnable `gcloud` bootstrap: enables APIs, creates the Artifact Registry repo, the deploy service account + roles, the WIF pool (shared) + a repo-scoped OIDC provider, and binds the repo to impersonate the SA. Prints the three GitHub secrets to set.

- [ ] **Step 1: Create `deploy/setup.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Idempotent GCP bootstrap for the lua-training slides deployment.
# Re-runnable: each step either creates the resource or no-ops if it already exists.

PROJECT_ID="${PROJECT_ID:-ristkari-dev}"
REGION="${REGION:-europe-north1}"
AR_REPO="${AR_REPO:-lua-training}"
SERVICE_NAME="${SERVICE_NAME:-lua-training-slides}"
SA_NAME="${SA_NAME:-github-deploy-lua}"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
WIF_POOL="${WIF_POOL:-github-actions}"
# Provider names must be unique-per-repo within the shared pool, because each
# provider has its own attribute condition restricting which GitHub repo can
# impersonate. Sibling repos own their own providers; use a repo-suffixed name.
WIF_PROVIDER="${WIF_PROVIDER:-github-lua-training}"
GITHUB_REPO="${GITHUB_REPO:-ristkari-dev/lua-training}"

bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
note()  { printf '  → %s\n' "$*"; }

bold "Project:        $PROJECT_ID"
bold "Region:         $REGION"
bold "AR repo:        $AR_REPO"
bold "Service:        $SERVICE_NAME"
bold "Service acct:   $SA_EMAIL"
bold "WIF pool:       $WIF_POOL"
bold "WIF provider:   $WIF_PROVIDER"
bold "GitHub repo:    $GITHUB_REPO"
echo

bold "1. Enabling required APIs"
gcloud services enable \
    artifactregistry.googleapis.com \
    iamcredentials.googleapis.com \
    run.googleapis.com \
    sts.googleapis.com \
    --project="$PROJECT_ID"

bold "2. Creating Artifact Registry repo (if missing)"
if gcloud artifacts repositories describe "$AR_REPO" \
        --location="$REGION" --project="$PROJECT_ID" >/dev/null 2>&1; then
    note "repo $AR_REPO already exists, skipping"
else
    gcloud artifacts repositories create "$AR_REPO" \
        --repository-format=docker \
        --location="$REGION" \
        --description="lua-training container images" \
        --project="$PROJECT_ID"
fi

bold "3. Creating service account (if missing)"
if gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" >/dev/null 2>&1; then
    note "service account $SA_EMAIL already exists, skipping"
else
    gcloud iam service-accounts create "$SA_NAME" \
        --display-name="GitHub Actions deploy for lua-training" \
        --project="$PROJECT_ID"
fi

bold "4. Granting roles to the service account"
for role in \
    roles/artifactregistry.writer \
    roles/run.admin \
    roles/iam.serviceAccountUser \
; do
    note "binding $role"
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$SA_EMAIL" \
        --role="$role" \
        --condition=None \
        --quiet >/dev/null
done

bold "5. Creating Workload Identity Federation pool (if missing)"
if gcloud iam workload-identity-pools describe "$WIF_POOL" \
        --location=global --project="$PROJECT_ID" >/dev/null 2>&1; then
    note "pool $WIF_POOL already exists, skipping"
else
    gcloud iam workload-identity-pools create "$WIF_POOL" \
        --location=global \
        --display-name="GitHub Actions" \
        --project="$PROJECT_ID"
fi

POOL_NAME=$(gcloud iam workload-identity-pools describe "$WIF_POOL" \
    --location=global --project="$PROJECT_ID" --format='value(name)')

bold "6. Creating WIF OIDC provider for GitHub (if missing)"
if gcloud iam workload-identity-pools providers describe "$WIF_PROVIDER" \
        --location=global --workload-identity-pool="$WIF_POOL" \
        --project="$PROJECT_ID" >/dev/null 2>&1; then
    note "provider $WIF_PROVIDER already exists, skipping"
else
    gcloud iam workload-identity-pools providers create-oidc "$WIF_PROVIDER" \
        --location=global \
        --workload-identity-pool="$WIF_POOL" \
        --display-name="GitHub OIDC" \
        --issuer-uri="https://token.actions.githubusercontent.com" \
        --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref" \
        --attribute-condition="assertion.repository == '${GITHUB_REPO}'" \
        --project="$PROJECT_ID"
fi

PROVIDER_NAME=$(gcloud iam workload-identity-pools providers describe "$WIF_PROVIDER" \
    --location=global --workload-identity-pool="$WIF_POOL" \
    --project="$PROJECT_ID" --format='value(name)')

bold "7. Allowing the GitHub repo to impersonate the SA"
gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
    --role=roles/iam.workloadIdentityUser \
    --member="principalSet://iam.googleapis.com/${POOL_NAME}/attribute.repository/${GITHUB_REPO}" \
    --project="$PROJECT_ID" \
    --condition=None \
    --quiet >/dev/null

echo
bold "Done. Add these as GitHub repository secrets:"
echo
echo "  GCP_PROJECT_ID                 = $PROJECT_ID"
echo "  GCP_WORKLOAD_IDENTITY_PROVIDER = $PROVIDER_NAME"
echo "  GCP_SERVICE_ACCOUNT_EMAIL      = $SA_EMAIL"
echo
bold "Then create the Cloud Run service for the first time (deploy expects it to exist):"
echo
echo "  gcloud run deploy $SERVICE_NAME \\"
echo "      --image=gcr.io/cloudrun/hello \\"
echo "      --region=$REGION --project=$PROJECT_ID \\"
echo "      --platform=managed --allow-unauthenticated --port=8080"
echo
bold "Then map the custom domain (see deploy/README.md for the Cloudflare CNAME):"
echo "  gcloud beta run domain-mappings create \\"
echo "      --service=$SERVICE_NAME \\"
echo "      --domain=lua.ristkari.dev \\"
echo "      --region=$REGION --project=$PROJECT_ID"
```

- [ ] **Step 2: Make it executable and verify it parses**

```bash
chmod +x deploy/setup.sh
bash -n deploy/setup.sh && echo "syntax ok"
```
Expected: `syntax ok`.

- [ ] **Step 3: Commit**

```bash
git add deploy/setup.sh
git commit -m "build: add idempotent GCP bootstrap script for deploy"
```

---

## Task 10: Add the deploy README

**Files:**
- Create: `deploy/README.md`

- [ ] **Step 1: Create `deploy/README.md`**

````markdown
# Deploying lua-training slides

The slides site is built into a Docker image, pushed to Google Artifact
Registry, and served by Cloud Run. A push to `main` triggers
`.github/workflows/deploy.yml` which does the build → push → deploy.

The custom domain `https://lua.ristkari.dev/` points at the Cloud Run
service via a Cloudflare CNAME (DNS-only).

This file documents the **one-time setup** you do once per project, not what
runs on every push.

## Prerequisites

- `gcloud` CLI authenticated as an account with Owner (or sufficient roles) on
  the `ristkari-dev` project.
- `gh` CLI authenticated against `ristkari-dev/lua-training` for setting
  repo secrets (or set them in the GitHub UI).
- Cloudflare access for the `ristkari.dev` zone.

## Step 1 — bootstrap GCP

```bash
./deploy/setup.sh
```

Idempotent / re-runnable. It enables the required APIs, creates Artifact
Registry repo `lua-training` in `europe-north1`, creates service account
`github-deploy-lua@ristkari-dev.iam.gserviceaccount.com` with
`artifactregistry.writer` + `run.admin` + `iam.serviceAccountUser`, creates the
shared `github-actions` WIF pool (if missing) and a repo-scoped OIDC provider
`github-lua-training`, binds the repo to impersonate the SA, and prints the
three values to set as GitHub repo secrets.

## Step 2 — set GitHub repo secrets

```bash
gh secret set GCP_PROJECT_ID                 -b "ristkari-dev"
gh secret set GCP_WORKLOAD_IDENTITY_PROVIDER -b "<value-from-setup-output>"
gh secret set GCP_SERVICE_ACCOUNT_EMAIL      -b "github-deploy-lua@ristkari-dev.iam.gserviceaccount.com"
```

Or set them in the GitHub UI: **Settings → Secrets and variables → Actions**.

## Step 3 — first-time service materialisation

The deploy workflow uses `gcloud run services replace deploy/cloudrun.yaml`,
which works only if the service already exists. Create it once with a
placeholder image:

```bash
gcloud run deploy lua-training-slides \
    --image=gcr.io/cloudrun/hello \
    --region=europe-north1 \
    --project=ristkari-dev \
    --platform=managed \
    --allow-unauthenticated \
    --port=8080
```

The first push to `main` then replaces it with the real image.

## Step 4 — map the custom domain

```bash
gcloud beta run domain-mappings create \
    --service=lua-training-slides \
    --domain=lua.ristkari.dev \
    --region=europe-north1 \
    --project=ristkari-dev
```

Output includes a CNAME target like `ghs.googlehosted.com.`.

## Step 5 — Cloudflare DNS

Add a CNAME in the Cloudflare dashboard for `ristkari.dev`:

| Type  | Name | Target                 | Proxy status              |
|-------|------|------------------------|---------------------------|
| CNAME | lua  | `ghs.googlehosted.com` | **DNS only** (gray cloud) |

Leave it gray — Cloudflare proxying (orange cloud) breaks Cloud Run's managed
TLS at the mapped hostname.

Verify:

```bash
dig lua.ristkari.dev CNAME +short
gcloud beta run domain-mappings describe \
    --domain=lua.ristkari.dev \
    --region=europe-north1 \
    --project=ristkari-dev
```

`READY=True` and HTTPS serving follow once Google provisions the managed
certificate (a few minutes after DNS propagates).

## Verifying a deploy

```bash
gh run watch                                   # watch the deploy workflow
curl -sS -I https://lua.ristkari.dev/          # expect HTTP/2 200, text/html
```

Service URL without the custom domain:

```bash
gcloud run services describe lua-training-slides \
    --region=europe-north1 --project=ristkari-dev \
    --format='value(status.url)'
```

## Rolling back

```bash
gcloud run revisions list --service=lua-training-slides \
    --region=europe-north1 --project=ristkari-dev
gcloud run services update-traffic lua-training-slides \
    --to-revisions=lua-training-slides-<previous-revision>=100 \
    --region=europe-north1 --project=ristkari-dev
```
````

- [ ] **Step 2: Commit**

```bash
git add deploy/README.md
git commit -m "docs: add deploy/README with one-time GCP + Cloudflare setup"
```

---

## Task 11: Add the CI and deploy GitHub Actions workflows

**Files:**
- Create: `.github/workflows/ci.yml`
- Create: `.github/workflows/deploy.yml`

- [ ] **Step 1: Create `.github/workflows/ci.yml`**

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # The repo's own toolchain: hererocks builds a pinned Lua 5.4 + LuaRocks
      # into ./.lua (scripts/bootstrap self-provisions hererocks into a venv).
      # Cache it so only the first run pays the build cost.
      - name: Cache Lua toolchain
        id: cache-lua
        uses: actions/cache@v4
        with:
          path: |
            .lua
            .bootstrap-venv
          key: lua-${{ runner.os }}-${{ hashFiles('scripts/bootstrap') }}

      - name: Bootstrap toolchain
        if: steps.cache-lua.outputs.cache-hit != 'true'
        run: make bootstrap

      - name: Lint (luacheck)
        run: make lint

      - name: Tests (busted)
        run: make test

      - name: Build static slides site
        run: make slides-build

      - name: Verify dist contents
        run: |
          test -f dist/index.html
          grep -q "Lua Training" dist/index.html
```

> **Why no lesson-test step yet:** `lessons/` holds only `.gitkeep` in Plan B; `make test` runs the tool specs (and the empty lesson loop is a no-op). When Phase 1 adds lessons, `make test` already picks up each lesson's `solutions/`.

- [ ] **Step 2: Create `.github/workflows/deploy.yml`**

```yaml
name: Deploy

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  id-token: write

env:
  REGION: europe-north1
  AR_REPO: lua-training
  IMAGE_NAME: slides
  SERVICE_NAME: lua-training-slides

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Verify required secrets are set
        env:
          PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
          WIP: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          SA: ${{ secrets.GCP_SERVICE_ACCOUNT_EMAIL }}
        run: |
          missing=()
          [ -z "$PROJECT_ID" ] && missing+=("GCP_PROJECT_ID")
          [ -z "$WIP" ]        && missing+=("GCP_WORKLOAD_IDENTITY_PROVIDER")
          [ -z "$SA" ]         && missing+=("GCP_SERVICE_ACCOUNT_EMAIL")
          if [ ${#missing[@]} -ne 0 ]; then
            echo "::error::Missing required secrets: ${missing[*]}"
            echo "See deploy/README.md for setup instructions."
            exit 1
          fi

      - id: auth
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ secrets.GCP_SERVICE_ACCOUNT_EMAIL }}

      - uses: google-github-actions/setup-gcloud@v2

      - name: Configure Docker for Artifact Registry
        env:
          REGION: ${{ env.REGION }}
        run: gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet

      - name: Build and push image
        id: build
        env:
          REGION: ${{ env.REGION }}
          AR_REPO: ${{ env.AR_REPO }}
          IMAGE_NAME: ${{ env.IMAGE_NAME }}
          PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
          SHA: ${{ github.sha }}
        run: |
          IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${AR_REPO}/${IMAGE_NAME}:${SHA}"
          docker build -t "$IMAGE" -f deploy/Dockerfile .
          docker push "$IMAGE"
          echo "image=$IMAGE" >> "$GITHUB_OUTPUT"

      - name: Render Cloud Run spec
        env:
          IMAGE: ${{ steps.build.outputs.image }}
        run: |
          sed "s|__IMAGE__|${IMAGE}|" deploy/cloudrun.yaml > /tmp/cloudrun.rendered.yaml

      - name: Deploy to Cloud Run
        env:
          REGION: ${{ env.REGION }}
          PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
        run: |
          gcloud run services replace /tmp/cloudrun.rendered.yaml \
              --region="$REGION" \
              --project="$PROJECT_ID"

      - name: Allow public access (idempotent)
        env:
          SERVICE_NAME: ${{ env.SERVICE_NAME }}
          REGION: ${{ env.REGION }}
          PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
        run: |
          gcloud run services add-iam-policy-binding "$SERVICE_NAME" \
              --region="$REGION" \
              --project="$PROJECT_ID" \
              --member=allUsers \
              --role=roles/run.invoker

      - name: Print service URL
        env:
          SERVICE_NAME: ${{ env.SERVICE_NAME }}
          REGION: ${{ env.REGION }}
          PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
        run: |
          gcloud run services describe "$SERVICE_NAME" \
              --region="$REGION" \
              --project="$PROJECT_ID" \
              --format='value(status.url)'
```

- [ ] **Step 3: Validate YAML parses**

Run:
```bash
.lua/bin/lua -e 'for _,p in ipairs({".github/workflows/ci.yml",".github/workflows/deploy.yml"}) do local f=assert(io.open(p)); local s=f:read("*a"); f:close(); assert(s:find("^name:")); end print("yaml shape ok")'
```
Expected: `yaml shape ok`. (Lua has no YAML parser; this confirms both files exist and start with a top-level `name:`. GitHub validates the full schema on push.)

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/ci.yml .github/workflows/deploy.yml
git commit -m "ci: add CI (lint/test/build) and Cloud Run deploy workflows"
```

---

## Task 12: Local Docker smoke test + final verification

This task's Docker sub-steps require Docker running locally. If Docker is unavailable, mark the Docker sub-steps BLOCKED-on-docker and report (do NOT fake results) — the deploy files are still valid and CI/deploy activate on push regardless.

- [ ] **Step 1: Check Docker availability**

Run: `docker info >/dev/null 2>&1 && echo "docker ok" || echo "docker unavailable"`
If `docker unavailable`, skip Steps 2–3 and note them BLOCKED-on-docker; still do Step 4.

- [ ] **Step 2: Build the deploy image**

Run: `docker build -t lua-training-slides:local -f deploy/Dockerfile .`
Expected: build succeeds. The builder stage runs `apk add lua5.4 lua5.4-filesystem` + `build-index`; the runtime stage is `nginx-unprivileged`. If the build fails at `apk add lua5.4-filesystem` (package not found in the Alpine tag), apply the Task 6 fallback (luarocks-based lfs install), commit that Dockerfile change with `git commit --amend` or a `fix(deploy):` commit, and rebuild.

- [ ] **Step 3: Run the container and curl it**

```bash
docker run --rm -d -p 8080:8080 -e PORT=8080 --name lt-slides-smoke lua-training-slides:local
sleep 2
curl -s -o /dev/null -w "root=%{http_code}\n" http://127.0.0.1:8080/
curl -s http://127.0.0.1:8080/ | grep -o "<title>[^<]*</title>"
curl -s -o /dev/null -w "revealcss=%{http_code}\n" http://127.0.0.1:8080/shared/reveal/dist/reveal.css
curl -s -o /dev/null -w "notfound=%{http_code}\n" http://127.0.0.1:8080/nope.txt
docker stop lt-slides-smoke
```
Expected: `root=200`, `<title>Lua Training</title>`, `revealcss=200`, `notfound=404`.

- [ ] **Step 4: Full local quality bar**

```bash
make lint
make test
make slides-build && test -f dist/index.html && grep -q "Lua Training" dist/index.html && echo "build ok"
rm -rf dist
```
Expected: lint clean (0/0); `make test` → **42 successes** (9 new-lesson + 13 slides-dev + 7 catalog + 13 builder); `build ok`.

- [ ] **Step 5: Confirm no stray artifacts**

Run: `git status --porcelain`
Expected: clean (no `dist/`, no container leftovers, no `/tmp` smoke dirs tracked).

- [ ] **Step 6: Final commit (only if anything needs tidying)**

If `git status` shows changes, investigate and commit intentionally. If clean, skip.

---

## Notes for execution

- **No `gcloud`, no `git push`, no secrets** are touched by this plan. The deploy files are written and locally validated; activating the pipeline is the owner's manual one-time `deploy/setup.sh` + secret-setting + DNS, documented in `deploy/README.md`.
- The deploy workflow runs on the first push to `main` after merge, but fails fast at "Verify required secrets" until the owner completes the one-time setup — the intended, safe default.
- After this plan, `lessons/` still holds only `.gitkeep`; the landing page shows all 23 lessons as faded placeholders, the correct pre-content state. Authoring lessons is Plan C onward.
- **Spec coverage:** this plan completes the spec's "Slide deck workflow → Build for deployment" and "Deployment workflow" sections, plus the `tools/build-index` and `catalog.lua` items. Type checking is intentionally absent (the spec's luacheck-only decision).
