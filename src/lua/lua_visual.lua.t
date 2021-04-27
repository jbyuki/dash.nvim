##../dash
@spawn_instance_for_neovim_visual+=
local err, pipe_address
if vim.fn.has('win32') then
  pipe_address = [[\\.\pipe\nvim-pipe-23578]]
else
  -- NEEDS TESTING
  pipe_address = vim.fn.tempname()
end

neovim_visual, err = vim.loop.spawn("nvim",
	{
		args = {"--headless", "-u", "NONE", "--listen", pipe_address},
		cwd = ".",
	}, 
  function(code, signal)
end)

@implement+=
function M.try_connect(add)
  for i=1,10 do
    local ok, conn
    ok, conn = pcall(vim.fn.sockconnect, "pipe", add, {rpc=true})
    if ok then
      return conn
    end
    vim.wait(200)
  end
end

@connect_to_neovim_visual+=
neovim_visual_conn = M.try_connect(pipe_address)

@script_variables+=
local neovim_visual_timer

@stop_neovim_visual_timer+=
if neovim_visual_timer then
  neovim_visual_timer:close()
end

@start_waiting_loop+=
if neovim_visual_conn then
  neovim_visual_timer = vim.loop.new_timer()
  neovim_visual_timer:start(0, 200, function()
    vim.schedule(function()
      local succ, output = pcall(vim.fn.rpcrequest, neovim_visual_conn, "nvim_exec_lua", [[return dash_output]], {})
      if not succ then
        neovim_visual_timer:close()
        neovim_visual_timer = nil
        return
      end

      if output then
        succ, err = pcall(vim.api.nvim_buf_set_lines, execute_buf, 0, -1, true, output)
        if not succ then
          neovim_visual_timer:close()
          neovim_visual_timer = nil
          return
        end
      end
    end)
  end)
end

@get_visual_selection+=
local _, start, _, _ = unpack(vim.fn.getpos("'<"))
local _, finish, _, _ = unpack(vim.fn.getpos("'>"))
local lines = vim.api.nvim_buf_get_lines(0, start-1, finish, true)

@send_visual_selection_to_neovim+=
vim.fn.rpcnotify(neovim_visual_conn, "nvim_exec", [[luafile ]] .. fname, false)

@send_custom_print_for_neovim_lua+=
vim.fn.rpcnotify(neovim_visual_conn, "nvim_exec_lua", [[dash_output = {}]], {})
vim.fn.rpcnotify(neovim_visual_conn, "nvim_exec_lua", [[function print(str) table.insert(dash_output, tostring(str)) end]], {})
