" Generated from execute_buf.lua.tl, init.lua.tl, lua-quickfix.lua.tl, lua-test.lua.tl, python-test.lua.tl, python.lua.tl, resize.lua.tl, test_suite.lua.tl, title.lua.tl, vimscript-quickfix.lua.tl, vimscript-test.lua.tl, vimscript.lua.tl using ntangle.nvim
if exists('g:loaded_dash')
    finish
endif
let g:loaded_dash= 1

command! -nargs=0 -bar DashRun lua require"dash".execute_buf()


