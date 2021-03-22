##../dash
@fill_vars_with_local_variables+=
local stack = 2
local li = 1
while true do
  local ln, lv = debug.getlocal(stack, li)
  li = li + 1
  if not ln then break end

  dash_debug_vars[ln] = lv
end

@set_globals_as_metatable+=
setmetatable(dash_debug_vars, {
  __index = _G
})

@transform_inspect_name_expression+=
local start = string.find(dash_inspect_name, "[.%[]")
if start then
  local rest = string.sub(dash_inspect_name, start)
  local start = string.sub(dash_inspect_name, 1, start-1)
  dash_inspect_name = "return dash_debug_vars['" .. start .. "']" .. rest
else
  dash_inspect_name = "return dash_debug_vars['" .. dash_inspect_name .. "']"
end

@execute_inspect_name_expression+=
local f = loadstring(dash_inspect_name)
if f then
  dash_inspect_result = f()
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

@implement+=
function M.vinspect()
  @get_name_in_visual_selection
  @send_inspect_name_to_neovim_debug
  @wait_for_inspect_result
end

@get_name_in_visual_selection+=
local _, srow, scol, _ = unpack(vim.fn.getpos("'<"))
local _, erow, ecol, _ = unpack(vim.fn.getpos("'>"))

assert(srow == erow, "only single row selection are supported!")

local line = vim.api.nvim_buf_get_lines(0, srow-1, srow, true)[1]
local name = string.sub(line, scol, ecol)
