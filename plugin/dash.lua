
vim.cmd [[command! -nargs=0 -bar DashDebug lua require"dash".debug_buf()]]

vim.cmd [[command! -nargs=0 -bar DashRun lua require"dash".execute_buf()]]
vim.cmd [[command! -nargs=0 -bar DashConnect lua require"dash".connect(7777)]]
