##../dash
@implement+=
function M.debug_buf()
  @check_if_tangle_file
  local filename, ft
  if tangle then
    @get_root_ntangle
  else
    @get_current_buffer_filename
  end
  @get_current_buffer_filetype
  M.debug(filename, ft)
end

@script_variables+=
local neovim_conn

@implement+=
function M.debug(filename, ft)
  if ft == "lua" then
    @kill_previous_neovim_instance

    @spawn_neovim_instance_for_debug

    neovim_conn = nil
    for i=1,10 do
      @connect_to_neovim_debug
      if success then
        break
      end
      vim.wait(200)
    end

    assert(neovim_conn, "Could not establish connection with debug instance")

    @get_pipe_address_for_current_instance
    @send_pipe_address_to_debug_instance

    @write_debug_client_code_to_temporary_file
    @run_debug_client_in_neovim_instance

    @send_all_breakpoints
    @send_filename_for_source

    @setup_debug_hook
    @execute_lua_in_neovim_for_debug

    @start_timer_for_break

    -- @close_connect_to_neovim_debug
    -- @kill_neovim_instance_for_debug
  end
end
