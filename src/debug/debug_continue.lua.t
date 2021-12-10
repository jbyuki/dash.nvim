##../dash
@implement+=
function M.continue()
  @send_continue_to_neovim_debug
  @remove_pc_sign
  @start_timer_for_break
end

@send_continue_to_neovim_debug+=
vim.fn.rpcnotify(neovim_conn, "nvim_exec_lua", [[dash_continue = true]], {})
