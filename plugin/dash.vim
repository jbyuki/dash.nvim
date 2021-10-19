" Generated using ntangle.nvim
if exists('g:loaded_dash')
    finish
endif
let g:loaded_dash= 1

command! -nargs=0 -bar DashDebug lua require"dash".debug_buf()

command! -nargs=0 -bar DashRun lua require"dash".execute_buf()


