##../dash
@define_signs+=
vim.fn.sign_define("dashPCDef", { text = "PC", texthl = "debugPC", linehl = "debugPC" })

@put_sign_for_pc+=
local bufname = vim.api.nvim_buf_get_name(0)
signPC = vim.fn.sign_place(0, "dashPC", "dashPCDef", bufname, {lnum = cur_lnum})

@script_variables+=
local signPC

@remove_pc_sign+=
if signPC then
  local bufname = vim.api.nvim_buf_get_name(0)
  vim.fn.sign_unplace("dashPC", { buffer = bufname })
  signPC = nil
end
