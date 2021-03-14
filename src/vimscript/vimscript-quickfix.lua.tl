##../little-runner
@parse_error_for_quickfix+=
if ft == "vim" then
  local filename
  local in_error = false
  local lnum
  local errors = {}
  for line in vim.gsplit(data, "\r*\n") do
    if string.match(line, "^Error detected while processing") then
      @extract_vim_filename_where_error_is
      in_error = true
    elseif in_error and string.match(line, "^line") then
      @extract_line_number_where_error_is_vimscript
    elseif in_error and string.match(line, "^E%d+: ") then
      @extract_error_text_vimscript
      @add_error_entry_in_quickfix_vimscript
    end
  end

  @set_vimscript_error_in_quickfix
end

@extract_vim_filename_where_error_is+=
filename = string.match(line, "^Error detected while processing (.+):")

@extract_line_number_where_error_is_vimscript+=
lnum = string.match(line, "^line (%d+)")

@extract_error_text_vimscript+=
local errnum, errmsg = string.match(line, "^E(%d+): (.+)")

@add_error_entry_in_quickfix_vimscript+=
table.insert(errors, {
  filename = filename,
  lnum = lnum,
  nr = errnum,
  text = errmsg,
  type = 'E',
})

@set_vimscript_error_in_quickfix+=
vim.fn.setqflist(errors)
if #errors > 0 then
  open_quickfix = true
end
