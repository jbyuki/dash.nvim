##dash
@implement+=
function M.connect(port)
  @disconnect_any_previous_connection
  @connect_to_socket
end

@script_variables+=
local remote

@connect_to_socket+=
remote = vim.fn.sockconnect("tcp", ("localhost:%d"):format(port), { rpc = true })

@disconnect_any_previous_connection+=
if remote then
  vim.fn.chanclose(remote)
  remote = nil
end

@implement+=
function M.get_output()
  return output_lines
end

@script_variables+=
local finished = true

@set_as_not_finished+=
finished = false

@set_as_finished+=
finished = true

@implement+=
function M.has_finished()
  return finished
end

@implement+=
function M.execute_remote(filename, ft, open_split)
  local buf
  @close_split_if_different_tabpage
  @create_split_if_none
  @save_split_size

  @grey_namespace

  @restore_split_size_if_quickfix_close

  @clear_all_highlight
  @put_grey_highlight_over

  @execute_on_remote
  @register_looping_request_to_remote
end

@execute_on_remote+=
-- give relative path to avoid
-- inter-OS path troubles
-- assumption: both the client and server are
-- runing in the same directory
filename = vim.fn.fnamemodify(filename, ":.")
vim.fn.rpcnotify(remote, "nvim_exec_lua", [[require"dash".execute(...)]], { filename, ft, true })

@register_looping_request_to_remote+=
local timer = vim.loop.new_timer()
timer:start(100, 200, vim.schedule_wrap(function()
  @update_output_lines
  @check_if_execution_finished
end))

@check_if_execution_finished+=
local finished = vim.fn.rpcrequest(remote, "nvim_exec_lua", [[return require"dash".has_finished()]], {})
if finished then
  @clear_grey_highlight
  timer:close()
end

@update_output_lines+=
local remote_lines = vim.fn.rpcrequest(remote, "nvim_exec_lua", [[return require"dash".get_output()]], {})
vim.api.nvim_buf_set_lines(buf, 0, -1, true, remote_lines)
