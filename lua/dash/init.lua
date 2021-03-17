-- Generated from grey.lua.tl, init.lua.tl, resize.lua.tl using ntangle.nvim
local output_lines = {}

local execute_win, execute_buf

local MAX_LINES = 10000

local previous

local hl_ns

local M = {}
function M.execute(filename, ft, open_split, done)
  local buf
  if not execute_win or not vim.api.nvim_win_is_valid(execute_win) then
    local width, height = vim.api.nvim_win_get_width(0), vim.api.nvim_win_get_height(0)
    local split
    local win_size
    local percent = 0.2
    if width > 2*height then
      split = "vsp"
      win_size = math.floor(width*percent)
    else
      split = "sp"
      win_size = math.floor(height*percent)
    end
    
    vim.api.nvim_command("bo " .. win_size .. split)
    execute_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_option(execute_win, "winfixheight", true)
    vim.api.nvim_win_set_option(execute_win, "winfixwidth", true)
    
  end
  
  if open_split then
    vim.api.nvim_set_current_win(execute_win)
    vim.api.nvim_command("enew")
    vim.api.nvim_command("setlocal buftype=nofile bufhidden=wipe nobuflisted nolist noswapfile cursorline nospell")
    vim.api.nvim_command("setlocal nonumber")
    vim.api.nvim_command("setlocal norelativenumber")
    execute_buf = vim.api.nvim_win_get_buf(0)
    vim.api.nvim_command("wincmd p")
    
    if previous then
      vim.api.nvim_buf_set_lines(execute_buf, 0, -1, true, previous)
    end
  else
    execute_buf = vim.api.nvim_create_buf(false, true)
    
  end
  buf = execute_buf
  
  local execute_win_height = vim.api.nvim_win_get_height(execute_win)
  
  vim.api.nvim_win_set_height(execute_win, execute_win_height)
  

  local stdin = vim.loop.new_pipe(false)
  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)
  
  if hl_ns then
    vim.api.nvim_buf_clear_namespace(buf, hl_ns, 0, -1)
  else
    hl_ns = vim.api.nvim_create_namespace("")
  end
  
  local grey_id = vim.api.nvim_create_namespace("")
  local linecount = vim.api.nvim_buf_line_count(buf)
  for i=1,linecount  do
    vim.api.nvim_buf_add_highlight(buf, grey_id, "NonText", i-1, 0, -1)
  end
  

  local finish = function(code, signal) 
		vim.schedule(function()
      if #output_lines == 0 then
        vim.api.nvim_buf_clear_namespace(buf, grey_id, 0, -1)
      end
      
      if #output_lines == 0 then
        vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})
        
      end
      
      local new_lines = {}
      
      if previous then 
        local best = {}
        local best = {}
        
        local A = previous
        local B = output_lines
        
        best[0] = {}
        for j=0,#B do
          best[0][j] = {}
        end
        
        for i=1,#A do
          best[i] = {}
          best[i][0] = {}
          for j=1,#B do
            if B[j] ~= A[i] then
              if #best[i-1][j] > #best[i][j-1] then
                best[i][j] = best[i-1][j]
              else
                best[i][j] = best[i][j-1]
              end
            else
              best[i][j] = vim.deepcopy(best[i-1][j-1])
              table.insert(best[i][j], j)
            end
          end
        end
        
        local lcs = best[#previous][#output_lines]
        
        local k = 1
        for i=1,#output_lines do
          if k <= #lcs and lcs[k] == i then
            k = k + 1
          else
            table.insert(new_lines, i)
          end
        end
        
      else
        for i=1,#output_lines do
          table.insert(new_lines, i)
        end
        
      end
      
      for _,lnum in ipairs(new_lines) do
        vim.api.nvim_buf_add_highlight(buf, hl_ns, "Search", lnum-1, 0, -1)
      end
      
      previous = output_lines
      
      if done then
        done()
      end
		end)
  end

  local handle, err
  if ft == "lua" then
    -- After a lot of sweet and tears, I've found
    -- that neovim only outputs to stdout on exit
    -- that's why the -c exit is crucial,
    -- otherwise nothing is captured.
    handle, err = vim.loop.spawn("nvim",
    	{
    		stdio = {stdin, stdout, stderr},
    		args = {"--headless", "-u", "NONE", "-c", "luafile " .. filename, "-c", "exit"},
    		cwd = ".",
    	}, finish)
    
  elseif ft == "python" then
  elseif ft == "vim" then
  end
  assert(handle, err)
  
  stdout:read_start(function(err, data)
    vim.schedule(function()
      assert(not err, err)
      if data then
        if #output_lines == 0 then
          vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})
          
          vim.api.nvim_buf_clear_namespace(buf, grey_id, 0, -1)
        end
        
        for line in vim.gsplit(data, "\r*\n") do
          if #output_lines == 0 then
            vim.api.nvim_buf_set_lines(buf, 0, -1, true, { line })
          else
            vim.api.nvim_buf_set_lines(buf, -1, -1, true, { line })
          end
          table.insert(output_lines, line)
          if #output_lines >= MAX_LINES then
            handle:close()
            stdout:read_stop()
            stderr:read_stop()
            
            error("dash.nvim: too many lines. Abort script")
          end
        end
        
      end
    end)
  end)
  
  stderr:read_start(function(err, data)
    vim.schedule(function()
      assert(not err, err)
      if data then
        local open_quickfix = false
        if #output_lines == 0 then
          vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})
          
          vim.api.nvim_buf_clear_namespace(buf, grey_id, 0, -1)
        end
        
        for line in vim.gsplit(data, "\r*\n") do
          if #output_lines == 0 then
            vim.api.nvim_buf_set_lines(buf, 0, -1, true, { line })
          else
            vim.api.nvim_buf_set_lines(buf, -1, -1, true, { line })
          end
          table.insert(output_lines, line)
          if #output_lines >= MAX_LINES then
            handle:close()
            stdout:read_stop()
            stderr:read_stop()
            
            error("dash.nvim: too many lines. Abort script")
          end
        end
        
      end
    end)
  end)
  
  if handle then
    output_lines = {}
    
  end
end

function M.execute_buf()
  local name = vim.api.nvim_buf_get_name(0)
  local extext = vim.fn.fnamemodify(name, ":e:e")
  local tangle = string.match(extext, ".*%.tl")
  
  local filename, ft
  if tangle then
    filename = require"ntangle".getRootFilename()
    
  else
    filename = vim.api.nvim_buf_get_name(0)
    
  end
  ft = vim.api.nvim_buf_get_option(0, "ft")
  
  M.execute(filename, ft, true)
end


return M

