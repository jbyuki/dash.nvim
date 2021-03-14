" Generated from init.lua.tl, python.lua.tl, quickfix.lua.tl, resize.lua.tl, vimscript.lua.tl using ntangle.nvim
if exists('g:loaded_little_runner')
    finish
endif
let g:loaded_little_runner= 1

command! -nargs=0 -bar LittleRun lua require"little-runner".execute_buf()


