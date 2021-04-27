##../dash
@fill_vars_with_local_variables+=
local stack = 2
local stack_valid = true
while stack_valid do
  local li = 1
  while true do
    local lv, lv
    stack_valid, ln, lv = pcall(debug.getlocal, stack, li)
    if not stack_valid then
      break
    end
    li = li + 1
    if not ln then break end

    dash_debug_vars[ln] = lv
  end
  stack = stack + 1
end

@set_globals_as_metatable+=
setmetatable(dash_debug_vars, {
  __index = _G
})

@transform_inspect_name_expression+=
local str = dash_inspect_name:gsub('%a[a-zA-Z0-9_]*', 'dash_debug_vars["%0"]')
str = str:gsub('%.dash_debug_vars%["(.-)"%]', '.%1')
dash_inspect_name = "return " .. str

@execute_inspect_name_expression+=
local f = loadstring(dash_inspect_name)
if f then
  local ret
  ret, dash_inspect_result = pcall(f)
  if not ret then
    @parse_error_message_debug
  end
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

@parse_error_message_debug+=
dash_inspect_result = string.match(dash_inspect_result, ".*:.*: (.*)")
