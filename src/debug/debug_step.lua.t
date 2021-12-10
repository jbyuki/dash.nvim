##../dash
@send_continue_to_neovim_debug+=
vim.fn.rpcnotify(neovim_conn, "nvim_exec_lua", [[dash_step = nil]], {})

@implement+=
function M.step()
  vim.fn.rpcnotify(neovim_conn, "nvim_exec_lua", [[dash_step = true]], {})
  vim.fn.rpcnotify(neovim_conn, "nvim_exec_lua", [[dash_continue = true]], {})
  @remove_pc_sign
  @start_timer_for_break
end
