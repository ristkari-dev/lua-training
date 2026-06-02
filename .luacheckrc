-- luacheck configuration for lua-training.
std = "lua54"

-- The standalone interpreter provides `arg`; tools read it.
read_globals = { "arg" }

-- busted spec files use describe/it/assert/before_each/... globals.
files["**/*_spec.lua"] = {
  std = "+busted",
}
