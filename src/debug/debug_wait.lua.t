##../dash
@start_timer_for_break+=
local timer = vim.loop.new_timer()
timer:start(0, 200, function()
  if dash_breaked then
    vim.schedule(function()
      @retrieve_current_line_in_debugger
      @retrieve_filename_in_debugger
      @check_if_tangle_file
      if tangle then
        @get_tangle_line_mapping_for_current_file
        @put_sign_for_pc_tangled
      else
        @put_sign_for_pc
      end
      print("Debugger breaked on line " .. cur_lnum .. "!")
    end)
    dash_breaked = false
    timer:close()
  end
end)

@retrieve_current_line_in_debugger+=
local cur_lnum = vim.fn.rpcrequest(neovim_conn, "nvim_exec_lua", [[return dash_current_line]], {})

@retrieve_filename_in_debugger+=
local cur_filename = vim.fn.rpcrequest(neovim_conn, "nvim_exec_lua", [[return dash_return_filename]], {})
