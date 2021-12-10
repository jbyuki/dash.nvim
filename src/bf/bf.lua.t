##../dash
@close_split+=
if execute_win and vim.api.nvim_win_is_valid(execute_win) then
  vim.api.nvim_win_close(execute_win, true)
  execute_win = nil
end

@execute_bf_program+=
@get_buffer_content
@map_buffer_content_to_position
@build_jump_table
@open_state_buffer_split

@attach_keymap_stop

@init_execution_state
timer = vim.loop.new_timer()
timer:start(0, 50, function()
  @fetch_instruction
  @if_none_stop

  @save_previous_dp
  @execute_instruction
  vim.schedule(function()
    @clear_highlights
    @highlight_current_instruction

    @update_state_buffer
  end)
  @increment_instruction
end)

function M.stop_bf()
  @clear_highlights
  @detach_keymap_stop
  @focus_state_window
  @stop_timer
end

@get_buffer_content+=
local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

@map_buffer_content_to_position+=
local program = {}
for i=1,#lines do 
  local line = lines[i]
  for j=1,string.len(line) do
    @create_instruction_if_code
  end
end

@create_instruction_if_code+=
local c = line:sub(j, j)
if c == "+" or c == "-" or c == "[" or c == "]" or c == "<" or c == ">" or c == "." or c == "," then
  table.insert(program, {
    ins = c,
    row = i-1,
    col = j-1,
  })
end

@build_jump_table+=
local stack = {}
for i, c in ipairs(program) do
  if c.ins == "[" then
    table.insert(stack, i)
  elseif c.ins == "]" then
    assert(#stack > 0, "Mismatch ]")
    local j = stack[#stack]
    c.ref = j
    program[j].ref = i
    table.remove(stack)
  end
end

assert(#stack == 0, "Mismatch [")

@script_variables+=
local state_buf, state_win
local parent_width, parent_height
local win_width, win_height

@open_state_buffer_split+=
state_buf = vim.api.nvim_create_buf(false, true)
parent_width = vim.api.nvim_win_get_width(0)
parent_height = vim.api.nvim_win_get_height(0)
win_width = 2
win_height = 2
state_win = vim.api.nvim_open_win(state_buf, false, {
  relative = "win",
  row = parent_height - win_height - 1,
  col = parent_width - win_width - 1,
  width = win_width,
  height = win_height,
  style = "minimal",
})

@init_execution_state+=
local tape = {}
local ip = 1
local dp = 1

@fetch_instruction+=
local c = program[ip]

@if_none_stop+=
if not c then
  timer:close()
  timer = nil
  vim.schedule(function()
    @clear_highlights
    @focus_state_window
  end)
  return
end

@script_variables+=
local ns_hl = vim.api.nvim_create_namespace("")

@clear_highlights+=
vim.api.nvim_buf_clear_namespace(0, ns_hl, 0, -1)

@highlight_current_instruction+=
vim.api.nvim_buf_set_extmark(0, ns_hl, c.row, c.col, {
  hl_group = "IncSearch",
  end_col = c.col+1,
})

function a()
end

@execute_instruction+=
if c.ins == "+" then
  tape[dp] = (tape[dp] or 0)+1
elseif c.ins == "-" then
  tape[dp] = (tape[dp] or 0)-1
elseif c.ins == "<" then
  dp = dp - 1
elseif c.ins == ">" then
  dp = dp + 1
elseif c.ins == "[" then
  if not tape[dp] or tape[dp] == 0 then
    ip = c.ref
  end
elseif c.ins == "]" then
  if tape[dp] and tape[dp] ~= 0 then
    ip = c.ref
  end
elseif c.ins == "." then
  table.insert(output, string.char(tape[dp] or 0))
end

if not tape[dp] then
  tape[dp] = 0
end

@increment_instruction+=
ip = ip+1

@init_execution_state+=
local output = {}

@stop_timer+=
if timer then
  timer:close()
  timer = nil
end

@save_previous_dp+=
local sdp = dp

@update_state_buffer+=
local lines = {}

table.insert(lines, table.concat(tape, " ") or "")

local start = 0
for i=1,sdp-1 do
  start = start + string.len(tostring(tape[i])) + 1
end

local outlines = vim.split(table.concat(output), "\r*\n")
for _, line in ipairs(outlines) do
  table.insert(lines, line)
end

vim.api.nvim_buf_set_lines(state_buf, 0, -1, true, lines)

@resize_state_window

vim.api.nvim_buf_clear_namespace(state_buf, ns_hl2, 0, -1)
local succ = pcall(vim.api.nvim_buf_set_extmark, state_buf, ns_hl2, 0, start, {
  hl_group = "IncSearch",
  end_col = start + string.len(tostring(tape[sdp]))
})

if not succ then
  timer:close()
  return
end


@script_variables+=
local ns_hl2 = vim.api.nvim_create_namespace("")

@attach_keymap_stop+=
vim.api.nvim_buf_set_keymap(0, "n", "q", [[<cmd>lua require"dash".stop_bf()<CR>]], { noremap = true })
print("Press 'q' to stop.")

@detach_keymap_stop+=
vim.api.nvim_buf_del_keymap(0, "n", "q")

@focus_state_window+=
vim.api.nvim_set_current_win(state_win)

@resize_state_window+=
local max_width = 0
for _, line in ipairs(lines) do
  max_width = math.max(string.len(line), max_width)
end

if max_width > win_width then
  win_width = max_width
  vim.api.nvim_win_set_config(state_win, {
    relative = "win",
    row = parent_height - win_height - 1,
    col = parent_width - win_width - 1,
    width = win_width,
    height = win_height,
  })
end

if #lines > win_height then
  win_height = #lines
  vim.api.nvim_win_set_config(state_win, {
    relative = "win",
    row = parent_height - win_height - 1,
    col = parent_width - win_width - 1,
    width = win_width,
    height = win_height,
  })
end
