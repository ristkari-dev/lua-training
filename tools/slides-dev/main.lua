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
