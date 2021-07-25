##../dash
@spawn_fennel_instance+=
handle, err = vim.loop.spawn("fennel",
	{
		stdio = {stdin, stdout, stderr},
		args = {filename},
		cwd = ".",
	}, finish)

@execute_visual_fennel+=
@write_to_temporary_file
M.execute(fname, ft, true)
