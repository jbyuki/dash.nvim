##../dash
@spawn_nasm_instance+=
handle, err = vim.loop.spawn("nasm",
	{
		stdio = {stdin, stdout, stderr},
    args = { "-felf64", filename },
		cwd = ".",
	}, function(code, signal)
    vim.schedule(function()
      if code == 0 then
        link_program()
      else
        finish(code, signal)
      end
    end)
  end)

@link_nasm_program_on_success+=
function link_program()
  @replace_asm_extension_with_o
  @spawn_ld_to_link_obj_file
end

@replace_asm_extension_with_o+=
local obj_file = vim.fn.fnamemodify(filename, ":r") .. ".o"

@spawn_ld_to_link_obj_file+=
@clear_output_lines
@clear_output_window
@create_pipes
handle, err = vim.loop.spawn("gcc",
  {
    stdio = {stdin, stdout, stderr},
    args = { "-no-pie", obj_file },
    cwd = ".",
  }, function(code, signal)
    vim.schedule(function()
      if code == 0 then
        execute_program()
      else
        finish(code, signal)
      end
    end)
  end)

@if_spawn_error_print
@register_pipe_callback_neovim

@execute_nasm_program_on_success+=
function execute_program()
  @clear_output_lines
  @clear_output_window
  @create_pipes
  handle, err = vim.loop.spawn("./a.out",
    {
      stdio = {stdin, stdout, stderr},
      cwd = ".",
    }, finish)

  @if_spawn_error_print
  @register_pipe_callback_neovim
end
