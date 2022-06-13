##../dash
@execute_verilator+=
local args = { "--cc", filename, "--assert", "--debug-emitv", "--dump-tree" }

local verilator_root = vim.loop.os_getenv("VERILATOR_ROOT")
assert(verilator_root, "VERILATOR_ROOT not set")

handle, err = vim.loop.spawn(verilator_root .. "/bin/verilator",
  {
    stdio = {stdin, stdout, stderr},
    args = args,
    cwd = ".",
  }, finish)
