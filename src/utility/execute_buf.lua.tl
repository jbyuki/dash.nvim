##../dash
@implement+=
function M.execute_lines(lines, ft, show_pane, done)
  @write_to_temporary_file
  local augmented = function()
    @delete_temporary_file
    if done then
      done()
    end
  end
  M.execute(fname, ft, show_pane, augmented)
end

@write_to_temporary_file+=
local fname = vim.fn.tempname()
local f = io.open(fname, "w")
for _, line in ipairs(lines) do
  f:write(line .. "\n")
end
f:close()

@delete_temporary_file+=
os.remove(fname)
