##../dash
@implement+=
function M.execute_lua_ntangle_v2()
	local buf
	local open_split = true
	@close_split_if_different_tabpage

	@create_split_if_none_and_neovim_instance

	@get_code_content_at_current_section_v2

  @clear_all_grey_highlight
  @put_grey_highlight_over

	@execute_lua_code_in_remote
end

@get_code_content_at_current_section_v2+=
local found, ntangle_inc = pcall(require, "ntangle-inc")
assert(found)

local codebuf = vim.api.nvim_get_current_buf()
local row, col = unpack(vim.api.nvim_win_get_cursor(0))

local lnum = row-1
@get_hl_elem_at_lnum
if hl_elem and hl_elem.part then
	hl_elem = hl_elem.part
end
@get_lines_at_hl_elem

local ntangle_code = table.concat(lines, "\n")

@get_hl_elem_at_lnum+=
local hl_elem = ntangle_inc.Tto_hl_elem(codebuf, lnum)

@get_lines_at_hl_elem+=
local lines = {}
if hl_elem then
	local Tangle = require"vim.tangle"
	local ll = Tangle.get_ll_from_buf(codebuf)
	assert(ll)
	local hl = Tangle.get_hl_from_ll(ll)
	assert(hl)

	lines = hl:getlines_all(hl_elem, lines)
end

@script_variables+=
local grey_id

@implement+=
function M.execute_lua_ntangle_visual_v2()
	local buf
	local open_split = true
	@close_split_if_different_tabpage

	@create_split_if_none_and_neovim_instance

  @get_code_content_at_current_section_visual_v2


  @clear_all_grey_highlight
  @put_grey_highlight_over

	@execute_lua_code_in_remote
end

@get_code_content_at_current_section_visual_v2+=
local _,slnum,_,_ = unpack(vim.fn.getpos("'<"))
local _,elnum,_,_ = unpack(vim.fn.getpos("'>"))
local codebuf = vim.api.nvim_get_current_buf()

local found, ntangle_inc = pcall(require, "ntangle-inc")
assert(found)

local all_lines = {}
for lnum=slnum-1,elnum-1 do
	@get_hl_elem_at_lnum
	@get_lines_at_hl_elem
	@append_lines_to_all_lines
end

local ntangle_code = table.concat(all_lines, "\n")

@append_lines_to_all_lines+=
for _, line in ipairs(lines) do
	table.insert(all_lines, line)
end

@script_variables+=
local neovim_chan, neovim_proc

@start_neovim_kernel+=
local tcp_port
@get_free_tcp_address
neovim_proc = vim.system({vim.v.progpath, "--headless", "--listen", ("127.0.0.1:%d"):format(tcp_port)}, { 
	@define_neovim_proc_callbacks
})

local connect_success = false
for i=1,100 do
	@try_connection_with_proc
	vim.wait(30)
end

assert(connect_success)

@clear_output_lines
@clear_output_window

@append_neovim_version_header

@get_free_tcp_address+=
local temp_tcp = vim.loop.new_tcp()
temp_tcp:bind("127.0.0.1", 0)
local tcp_port = temp_tcp:getsockname().port
temp_tcp:close_reset()

@try_connection_with_proc+=
success, neovim_chan = pcall(vim.fn.sockconnect, "tcp", ("127.0.0.1:%d"):format(tcp_port), { rpc = true })
if success then
	connect_success = true
	break
end

@define_neovim_proc_callbacks+=
stdout = vim.schedule_wrap(function(err, data)
	assert(not err)
	if data then
		@append_data_to_output_lines
		vim.api.nvim_buf_set_lines(buf, -1, -1, true, new_lines)

		@scroll_buffer_to_last_line
	end
end),

stderr = vim.schedule_wrap(function(err, data)
	assert(not err)
	if data then
		local new_lines = {}
		@append_data_to_output_lines
		vim.api.nvim_buf_set_lines(buf, -1, -1, true, new_lines)
		@scroll_buffer_to_last_line
	end
end)

@script_variables+=
local lua_temp_file

@execute_lua_code_in_remote+=
local syntax_error = false
@check_syntax_error
if not syntax_error then
	@wrap_code_into_error_handler
	@if_no_temp_file_generate_name
	@write_code_to_temp_file
	vim.fn.rpcnotify(neovim_chan, "nvim_exec", "luafile " .. lua_temp_file, false)
end

@if_no_temp_file_generate_name+=
if not lua_temp_file then
	lua_temp_file = vim.fn.tempname()
end

@write_code_to_temp_file+=
local f = io.open(lua_temp_file, "w")
f:write(ntangle_code)
f:close()

@append_data_to_output_lines+=
new_lines = vim.split(data, "\r*\n")

@append_neovim_version_header+=
local _, info = unpack(vim.fn.rpcrequest(neovim_chan, "nvim_get_api_info"))
local header = ("NVIM v%d.%d.%d-%s"):format(info.version.major, info.version.minor, info.version.patch, info.version.build)
vim.api.nvim_buf_set_lines(buf, 0, -1, true, {header, ""})

@create_split_if_none_and_neovim_instance+=
if not execute_win or not vim.api.nvim_win_is_valid(execute_win) then
	@create_grey_namespace
  @register_close_callback_if_first_time
  @create_new_window_for_execution
  @create_new_buffer_into_window

	buf = execute_buf

	@stop_neovim_kernel_if_running
	@start_neovim_kernel
end

buf = execute_buf

@stop_neovim_kernel_if_running+=
if neovim_proc then
	neovim_proc:kill()
	neovim_chan = nil
	neovim_proc = nil
end

@clear_all_grey_highlight+=
vim.api.nvim_buf_clear_namespace(buf, grey_id, 0, -1)

@create_grey_namespace+=
grey_id = vim.api.nvim_create_namespace("")

@check_syntax_error+=
local good, err = loadstring(ntangle_code)
if not good then
	vim.api.nvim_buf_set_lines(buf, -1, -1, true, { err })
	syntax_error = true
end

@wrap_code_into_error_handler+=
ntangle_code = ([[
	local succ, osv = pcall(require, "osv")
	if not succ or not osv.is_attached() then
		local success, err = pcall(function()
			%s
		end)
		if not success and err then
			io.write(err)
		end
	else
			%s
	end
]]):format(ntangle_code, ntangle_code)
