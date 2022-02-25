##../dash
@execute_bash_script+=
filename = vim.fn.fnamemodify(filename, ":.")
handle, err = vim.loop.spawn("./" .. filename,
	{
		stdio = {stdin, stdout, stderr},
		args = {},
		cwd = ".",
	}, finish)
