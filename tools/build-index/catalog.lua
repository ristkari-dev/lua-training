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
