##../dash
@check_if_inspect_is_local_variable+=
local stack = 2
while dash_inspect_name do
  local li = 1
  while true do
    local ln, lv = debug.getlocal(stack, li)
    li = li + 1
    if not ln then
      break
    end

    if ln == dash_inspect_name then
      dash_inspect_result = lv
      dash_inspect_name = nil
      break
    end
  end

  if li == 1 then
    break
  end
  stack = stack + 1
  break
end

@check_if_inspect_is_global_variable+=
if _G[dash_inspect_name] then
  dash_inspect_result = _G[dash_inspect_name]
end

@implement+=
function M.inspect()
  @get_variable_name_to_inspect_under_cursor
  @send_inspect_name_to_neovim_debug
  @wait_for_inspect_result
end

@send_inspect_name_to_neovim_debug+=
vim.fn.rpcnotify(neovim_conn, 'nvim_exec_lua', "dash_inspect_result_done = false", {})
vim.fn.rpcnotify(neovim_conn, 'nvim_exec_lua', "dash_inspect_result = nil", {})
vim.fn.rpcnotify(neovim_conn, 'nvim_exec_lua', "dash_inspect_name = " .. vim.inspect(name), {})

@wait_for_inspect_result+=
local timer = vim.loop.new_timer()
timer:start(0, 200, function()
  vim.schedule(function()
    @retrieve_inspect_result_done
    if dash_inspect_result_done then
      @retrieve_inspect_result

      @create_buffer_inspect
      @put_inspect_result_in_inspect_buffer
      @create_float_window_inspect
      @register_close_float_window_inspect
      timer:close()
    end
  end)
end)

@retrieve_inspect_result_done+=
local dash_inspect_result_done = vim.fn.rpcrequest(neovim_conn, 'nvim_exec_lua', [[return dash_inspect_result_done]], {})

@retrieve_inspect_result+=
local dash_inspect_result = vim.fn.rpcrequest(neovim_conn, 'nvim_exec_lua', [[return dash_inspect_result]], {})

@get_variable_name_to_inspect_under_cursor+=
local name = vim.fn.expand("<cword>")
