##dash
@check_if_tangle_v2_file+=
local name = vim.api.nvim_buf_get_name(0)
local extext = vim.fn.fnamemodify(name, ":e:e")
local tangle_v2 = string.match(extext, ".*%.t2$")

@get_root_ntangle_v2_under_cursor+=
local found, ntangle_inc = pcall(require, "ntangle-inc")
assert(found, "ntangle-inc is required")

@lookup_root_under_cursor_ntangle_v2
@lookup_filetype_for_mirror_buffer

@lookup_root_under_cursor_ntangle_v2+=
local buf = vim.api.nvim_get_current_buf()
local row, col = unpack(vim.api.nvim_win_get_cursor(0))
local nt_infos = ntangle_inc.TtoNT(buf, row-1)

for _, nt_info in ipairs(nt_infos) do
	local hl = nt_info[1]
	local root_section = nt_info[2]
	local line = nt_info[3]
  buf = ntangle_inc.root_to_mirror_buf[root_section]
	local hl_path = ntangle_inc.hl_to_hl_path[hl]

	local parent_path = hl_path
	if root_section.name:find("/") or root_section.name:find("\\") then
		filename = vim.fs.joinpath(parent_path, root_section.name)
	else
		filename = vim.fs.joinpath(parent_path, ntangle_inc.ntangle_folder, root_section.name)
	end
	break
end

@lookup_filetype_for_mirror_buffer+=
ft = vim.api.nvim_buf_get_option(buf, "ft")
