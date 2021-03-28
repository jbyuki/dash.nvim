##../dash
@parse_errors_cpp+=
local error_lines, warning_lines = {}, {}
for _, line in ipairs(output_lines) do
  if (string.find(line, ": error") or string.find(line, ": fatal error")) then
    if string.find(line, "LNK") then
      @parse_linker_error
    elseif not string.find(line, "^ ") then
      local fn,lnum,error_str = string.match(line, "^(.+)%((%d+),%d+%):[^:]+: (.+) %[")
      if fn and lnum and error_str then
        table.insert(error_lines, {fn, lnum, error_str})
      end
    end
  elseif string.find(line, ": warning") and not string.find(line, "^ ") then
    local fn,lnum,warning_str = string.match(line, "^(.+)%((%d+),%d+%):[^:]+: (.+) %[")
    if fn and lnum and warning_str then
      table.insert(warning_lines, {fn, lnum, warning_str})
    end
  elseif string.find(line, "Warning%(s%)") then
    num_warnings = string.match(line, "(%d+)")
  elseif string.find(line, "Error%(s%)") then
    num_errors = string.match(line, "(%d+)")
  end
end

@put_errors_in_quickfix_cpp+=
local qflist = {}
for _, line in ipairs(error_lines) do
  table.insert(qflist, {
    filename = line[1],
    lnum = line[2],
    text = line[3],
    type = "E",
  })
end

for _, line in ipairs(warning_lines) do
  table.insert(qflist, {
    filename = line[1],
    lnum = line[2],
    text = line[3],
    type = "W",
  })
end

vim.fn.setqflist(qflist)

@parse_linker_error+=
local fn,error_str = string.match(line, "^%s*(.+):.+: (.+) %[")
if fn and error_str then
  table.insert(error_lines, {fn, -1, error_str})
end
