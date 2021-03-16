##../dash
@save_split_size+=
local execute_win_height = vim.api.nvim_win_get_height(execute_win)

@restore_split_size_if_quickfix_close+=
vim.api.nvim_win_set_height(execute_win, execute_win_height)

@set_window_dimension_fix+=
vim.api.nvim_win_set_option(execute_win, "winfixheight", true)
vim.api.nvim_win_set_option(execute_win, "winfixwidth", true)
