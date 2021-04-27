##../dash
@spawn_python_instance+=
handle, err = vim.loop.spawn("python",
	{
		stdio = {stdin, stdout, stderr},
		args = {filename},
		cwd = ".",
	}, finish)

@execute_visual_python+=
@write_to_temporary_file
M.execute(fname, ft, true)
