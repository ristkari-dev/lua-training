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
