# Lua Training

A Lua programming course delivered as code + per-lesson reveal.js slide decks.
Targets **Lua 5.4** (the PUC-Rio reference). The arc starts at programming-101
and finishes with the language's distinctive endgame: coroutines, performance,
packaging with LuaRocks, and embedding (running Lua inside a host, and
extending Lua from a host).

## Prerequisites

- A C compiler + `make` and the readline dev header (Lua is built from source).
  On macOS: `xcode-select --install`. On Debian/Ubuntu: `sudo apt-get install build-essential libreadline-dev`.
- Python 3 — used only to fetch [`hererocks`](https://github.com/luarocks/hererocks),
  the tool that builds the pinned Lua 5.4 + LuaRocks toolchain under `./.lua/`.
  `make bootstrap` provisions `hererocks` into a local `./.bootstrap-venv/`
  automatically when it is not already on your PATH — no global install needed.
- [`StyLua`](https://github.com/JohnnyMorganz/StyLua) for `make fmt` (`brew install stylua`).

## Quick start

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
