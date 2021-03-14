##../little-runner
@spawn_python_instance+=
handle, err = vim.loop.spawn("python",
	{
		stdio = {stdin, stdout, stderr},
		args = {filename},
		cwd = ".",
	}, finish)
