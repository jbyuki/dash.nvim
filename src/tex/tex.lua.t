##../dash
@spawn_tex_instance+=

MAX_LINES = 100000
handle, err = vim.loop.spawn("cmd",
  {
    stdio = {stdin, stdout, stderr},
    args = {"/c pdflatex " .. filename},
    cwd = ".",
  }, finish)
