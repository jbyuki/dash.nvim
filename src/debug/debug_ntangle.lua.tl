##../dash
@get_tangle_line_mapping_for_current_file+=
local tangled = require"ntangle".get_location_list()
local mapping = {}
for lnum, line in ipairs(tangled) do
  local prefix, l = unpack(line)
  if l.lnum then
    mapping[l.lnum] = mapping[l.lnum] or {}
    table.insert(mapping[l.lnum], lnum)
  end
end

@send_all_breakpoints_to_neovim_debug_tangled+=
for _, sign in ipairs(signs[1].signs) do
  local lnums = mapping[sign.lnum]
  for _, lnum in ipairs(lnums) do
    vim.fn.rpcnotify(neovim_conn, 'nvim_exec_lua', "dash_breakpoint[" .. lnum .. "] = true" , {})
  end
end

@put_sign_for_pc_tangled+=
local bufname = vim.api.nvim_buf_get_name(0)
local prefix, l = unpack(tangled[cur_lnum])
signPC = vim.fn.sign_place(0, "dashPC", "dashPCDef", bufname, {lnum = l.lnum})

@send_breakpoint_to_debug_neovim_tangled+=
local lnums = mapping[lnum]
for _, lnum in ipairs(lnums) do
  @send_breakpoint_to_debug_neovim
end
