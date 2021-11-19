##../dash
@spawn_tex_instance+=
handle, err = vim.loop.spawn("cmd",
  {
    stdio = {stdin, stdout, stderr},
    args = {"/c pdflatex " .. filename},
    cwd = ".",
  }, finish)
