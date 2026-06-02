# Lua Training Course — Design

**Status:** Approved (brainstorming complete, awaiting implementation plan)
**Date:** 2026-06-02
**Owner:** Aki Ristkari

## Summary

A Lua programming course delivered as both a code repository and per-lesson
reveal.js slide decks. The arc starts at "programming 101" and finishes with
the language's honest endgame — coroutines, performance, packaging with
LuaRocks, and **embedding** (running Lua inside a host, and extending Lua from
a host). It targets **Lua 5.4 (the PUC-Rio reference implementation)**.

The repository structure, slide pipeline, and deployment model intentionally
mirror the sibling [python-training](../../../../python-training) and
[go-training](../../../../go-training) courses so the family can share authoring
conventions and infrastructure patterns. Lua-specific differences — a dynamic
language, a single data structure (the table), metatables, coroutines, Lua
patterns instead of regex, and the embedding story — are called out throughout.

## Audience and delivery

- **Audience:** Software engineering students at the start; early-career and
  experienced engineers by the end. The same arc serves both, with optional
  "going further" material per lesson for stronger students.
- **Delivery:** Hybrid. Some lessons live (lectures + live coding), some
  self-study. Each lesson is sized for ~90 minutes of live time plus self-study.
- **Length:** ~23 lessons. Lua is a small language; the course favours depth on
  what makes Lua distinctive over filler.
- **Language:** English only.

## Key decisions

These were settled during brainstorming and drive everything below:

1. **Lua flavor — 5.4 reference (PUC-Rio).** Lessons may use 5.4 features:
   the integer/float number subtypes, bitwise operators, `goto`, the
   `<const>`/`<close>` variable attributes, and the generational GC. LuaJIT/5.1
   differences are flagged only where they genuinely matter; there is no
   LuaJIT-specific track.
2. **Focus — host-agnostic language + embedding.** Early/middle phases teach
   core Lua deeply. The course lands on packaging (LuaRocks) and embedding (the
   C API) rather than any one host ecosystem (Neovim/LÖVE/OpenResty).
3. **Static checks — `luacheck` is the gate.** Lua is dynamically typed; there
   is no enforced type checker. `luacheck` (undefined globals, unused/shadowed
   locals, arity) runs in CI. LuaLS `---@` annotations and runtime contracts are
   *taught* (lesson 13 and "going further"), not enforced.
4. **No C prerequisite.** The embedding lessons *ship* a working C host that is
   built and demoed; all graded exercise work happens in the **Lua** the host
   loads and runs. A pure-Lua fallback host ships too, so the graded `busted`
   specs run with no C toolchain — the C host is a runnable demo, not a test gate.

## Hands-on model

- Per-lesson exercises in a starter repo students clone.
- Each exercise ships **runnable starter code** (function stubs `error("TODO:
  …")` or return placeholder values) plus **failing `*_spec.lua` busted tests**
  that act as the spec. Students make the tests pass.
- Solutions ship in the same lesson folder under `solutions/`, committed to
  `main`. Students can peek if stuck.
- **`busted` is used from lesson 1** — treated as a "magic test runner" until
  lesson 6 explains it properly (`describe`/`it`/`assert`, `before_each`, spies).
- **No type checker is enforced.** `luacheck` is the static gate from lesson 1
  (it catches the typo'd-global class of bug, which bites hard in Lua). LuaLS
  `---@` annotations are introduced as documentation in lesson 13 and reused in
  "going further" sections, but never gate the build.

## Curriculum (23 lessons, four phases)

5.4-specific topics are marked ⁵⁴.

### Phase 1 — Foundations (lessons 1–7)

1. **`01-hello` — Hello, Lua** — install Lua 5.4 (via `hererocks`/`make
   bootstrap`), the REPL, running scripts (`lua file.lua`) vs the REPL, `print`,
   comments, a first function, a first `busted` test (magic).
2. **`02-values-types` — Values & types** — `nil`, `boolean`, **number
   (integer vs float subtype)** ⁵⁴, `string`; truthiness (only `nil`/`false`
   are falsy); `type`, `tostring`/`tonumber`.
3. **`03-variables-scope` — Variables & scope** — `local` vs global and why
   globals are dangerous; `local x <const>` ⁵⁴; blocks/chunks; multiple
   assignment and swap.
4. **`04-operators` — Operators & expressions** — arithmetic (`//` floor div,
   `%`, `^`), relational, logical (`and`/`or`/`not`, the `a and b or c` idiom),
   `..` concat, `#` length, **bitwise operators** ⁵⁴, precedence.
5. **`05-control-flow` — Control flow** — `if`/`elseif`/`else`, `while`,
   `repeat`/`until`, numeric `for`, generic `for` (teaser), `break`,
   `goto`/labels, and the missing `continue` (idioms around it).
6. **`06-functions-testing` — Functions & testing** — multiple return values,
   varargs (`...`), default-argument idioms, functions as first-class values,
   `select`. **`busted` introduced properly** — `describe`/`it`/`assert`,
   `before_each`, spies.
7. **`07-capstone-cli` — Phase 1 capstone (CLI)** — a small command-line script:
   the `arg` table, reading stdin/files with `io`, producing output, composed
   from several functions (e.g. a unit converter or word-count tool).

### Phase 2 — The Heart of Lua (lessons 8–13)

8. **`08-tables` — Tables: the one data structure** — arrays (**1-based**), maps,
   mixed tables, constructors, the `#`/border rule, the `table` library
   (`insert`/`remove`/`concat`/`sort`/`unpack`), `pairs`/`ipairs`; tables as
   records/sets/stacks/queues.
9. **`09-strings-patterns` — Strings & patterns** — the `string` library, **Lua
   patterns (not regex!)**: `find`/`match`/`gmatch`/`gsub`, captures, character
   classes, anchors; `string.format`; long strings `[[ ]]`.
10. **`10-metatables` — Metatables & metamethods** — `setmetatable`/
    `getmetatable`, `__index` (table and function), `__newindex`, arithmetic
    metamethods, `__eq`/`__lt`/`__concat`/`__tostring`/`__call`/`__len`; the
    lookup mechanics.
11. **`11-oop` — OOP in Lua** — building classes with metatables + `__index`, the
    `:` method-call sugar and `self`, single inheritance, encapsulation patterns,
    a small `class()` helper. (Lua has no built-in objects — you build them.)
12. **`12-modules` — Modules & require** — `require`, returning a module table,
    `package.path`/`package.loaded`/`package.preload`, organising multi-file
    programs, the no-globals discipline.
13. **`13-errors` — Errors & robustness** — `error`/`assert`/`pcall`/`xpcall`,
    error objects vs strings and error levels, the `nil, err` return convention,
    cleanup, `<close>` to-be-closed variables ⁵⁴. **Runtime contracts
    (`assert`/`type`) and LuaLS `---@` annotations are taught here** as
    documentation, not enforcement.

### Phase 3 — Idiomatic & Advanced Lua (lessons 14–18)

14. **`14-iterators` — Iterators & the generic for** — stateless vs stateful
    iterators, writing your own, `next`, closures as iterators.
15. **`15-closures` — Closures & functional Lua** — upvalues in depth,
    higher-order functions, memoization, immutability patterns.
16. **`16-coroutines` — Coroutines** — `create`/`resume`/`yield`/`status`/`wrap`,
    generators, cooperative scheduling, producer/consumer; coroutines vs threads.
    (Lua's signature concurrency feature.)
17. **`17-stdlib-io` — Standard library & I/O** — `os`, `io` (files, modes,
    streams), `math`, `string.pack`/`unpack`, `utf8`, `load`/`dofile`.
18. **`18-environments-gc` — Environments, GC & performance** — `_ENV`/`_G` and
    sandbox intuition, the **generational garbage collector** ⁵⁴,
    `collectgarbage`, weak tables, `__gc` finalizers, performance idioms
    (localise globals, preallocate tables, avoid churn).

### Phase 4 — Packaging & Embedding (lessons 19–23)

19. **`19-luarocks` — LuaRocks & writing a module** — the `.rockspec` format,
    install/build/publish a rock, semantic versioning, declaring dependencies,
    the rocks tree; package the Phase-2 library as a rock.
20. **`20-embedding` — Embedding Lua (host provided)** — read and run a supplied
    C host that loads and executes a Lua script; *demo* the stack model and how
    values cross the boundary. **The exercise is the Lua the host runs** (e.g. a
    config the host reads back) — no C writing required.
21. **`21-extending` — Extending Lua (host API provided)** — the supplied host
    exposes C functions to Lua; *demo* how a `lua_CFunction`/`luaL_newlib` is
    registered. **The exercise is Lua that uses that host API** and builds logic
    on top of it.
22. **`22-sandboxing` — Sandboxing & plugin patterns** — running untrusted
    scripts safely: a custom `_ENV`, stripped globals, instruction-count limits
    via `debug.sethook`; the "Lua as plugin/config language" pattern. All Lua.
23. **`23-capstone` — Capstone: an embeddable scripting host** — the provided
    host plus **your Lua plugin system / config-DSL**, tying together modules,
    OOP, coroutines, and the embedding model. A pure-Lua fallback host ships so
    the graded specs run without a C toolchain. Course wrap-up.

### Cross-cutting threads

- **Testing** — `busted` from lesson 1; testing technique deepens each phase.
- **Tooling** — `luacheck` and `StyLua` from lesson 1; CI runs both from the
  start. `hererocks` pins the Lua 5.4 toolchain.
- **Globals discipline** — Lua's accidental-global footgun is a recurring theme;
  `luacheck` enforces it and `local`/`<const>` are taught early.
- **"Going further"** — every lesson README has a section with optional advanced
  exercises, stdlib reading, LuaLS-annotation practice, and external links.

## Repository layout

```
lua-training/
├── README.md
├── CONTRIBUTING.md
├── Makefile                    # canonical entry point (make help)
├── .editorconfig
├── .gitignore
├── .luacheckrc                 # luacheck config (Lua 5.4 std, globals policy)
├── stylua.toml                 # StyLua config
├── .busted                     # busted run config (test roots)
├── scripts/
│   └── bootstrap               # hererocks + pinned rocks (busted, luacheck, …)
│
├── lessons/
│   ├── 01-hello/
│   │   ├── README.md           # self-study notes + "going further"
│   │   ├── slides/
│   │   │   ├── index.html
│   │   │   ├── slides.md
│   │   │   └── assets/
│   │   ├── exercises/
│   │   │   ├── hello.lua        # runnable but incomplete
│   │   │   └── hello_spec.lua   # failing busted tests (the spec)
│   │   └── solutions/
│   │       ├── hello.lua        # reference implementation
│   │       └── hello_spec.lua   # identical spec, passes
│   ├── 02-values-types/
│   ├── …
│   └── 23-capstone/
│
├── shared/
│   └── reveal/                 # vendored reveal.js 5.1.0 + theme + plugins (pinned)
│       ├── dist/
│       ├── plugin/
│       └── theme/lua-training.css
│
├── deploy/
│   ├── Dockerfile              # two-stage: lua+luarocks builder + nginx-unprivileged
│   ├── nginx.conf.template
│   ├── cloudrun.yaml
│   ├── setup.sh                # one-time GCP/WIF bootstrap (idempotent)
│   └── README.md
│
├── tools/                      # developer tooling, written in Lua (dogfooded)
│   ├── build-index/            # generates dist/index.html + copies decks
│   ├── slides-dev/             # local static server for one deck
│   └── new-lesson/             # scaffolds a new lesson from a template
│
├── docs/
│   └── superpowers/
│       ├── specs/              # design docs (this file)
│       └── plans/              # implementation plans
│
└── .github/
    └── workflows/
        ├── ci.yml
        └── deploy.yml
```

### Toolchain & dependency strategy

Lua has no single tool equivalent to `uv`/`cargo`. The reproducible setup is:

- **`make bootstrap`** runs `scripts/bootstrap`, which uses **`hererocks`** to
  install a pinned **Lua 5.4.x + LuaRocks** into a repo-local, git-ignored
  `.lua/` tree (the venv analogue), then `luarocks install`s the pinned dev
  rocks: **`busted`**, **`luacheck`**, **`luafilesystem`**, **`luasocket`**.
- **`StyLua`** is a standalone binary (not a rock); the README documents
  installing it via `brew install stylua` / a release download / `cargo install
  stylua`, exactly as `go-training` documents `golangci-lint`.
- **Lessons avoid third-party rocks.** The standard library plus `busted`
  (provided by bootstrap) cover the course. A lesson that genuinely needs a rock
  documents it in its README and adds it to `scripts/bootstrap`.
- The two tool dependencies — `luafilesystem` (directory walking/copy) and
  `luasocket` (the dev server) — are tooling deps, not lesson deps.
- No cross-lesson `require`s: each lesson is self-contained, so renumbering or
  rewriting a lesson never breaks another. Enforced by convention + `luacheck`.

## Anatomy of a lesson

Every `lessons/NN-slug/` folder contains four parts.

### `README.md`

1. **Learning goals** — 3–5 bullets.
2. **Prereqs** — links to earlier lessons.
3. **Concepts** — 1–3 paragraphs of prose mirroring the deck narrative.
4. **Exercise brief** — what to build, what `busted` should show when done.
5. **How to run** — `make test-lesson LESSON=NN-slug` (and `lua` invocations
   where applicable).
6. **Going further** — optional advanced material, including LuaLS-annotation
   practice.

### `slides/`

- `index.html` — minimal reveal.js bootstrap referencing `/shared/reveal/` with
  **absolute paths** (so decks render both under `slides-dev` and when deployed),
  configures the markdown plugin, points at `slides.md`.
- `slides.md` — markdown with `---` horizontal separators and `--` vertical
  (used sparingly). Code in fenced ` ```lua ` blocks. Speaker notes via `Note:`
  blocks. HTML escape hatches for layout/fragments.
- `assets/` — diagrams (SVG preferred); never images of code.

### `exercises/`

- One or more `.lua` modules with **runnable but incomplete** code: function
  shapes present, bodies `error("TODO: …")` or returning placeholders.
- One or more `*_spec.lua` files with **failing busted tests** — the spec.
- No third-party rocks unless the lesson explicitly introduces one.

### `solutions/`

- Same module shape as `exercises/`, fully implemented.
- Specs are identical to `exercises/` so swapping in `solutions/` and re-running
  `busted` passes.
- Brief `-- why:` comments only where a choice is non-obvious.

### Conventions

- Module files lowercase `snake_case.lua` (Lua convention); test files always
  `*_spec.lua` (busted convention).
- Lesson folder names `NN-kebab-case` with two-digit numbering (`01`…`23`) so
  listings sort naturally. Inside the folder the two literal directory names are
  `exercises` and `solutions`.
- Tables are 1-indexed; lessons lean into idiomatic Lua rather than porting
  habits from other languages.

## Slide deck workflow

### Authoring

- Markdown with HTML escape hatches.
- Code-heavy slides limited to ~15 visible lines; longer examples split across
  slides.
- First slide of every deck: lesson number, title, one-line learning goal.
- Last slide: a "what's next" pointer to the next lesson.
- Diagrams as SVG; never images of code.

### Shared assets

- `shared/reveal/` holds a pinned, vendored reveal.js **5.1.0** — no CDN, no npm.
  Copied verbatim from the sibling courses (same pinned version).
- `shared/reveal/theme/lua-training.css` is a custom theme tuned for code-heavy
  decks: monospace at a readable size, a Lua-blue accent palette
  (deep blue `#000080`/`#2c2d72` with a lighter-blue highlight), generous
  code-block padding, no distracting transitions.
- Default plugins: `markdown`, `highlight`, `notes`, `search`.

### Per-deck `index.html`

- Identical scaffolding across decks. Loads `/shared/reveal/dist/reveal.css`, the
  theme CSS, and a single `<section data-markdown="slides.md" …>`. Uses
  **absolute `/shared/...` paths** so the same file works locally and deployed.
- `<head>` sets the deck title from the lesson name.
- Generated by `make new-lesson` so authors don't copy-paste.

### Local development

- `make slides-dev LESSON=NN-slug` starts a local static server (`tools/slides-dev`,
  Lua + `luasocket`) on `localhost:8000` serving the requested lesson plus the
  shared assets, with a path-traversal guard.
- A server is needed because reveal.js's markdown plugin uses `fetch`, which
  doesn't work over `file://`.

### Build for deployment

- `make slides-build` runs `tools/build-index` (Lua + `luafilesystem`), which:
  1. Walks `lessons/*/slides/`.
  2. Generates `dist/index.html` from `catalog.lua` (the master lesson list,
     grouped by phase): published lessons (a `slides/` dir exists) link; the rest
     render as faded "future" placeholders.
  3. Copies each `slides/` directory and the shared `reveal/` assets into `dist/`,
     preserving the `lessons/NN-slug/slides/` URL shape.
- Output is fully static. **No npm, no Node — Lua + vendored reveal.js is the
  entire toolchain.**

## Deployment workflow (Docker + Cloud Run)

Mirrors the sibling courses exactly, renamed for Lua.

### Container image

`deploy/Dockerfile` is two stages:

1. **Build stage** — Alpine with `lua5.4` + `luarocks` + `luafilesystem`
   installed. Copies the repo and runs `build-index` to produce the static
   `dist/`.
2. **Runtime stage** — `nginxinc/nginx-unprivileged:alpine` (Cloud Run requires
   non-root). Copies `dist/` into `/usr/share/nginx/html/`. Uses
   `deploy/nginx.conf.template`, which listens on `$PORT` (default 8080), serves
   assets with `Cache-Control: public, max-age=3600` and HTML with `no-cache`,
   and returns 404 for unknown paths.

The runtime image contains no Lua — only nginx + static files.

### Cloud Run service

- One service (`lua-training-slides`) in `europe-north1`.
- Public, unauthenticated ingress. Min instances 0, max 2. 256 MiB / 1 vCPU.
- `cloudrun.yaml` (Knative-style definition) checked in for reproducibility.

### CI/CD

Two GitHub Actions workflows under `.github/workflows/`:

**`ci.yml`** (push/PR):

- `make bootstrap` (hererocks + pinned rocks; cached).
- `luacheck` over the repo.
- `stylua --check` over the repo.
- `busted` on the tools and every lesson's `solutions/` (the always-green set).
- Exercise specs run separately and are allowed to fail (logged for visibility).
- `make slides-build` — verifies the static site builds and `dist/index.html`
  contains "Lua Training".

**`deploy.yml`** (push to `main`):

- Builds the Docker image.
- Authenticates to GCP via **Workload Identity Federation** (no long-lived keys).
- Pushes the image to Artifact Registry (`lua-training`).
- Deploys to Cloud Run via `gcloud run services replace cloudrun.yaml`, then
  ensures public access.

### One-time setup (`deploy/setup.sh`, documented in `deploy/README.md`)

- Reuses the shared `ristkari-dev` GCP project and `github-actions` WIF pool.
- Idempotently creates: Artifact Registry repo `lua-training`, service account
  `github-deploy-lua`, a repo-scoped OIDC provider `github-lua-training`, role
  bindings (`artifactregistry.writer` + `run.admin` + `iam.serviceAccountUser`),
  and the repo→SA impersonation binding.
- GitHub repo secrets: `GCP_PROJECT_ID`, `GCP_WORKLOAD_IDENTITY_PROVIDER`,
  `GCP_SERVICE_ACCOUNT_EMAIL`. No JSON keys.
- Custom domain `lua.ristkari.dev` via a Cloudflare CNAME → `ghs.googlehosted.com`
  (DNS-only / gray cloud, so Cloud Run's managed TLS works).

### Local parity

- `make slides-docker` builds the same image locally and runs it on
  `localhost:8080`.

## Tooling and scaffolding

### Makefile

The single canonical entry point, self-documenting via `make help`:

| Target | What it does |
|---|---|
| `make help` | Lists all targets |
| `make bootstrap` | `hererocks` + pinned rocks → repo-local `.lua/` |
| `make test` | `busted` on tools + every lesson's `solutions/` (always green) |
| `make test-exercises` | `busted` on `exercises/` — fails by design (the spec) |
| `make test-lesson LESSON=NN-slug` | Both exercises and solutions for one lesson |
| `make lint` | `luacheck` over the repo |
| `make fmt` | `stylua` over the repo |
| `make new-lesson NAME=NN-slug` | Scaffolds a new lesson |
| `make slides-dev LESSON=NN-slug` | Local server for one deck |
| `make slides-build` | Builds the full static `dist/` |
| `make slides-docker` | Builds and runs the deploy image locally on `:8080` |

There is no `typecheck` target — `luacheck` is folded into `make lint`.

### The three tools (written in Lua, dogfooded)

- **`tools/build-index`** (Lua + `luafilesystem`) — `catalog.lua` is the master
  lesson list (the single source of truth for the landing page); the builder
  walks `lessons/*/slides/`, renders `dist/index.html`, and copies decks + shared
  assets into `dist/`. Has busted specs.
- **`tools/slides-dev`** (Lua + `luasocket`) — a tiny static HTTP server for one
  lesson's deck + shared assets, with a path-traversal guard. Has busted specs.
- **`tools/new-lesson`** (Lua + `luafilesystem`) — validates the `NN-kebab`
  format, refuses to overwrite an existing folder, and copies a
  `tools/new-lesson/template/` tree (`README.md`, `slides/index.html`,
  `slides/slides.md`, `exercises/{main.lua, main_spec.lua}`,
  `solutions/{main.lua, main_spec.lua}`) with the lesson name/number/title
  substituted. Has busted specs.

### Linting and formatting

- `luacheck` configured in `.luacheckrc`: Lua 5.4 standard library, the
  globals/unused/shadowing policy, and per-path relaxations for slide demo
  snippets if needed.
- `StyLua` configured in `stylua.toml` (indent, column width) as the only
  formatter.
- `.editorconfig` for whitespace consistency.

### Versioning and dependencies

- Lua version pinned in `scripts/bootstrap` (e.g. `5.4.7`) and matched in CI +
  Dockerfile.
- Reveal.js vendored at the pinned **5.1.0** under `shared/reveal/`; upgrades are
  explicit, reviewable commits.
- Third-party rocks avoided in lessons; the tool rocks (`luafilesystem`,
  `luasocket`) and dev rocks (`busted`, `luacheck`) are pinned in bootstrap.

### Documentation in the repo

- Top-level `README.md` — what the course is, prerequisites (install
  `hererocks`/Lua + `StyLua`), clone + `make bootstrap` + run the first lesson.
- `CONTRIBUTING.md` — adding lessons: the four-file convention, `make
  new-lesson`, slide style, commit conventions.
- `deploy/README.md` — one-time GCP setup.

## Non-goals

- **No LuaJIT-specific track.** 5.4 is the target; LuaJIT/5.1 gets incidental
  callouts only, not its own lessons or toolchain.
- **No single-host track.** The course is host-agnostic; Neovim, LÖVE,
  OpenResty, and Redis appear at most as "going further" examples, not as the
  spine.
- **No student-written C.** The embedding lessons provide and demo a C host; all
  graded work is Lua. A pure-Lua fallback host keeps the test gate C-free.
- **No typed-Lua dialect.** Teal and similar are out of scope; LuaLS annotations
  are taught as documentation, not compiled or enforced.
- **No auto-grading service.** `*_spec.lua` files are the spec; students
  self-verify with `busted`.
- **No npm / no Node toolchain.** Slides build with Lua + vendored static
  reveal.js.
- **No alternative package managers.** LuaRocks (under a `hererocks`-managed
  tree) is the only supported toolchain entry point.

## Open items deferred to implementation planning

- Exact Lua patch version pin (current 5.4.x at implementation time, e.g. 5.4.7).
- Exact pinned versions of `busted`, `luacheck`, `luafilesystem`, `luasocket`,
  and `StyLua`.
- Whether `scripts/bootstrap` is a shell script or a Lua script (default: shell,
  since it must run before Lua is installed).
- Whether `make slides-dev` includes live reload (default: no).
- Confirmation that the `ristkari-dev` GCP project + shared `github-actions` WIF
  pool are reused (default: reuse — same workload, new image, service, and
  subdomain).
- The exact build order of the foundation bootstrap (Plan A): toolchain +
  Makefile + tools + shared reveal + deploy, before any lesson lands.
