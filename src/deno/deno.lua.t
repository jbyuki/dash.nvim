##../dash
@spawn_deno_instance+=
handle, err = vim.loop.spawn("cmd",
	{
		stdio = {stdin, stdout, stderr},
		args = {"/c deno " .. filename},
		cwd = ".",
	}, finish)

@execute_visual_deno+=
@write_to_temporary_file
M.execute(fname, ft, true)
