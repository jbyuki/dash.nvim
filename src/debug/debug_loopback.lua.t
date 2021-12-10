##../dash
@get_pipe_address_for_current_instance+=
-- the name serverstart() is kind of
-- misleading because it doesn't actually
-- start a server, but only provides
-- the caller with another pipe address
-- to connect to the running instance
local my_address = vim.fn.serverstart()

@send_pipe_address_to_debug_instance+=
-- inspect is used here to escape characters such as \, ", ...
vim.fn.rpcnotify(neovim_conn, 'nvim_exec', [[lua dash_debug_conn = vim.fn.sockconnect("pipe", ]] .. vim.inspect(my_address) .. [[, {rpc = true})]], true)
