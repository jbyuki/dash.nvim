
vim.cmd [[command! -nargs=0 -bar DashDebug lua require"dash".debug_buf()]]

vim.cmd [[command! -nargs=0 -bar DashRun lua require"dash".execute_buf()]]
vim.cmd [[command! -nargs=0 -bar DashConnect lua require"dash".connect(7777)]]
vim.cmd [[command! -nargs=0 -bar DashStop lua require"dash".stop()]]

vim.api.nvim_create_user_command("DashNTangleV2", function() require"dash".execute_lua_ntangle_visual_v2() end, { range = true })
vim.api.nvim_create_user_command("DashStopKernel", function() require"dash".stop_nvim_kernel() end, {})
