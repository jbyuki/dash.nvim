##../dash
@execute_cmake_build+=
local execute_program_bat
@execute_cmake
@execute_exe_if_exists_build_bat

@execute_cmake+=
handle, err = vim.loop.spawn("cmake",
	{
		stdio = {stdin, stdout, stderr},
		args = {"--build", "build" },
		cwd = ".",
	}, function(code, signal)
    vim.schedule(function()
      @find_target_name_in_cmake_output
      local exe_file = target_name and vim.fn.glob("build/" .. target_name)
      if code == 0 and exe_file and exe_file ~= "" then

        execute_program_bat(exe_file)
      else
        finish(code, signal)
      end
    end)
  end)


@find_target_name_in_cmake_output+=
local target_name
for i=1,#output_lines do
  _, _, target_name = output_lines[i]:find("Built target (.*)")
  if target_name then
    break
  end
end
