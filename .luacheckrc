-- luacheck configuration for lua-training.
std = "lua54"

-- Exercise stubs intentionally leave function arguments unused
-- (e.g. greet(name) that just errors), so don't warn on unused arguments.
unused_args = false

-- Long data-table rows (catalog.lua LESSONS) are allowed; do not enforce line length.
max_line_length = false

-- The standalone interpreter provides `arg`; tools read it.
read_globals = { "arg" }

-- busted spec files use describe/it/assert/before_each/... globals.
files["**/*_spec.lua"] = {
  std = "+busted",
}
