##../dash
@spawn_fennel_instance+=
handle, err = vim.loop.spawn("cmd",
	{
		stdio = {stdin, stdout, stderr},
		args = {"/c fennel " .. filename},
		cwd = ".",
	}, finish)

@execute_visual_fennel+=
@write_to_temporary_file
M.execute(fname, ft, true)
