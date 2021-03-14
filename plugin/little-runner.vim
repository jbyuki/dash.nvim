" Generated from execute_buf.lua.tl, init.lua.tl, lua-quickfix.lua.tl, lua-test.lua.tl, python-test.lua.tl, python.lua.tl, test_suite.lua.tl, vimscript-quickfix.lua.tl, vimscript-test.lua.tl, vimscript.lua.tl using ntangle.nvim
if exists('g:loaded_little_runner')
    finish
endif
let g:loaded_little_runner= 1

command! -nargs=0 -bar LittleRun lua require"little-runner".execute_buf()


