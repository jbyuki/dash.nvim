##dash
@../lua/dash/init.lua=
@script_variables
@add_tests
local M = {}
@implement

return M

@o+=
local a

@implement+=
function M.execute(filename, ft, open_split, done)
  local buf
  @create_split_if_none
  @save_split_size
  @close_quickfix_if_open
  @restore_split_size_if_quickfix_close

  @create_pipes
  @clear_all_highlight

  local finish = function(code, signal) 
		vim.schedule(function()
      @if_no_output_clear_console
      @compare_with_previous_output
      @higlight_differences
      @save_current_output
      if done then
        done()
      end
		end)
  end

  local handle, err
  if ft == "lua" then
    @spawn_neovim_process
  elseif ft == "python" then
    @spawn_python_instance
  elseif ft == "vim" then
    @spawn_neovim_process_for_vimscript
  end
  @if_spawn_error_print
  @register_pipe_callback_neovim
  if handle then
    @clear_output_lines
  end
end

@create_pipes+=
local stdin = vim.loop.new_pipe(false)
local stdout = vim.loop.new_pipe(false)
local stderr = vim.loop.new_pipe(false)

@spawn_neovim_process+=
-- After a lot of sweet and tears, I've found
-- that neovim only outputs to stdout on exit
-- that's why the -c exit is crucial,
-- otherwise nothing is captured.
handle, err = vim.loop.spawn("nvim",
	{
		stdio = {stdin, stdout, stderr},
		args = {"--headless", "-u", "NONE", "-c", "luafile " .. filename, "-c", "exit"},
		cwd = ".",
	}, finish)

@if_spawn_error_print+=
assert(handle, err)

@script_variables+=
local output_lines = {}

@clear_output_lines+=
output_lines = {}

@register_pipe_callback_neovim+=
stdout:read_start(function(err, data)
  vim.schedule(function()
    assert(not err, err)
    if data then
      @append_output_to_buf
    end
  end)
end)

stderr:read_start(function(err, data)
  vim.schedule(function()
    assert(not err, err)
    if data then
      local open_quickfix = false
      @append_output_to_buf
      @parse_error_for_quickfix
      @open_quickfix
    end
  end)
end)

@script_variables+=
local execute_win, execute_buf

@create_split_if_none+=
if not execute_win or not vim.api.nvim_win_is_valid(execute_win) then
  @create_new_window_for_execution
end

if open_split then
  @create_new_buffer_into_window
  @set_previous_content_in_the_meantime
else
  @create_new_scratch_buffer
end
buf = execute_buf

@create_new_window_for_execution+=
local width, height = vim.api.nvim_win_get_width(0), vim.api.nvim_win_get_height(0)
local split
local win_size
local percent = 0.2
if width > 2*height then
  split = "vsp"
  win_size = math.floor(width*percent)
else
  split = "sp"
  win_size = math.floor(height*percent)
end

vim.api.nvim_command("bo " .. win_size .. split)
execute_win = vim.api.nvim_get_current_win()

@create_new_buffer_into_window+=
vim.api.nvim_set_current_win(execute_win)
vim.api.nvim_command("enew")
vim.api.nvim_command("setlocal buftype=nofile bufhidden=wipe nobuflisted nolist noswapfile cursorline nospell")
vim.api.nvim_command("setlocal nonumber")
vim.api.nvim_command("setlocal norelativenumber")
execute_buf = vim.api.nvim_win_get_buf(0)
@rename_output_buffer
vim.api.nvim_command("wincmd p")

@create_new_scratch_buffer+=
execute_buf = vim.api.nvim_create_buf(false, true)

@clear_output_window+=
vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})

@script_variables+=
local MAX_LINES = 10000

@append_output_to_buf+=
if #output_lines == 0 then
  @clear_output_window
end

for line in vim.gsplit(data, "\r*\n") do
  if #output_lines == 0 then
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, { line })
  else
    vim.api.nvim_buf_set_lines(buf, -1, -1, true, { line })
  end
  table.insert(output_lines, line)
  if #output_lines >= MAX_LINES then
    @abort_script
    error("dash.nvim: too many lines. Abort script")
  end
end

@../plugin/dash.vim=
@check_if_plugin_already_loaded
@register_vim_commands

@check_if_plugin_already_loaded+=
if exists('g:loaded_dash')
    finish
endif
let g:loaded_dash= 1

@register_vim_commands+=
command! -nargs=0 -bar DashRun lua require"dash".execute_buf()

@o+=
local a
end

@implement+=
function M.execute_buf()
  @check_if_tangle_file
  local filename, ft
  if tangle then
    @get_root_ntangle
  else
    @get_current_buffer_filename
  end
  @get_current_buffer_filetype
  M.execute(filename, ft, true)
end

@get_current_buffer_filename+=
filename = vim.api.nvim_buf_get_name(0)

@get_current_buffer_filetype+=
ft = vim.api.nvim_buf_get_option(0, "ft")

@script_variables+=
local previous

@compare_with_previous_output+=
local new_lines = {}

if previous then 
  local best = {}
  @find_longest_common_subsequence
  @find_current_lines_which_are_not_in_lcs
else
  @all_lines_are_new
end

@find_longest_common_subsequence+=
local best = {}

local A = previous
local B = output_lines

best[0] = {}
for j=0,#B do
  best[0][j] = {}
end

for i=1,#A do
  best[i] = {}
  best[i][0] = {}
  for j=1,#B do
    if B[j] ~= A[i] then
      if #best[i-1][j] > #best[i][j-1] then
        best[i][j] = best[i-1][j]
      else
        best[i][j] = best[i][j-1]
      end
    else
      best[i][j] = vim.deepcopy(best[i-1][j-1])
      table.insert(best[i][j], j)
    end
  end
end

local lcs = best[#previous][#output_lines]

@find_current_lines_which_are_not_in_lcs+=
local k = 1
for i=1,#output_lines do
  if k <= #lcs and lcs[k] == i then
    k = k + 1
  else
    table.insert(new_lines, i)
  end
end

@all_lines_are_new+=
for i=1,#output_lines do
  table.insert(new_lines, i)
end

@save_current_output+=
previous = output_lines

@script_variables+=
local hl_ns

@clear_all_highlight+=
if hl_ns then
  vim.api.nvim_buf_clear_namespace(buf, hl_ns, 0, -1)
else
  hl_ns = vim.api.nvim_create_namespace("")
end

@higlight_differences+=
for _,lnum in ipairs(new_lines) do
  vim.api.nvim_buf_add_highlight(buf, hl_ns, "Search", lnum-1, 0, -1)
end

@abort_script+=
handle:close()
stdout:read_stop()
stderr:read_stop()

@check_if_tangle_file+=
local name = vim.api.nvim_buf_get_name(0)
local extext = vim.fn.fnamemodify(name, ":e:e")
local tangle = string.match(extext, ".*%.tl")

@get_root_ntangle+=
filename = require"ntangle".getRootFilename()

@if_no_output_clear_console+=
if #output_lines == 0 then
  @clear_output_window
end

@set_previous_content_in_the_meantime+=
if previous then
  vim.api.nvim_buf_set_lines(execute_buf, 0, -1, true, previous)
end
