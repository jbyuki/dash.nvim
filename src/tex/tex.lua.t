##../dash
@spawn_tex_instance+=
local finish_tex = function(code, signal)
  vim.schedule(function()
    @check_if_output_written
    if output_written then
      -- @close_output_split
      if done then
        done()
      end
    else
      finish()
    end
  end)
end

@look_for_config_json_latex
@if_config_json_latex_read_main
@resize_output_split

MAX_LINES = 100000
handle, err = vim.loop.spawn("cmd",
  {
    stdio = {stdin, stdout, stderr},
    args = {"/c pdflatex -interaction=nonstopmode " .. filename},
    cwd = vim.fn.fnamemodify(filename, ":h")
  }, finish_tex)

@check_if_output_written+=
local output_written = false
for _, line in ipairs(output_lines) do
  if string.match(line, "^Output written on") then
    output_written = true
    break
  end
end 

@close_output_split+=
if execute_win and vim.api.nvim_win_is_valid(execute_win) then
  vim.api.nvim_win_close(execute_win, true)
  execute_win = nil
end

@look_for_config_json_latex+=
local path = vim.fn.expand("%:p")
while true do
	local parent = vim.fn.fnamemodify(path, ":h")

	@find_files_in_parent
	@if_one_file_is_config_json_stop

	if config_path then
		break
	end

	if parent == path then
		break
	end
	path = parent 
end

@find_files_in_parent+=
local files = {}
for file in vim.gsplit(vim.fn.glob(parent .. "/*"), "\n") do
	if vim.fn.isdirectory(file) == 0 then
		table.insert(files, file)
	end
end

@if_one_file_is_config_json_stop+=
for _, file in ipairs(files) do
  if vim.fn.fnamemodify(file, ":t") == "config.json" then
    config_path = file
    break
  end
end

@look_for_config_json_latex-=
local config_path

@if_config_json_latex_read_main+=
if config_path then
	local f = io.open(config_path, "r")
	
  local lines = {}
  while true do
    local line = f:read()
    if not line then
      break
    end
    table.insert(lines, line)
	end

  local content = table.concat(lines, "\n")
  local decoded = vim.json.decode(content)

	if decoded["main"] then
		filename = vim.fn.fnamemodify(config_path, ":h") .. "/" .. decoded["main"]
	end
	@check_if_open_split
end

@resize_output_split+=
if execute_win_height ~= 1 then
	if vim.api.nvim_win_is_valid(execute_win) then
		vim.fn.win_splitmove(execute_win, 0, { vertical = false, rightbelow = true })
		vim.api.nvim_win_set_height(execute_win, 1)
		execute_win_height = 1
	end
end


