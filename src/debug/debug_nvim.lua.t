##../dash
@script_variables+=
local neovim_port = 81489
local pipe_address
local neovim_handle

@spawn_neovim_instance_for_debug+=
if vim.fn.has('win32') then
  pipe_address = [[\\.\pipe\nvim-pipe-23493]]
else
  -- NEEDS TESTING
  pipe_address = vim.fn.tempname()
end

local err
neovim_handle, err = vim.loop.spawn("nvim",
	{
		args = {"--headless", "-u", "NONE", "--listen", pipe_address},
		cwd = ".",
	}, function(code, signal)
    vim.schedule(function()
      debug_running = false
    end)
  end
)

if not neovim_handle then
  print(err)
  debug_running = false
else
  debug_running = true
end

@kill_previous_neovim_instance+=
if neovim_handle then
  neovim_handle:kill()
  neovim_handle = nil
end

@kill_neovim_instance_for_debug+=
neovim_handle:kill()
neovim_handle = nil

@connect_to_neovim_debug+=
local err, success
success, neovim_conn = pcall(vim.fn.sockconnect, "pipe", pipe_address, { rpc = true })

@close_connect_to_neovim_debug+=
vim.fn.chanclose(neovim_conn)
