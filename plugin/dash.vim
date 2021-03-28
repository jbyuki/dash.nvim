" Generated from debug_breakpoint.lua.tl, debug_client.lua.tl, debug_continue.lua.tl, debug_inspect.lua.tl, debug_loopback.lua.tl, debug_ntangle.lua.tl, debug_nvim.lua.tl, debug_pc.lua.tl, debug_server.lua.tl, debug_step.lua.tl, debug_ui_value.lua.tl, debug_wait.lua.tl, execute_buf.lua.tl, grey.lua.tl, init.lua.tl, lua-quickfix.lua.tl, lua-test.lua.tl, lua_visual.lua.tl, python-test.lua.tl, python.lua.tl, resize.lua.tl, test_suite.lua.tl, title.lua.tl, vimscript-quickfix.lua.tl, vimscript-test.lua.tl, vimscript.lua.tl, vs.lua.tl using ntangle.nvim
if exists('g:loaded_dash')
    finish
endif
let g:loaded_dash= 1

command! -nargs=0 -bar DashDebug lua require"dash".debug_buf()

command! -nargs=0 -bar DashRun lua require"dash".execute_buf()


