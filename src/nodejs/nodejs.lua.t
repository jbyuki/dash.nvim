##../dash
@spawn_nodejs_instance+=
handle, err = vim.loop.spawn("cmd",
	{
		stdio = {stdin, stdout, stderr},
		args = {"/c node " .. filename},
		cwd = ".",
	}, finish)

@execute_visual_nodejs+=
@write_to_temporary_file
M.execute(fname, ft, true)
