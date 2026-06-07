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
