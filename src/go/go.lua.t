##../dash
@spawn_go_instance+=
handle, err = vim.loop.spawn("cmd",
	{
		stdio = {stdin, stdout, stderr},
		args = {"/c go run ."},
		cwd = ".",
	}, finish)
