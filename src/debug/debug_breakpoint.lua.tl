##../dash
@implement+=
function M.toggle_breakpoint()
  @get_current_line_number
  @get_breakpoint_at_current_line
  @toggle_breakpoint_sign_at_current_line
  -- if debug_running then
    -- @send_breakpoint_to_debug_neovim
  -- end
end

function M.clear_breakpoints()
  @clear_all_breakpoint_signs
  -- if debug_running then
    -- @clear_breapoints_in_debug_neovim
  -- end
end

@get_current_line_number+=
local lnum, _  = unpack(vim.api.nvim_win_get_cursor(0))

@send_breakpoint_to_debug_neovim+=
vim.fn.rpcnotify(neovim_conn, 'nvim_exec_lua', "if dash_breakpoint[" .. lnum .. "] then dash_breakpoint[" .. lnum .. "] = nil else dash_breakpoint[" .. lnum .. "] = true end" , {})

@clear_breapoints_in_debug_neovim+=
vim.fn.rpcnotify(neovim_conn, 'nvim_exec_lua', "dash_breakpoint = {}" , {})

@send_all_breakpoints+=
@get_all_breakpoint_in_current_buffer
@clear_breapoints_in_debug_neovim
@send_all_breakpoints_to_neovim_debug

@define_signs+=
vim.fn.sign_define("dashBreakpointDef", { text = "B", texthl = "debugBreakpoint" })

@get_current_line_number+=
local row, _ = unpack(vim.api.nvim_win_get_cursor(0))

@get_breakpoint_at_current_line+=
local bufname = vim.api.nvim_buf_get_name(0)
local signs = vim.fn.sign_getplaced(bufname, {group="dashBreakpoint", lnum=row})

@toggle_breakpoint_sign_at_current_line+=
if #signs[1].signs == 0 then
  vim.fn.sign_place(0, "dashBreakpoint", "dashBreakpointDef", bufname, {lnum = row})
else
  vim.fn.sign_unplace("dashBreakpoint", { buffer = bufname, id = signs[1].signs[1].id })
end

@clear_all_breakpoint_signs+=
vim.fn.sign_unplace("dashBreakpoint", { buffer = bufname })

@get_all_breakpoint_in_current_buffer+=
local bufname = vim.api.nvim_buf_get_name(0)
local signs = vim.fn.sign_getplaced(bufname, {group="dashBreakpoint"})

@send_all_breakpoints_to_neovim_debug+=
for _, sign in ipairs(signs[1].signs) do
  vim.fn.rpcnotify(neovim_conn, 'nvim_exec_lua', "dash_breakpoint[" .. sign.lnum .. "] = true" , {})
end
