##../dash
@try_find_build_bat+=
local fn = vim.api.nvim_buf_get_name(0)
fn = vim.fn.fnamemodify(fn, ":p")
local pardir = vim.fn.fnamemodify(fn, ":h")
local buildbat = vim.fn.glob(pardir .. "/build.bat") ~= ""

@execute_build_bat+=
handle, err = vim.loop.spawn("cmd",
	{
		stdio = {stdin, stdout, stderr},
		args = {"/k", pardir .. "/build.bat" },
		cwd = ".",
	}, function(code, signal)
    vim.schedule(function()
      local exe_file = vim.fn.glob(pardir .. "/bin/*.exe")
      if code == 0 and exe_file ~= "" then

        execute_program_bat(exe_file)
      else
        finish(code, signal)
      end
    end)
  end)

@execute_exe_if_exists_build_bat+=
function execute_program_bat(exe_file)
  @clear_output_lines
  @clear_output_window
  @create_pipes
  handle, err = vim.loop.spawn(exe_file,
    {
      stdio = {stdin, stdout, stderr},
      cwd = ".",
    }, finish)

  @if_spawn_error_print
  @register_pipe_callback_neovim
end
