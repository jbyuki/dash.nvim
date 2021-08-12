##../dash
@parse_output_gradle+=
local qflist = {} 
for _, line in ipairs(output_lines) do
  if line:match("^%s*ERROR") then
    @parse_gradle_error_line
    @put_gradle_error_into_qflist
  elseif line:match("^%s*e:") then
    @parse_gradle_e_line
    @put_gradle_error_into_qflist
  end
end

@parse_gradle_error_line+=
local filename, line_number, err_text = line:match("^%s*ERROR:([^.]+.%w+):(%d+):(.*)")

@put_gradle_error_into_qflist+=
table.insert(qflist, {
  filename = filename,
  lnum = line_number,
  text = err_text,
  type = "E",
})

@put_gradle_error_into_qflist+=
vim.fn.setqflist(qflist)

@parse_gradle_e_line+=
local filename, line_number, err_text = line:match("^%s*e:%s*([^.]+.%w+):%s%((%d+),%s*%d+%):(.*)")
