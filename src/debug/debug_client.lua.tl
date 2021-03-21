##../dash
@script_variables+=
local client_code_fn
local client_code = [[ 
@define_debug_hooks
]]

@write_debug_client_code_to_temporary_file+=
if not client_code_fn then
  client_code_fn = vim.fn.tempname()
  -- print("temp file " .. client_code_fn)
  local f = io.open(client_code_fn, "w")
  for line in vim.gsplit(client_code, "\r*\n") do
    f:write(line .. "\n")
  end
  f:close()
end

@run_debug_client_in_neovim_instance+=
vim.fn.rpcnotify(neovim_conn, "nvim_exec", "luafile " .. client_code_fn, false)
vim.wait(200)

@execute_lua_in_neovim_for_debug+=
vim.fn.rpcnotify(neovim_conn, "nvim_exec", "luafile " .. filename, false)

@define_debug_hooks+=
dash_current_line = nil

function dash_every_line(event, lnum)
  dash_current_line = lnum
  if dash_breakpoint[lnum] or dash_step then
    dash_continue = false
    @send_to_host_that_breaked
    @wait_for_continue
  end
end

@setup_debug_hook+=
vim.fn.rpcnotify(neovim_conn, "nvim_exec_lua", [[debug.sethook(dash_every_line, "l", 0)]], {})

@wait_for_continue+=
while not dash_continue do
  if dash_inspect_name then
    @check_if_inspect_is_local_variable
    @check_if_inspect_is_global_variable
    dash_inspect_result_done = true
    dash_inspect_name = nil
  end
  vim.wait(200)
end

@send_to_host_that_breaked+=
vim.fn.rpcnotify(dash_debug_conn, "nvim_exec_lua", "dash_breaked = true", {})

@script_variables+=
dash_breaked = false
