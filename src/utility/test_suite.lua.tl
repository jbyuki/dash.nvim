##../little-runner
@script_variables+=
local tests = {}

@implement+=
function M.test()
  local results = {}
  for ft, test in pairs(tests) do
    local done = false
    M.execute_lines(vim.split(test.str, "\n"), ft, false, function()
      done = true
    end)
    @wait_for_test_completion
    @compare_output_to_expected
  end

  @show_test_results
end

@wait_for_test_completion+=
-- timeout 5 seconds
local ok = false
for i=1,100 do
  vim.wait(50)
  if done then
    ok = true
    break
  end
end

@compare_output_to_expected+=
if not ok then
  results[ft] = "TIMEOUT"
else
  if vim.deep_equal(previous, test.expected) then
    results[ft] = "OK"
  else
    results[ft] = "FAIL"
  end
end

@show_test_results+=
local result_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_win_set_buf(0, result_buf)
local lines = {}
local text = {}
local padding = 30
for ft,result in pairs(results) do
  local line = ft
  @add_padding_to_line
  line = line .. result
  table.insert(lines, line)
  table.insert(text, result)
end
vim.api.nvim_buf_set_lines(result_buf, 0, -1, true, lines)
local ns_id = vim.api.nvim_create_namespace("")
for i=1,#lines do
  local hl_group
  @decide_highlight_group_depending_on_text
  vim.api.nvim_buf_add_highlight(result_buf, ns_id, hl_group, i-1, padding, -1)
end

@add_padding_to_line+=
local s = string.len(ft)
for i=s+1,padding do
  line = line .. " "
end

@decide_highlight_group_depending_on_text+=
if text[i] == "OK" then
  hl_group = "Search"
elseif text[i] == "TIMEOUT" then
  hl_group = "Substitute"
else
  hl_group = "IncSearch"
end
