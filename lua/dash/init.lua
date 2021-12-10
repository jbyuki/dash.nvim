-- Generated using ntangle.nvim
local state_buf, state_win
local parent_width, parent_height
local win_width, win_height

local ns_hl = vim.api.nvim_create_namespace("")

local ns_hl2 = vim.api.nvim_create_namespace("")

local client_code_fn
local client_code = [[ 
dash_current_line = nil
previous_lnum = nil
dash_filename = nil
dash_return_filename = nil

function dash_every_line(event, lnum)
  if lnum == 0 or lnum == previous_lnum then
    return
  end

  local info = debug.getinfo(2, 'S')
  if info.source ~= "@" .. dash_filename then
    return
  end

  dash_current_line = lnum
  previous_lnum = lnum

  if dash_breakpoint[lnum] or dash_step then
    dash_continue = false
    vim.fn.rpcnotify(dash_debug_conn, "nvim_exec_lua", "dash_breaked = true", {})
    
    while not dash_continue do
      if dash_inspect_name then
        dash_debug_vars = {}
        local stack = 2
        local stack_valid = true
        while stack_valid do
          local li = 1
          while true do
            local lv, lv
            stack_valid, ln, lv = pcall(debug.getlocal, stack, li)
            if not stack_valid then
              break
            end
            li = li + 1
            if not ln then break end
        
            dash_debug_vars[ln] = lv
          end
          stack = stack + 1
        end
        
        setmetatable(dash_debug_vars, {
          __index = _G
        })
        
        local str = dash_inspect_name:gsub('%a[a-zA-Z0-9_]*', 'dash_debug_vars["%0"]')
        str = str:gsub('%.dash_debug_vars%["(.-)"%]', '.%1')
        dash_inspect_name = "return " .. str
        
        local f = loadstring(dash_inspect_name)
        if f then
          local ret
          ret, dash_inspect_result = pcall(f)
          if not ret then
            dash_inspect_result = string.match(dash_inspect_result, ".*:.*: (.*)")
          end
        end
        
        dash_inspect_result_done = true
        dash_inspect_name = nil
      end
      vim.wait(200)
    end
    
  end
end

]]

dash_breaked = false

local neovim_port = 81489
local pipe_address
local neovim_handle

local signPC

local neovim_conn

local output_lines = {}

local execute_win, execute_buf

local MAX_LINES = 500

local previous

local hl_ns

local neovim_visual
local neovim_visual_conn

local previous_handle

local neovim_visual_timer

local global_handle

local out_counter = 1
local tests = {}

tests["lua"] = {
  str = [[
print("hello")
]],
  expected = { "hello" }
}
tests["python"] = {
  str = [[
print("hello")
]],
  expected = { "hello", "" }
}
tests["vim"] = {
  str = [[
echo "hello"
]],
  expected = { "hello" }
}
vim.fn.sign_define("dashBreakpointDef", { text = "B", texthl = "debugBreakpoint" })

vim.fn.sign_define("dashPCDef", { text = "PC", texthl = "debugPC", linehl = "debugPC" })

local M = {}
function M.find_sln()
  local path = vim.fn.expand("%:p")
  local sln_path
  while true do
    local parent = vim.fn.fnamemodify(path, ":h")
    local dirs = {}
    for file in vim.gsplit(vim.fn.glob(parent .. "/*"), "\n") do
      if vim.fn.isdirectory(file) == 1 then
        table.insert(dirs, file)
      end
    end
    
    local build_path
    for _, dir in ipairs(dirs) do
      if vim.fn.fnamemodify(dir, ":t") == "build" then
        build_path = dir
        break
      end
    end
    
    if build_path then
      for file in vim.gsplit(vim.fn.glob(build_path .. "/*"), "\n") do
        if vim.fn.isdirectory(file) == 0 then
          if vim.fn.fnamemodify(file, ":e") == "sln" then
            sln_path = file
            break
          end
        end
      end
    end
    

    if sln_path then
      break
    end

    if parent == path then
      break
    end
    path = parent 
  end
  return sln_path
end

function M.toggle_breakpoint()
  local lnum, _  = unpack(vim.api.nvim_win_get_cursor(0))
  
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  
  local bufname = vim.api.nvim_buf_get_name(0)
  local signs = vim.fn.sign_getplaced(bufname, {group="dashBreakpoint", lnum=row})
  
  if #signs[1].signs == 0 then
    vim.fn.sign_place(0, "dashBreakpoint", "dashBreakpointDef", bufname, {lnum = row})
  else
    vim.fn.sign_unplace("dashBreakpoint", { buffer = bufname, id = signs[1].signs[1].id })
  end
  
  if debug_running then
    local name = vim.api.nvim_buf_get_name(0)
    local extext = vim.fn.fnamemodify(name, ":e:e")
    local tangle = string.match(extext, ".*%.t")
    
    if tangle then
      local tangled = require"ntangle".get_location_list()
      local mapping = {}
      for lnum, line in ipairs(tangled) do
        local prefix, l = unpack(line)
        if l.lnum then
          mapping[l.lnum] = mapping[l.lnum] or {}
          table.insert(mapping[l.lnum], lnum)
        end
      end
      
      local lnums = mapping[lnum]
      for _, lnum in ipairs(lnums) do
        vim.fn.rpcnotify(neovim_conn, 'nvim_exec_lua', "if dash_breakpoint[" .. lnum .. "] then dash_breakpoint[" .. lnum .. "] = nil else dash_breakpoint[" .. lnum .. "] = true end" , {})
        
      end
    else
      vim.fn.rpcnotify(neovim_conn, 'nvim_exec_lua', "if dash_breakpoint[" .. lnum .. "] then dash_breakpoint[" .. lnum .. "] = nil else dash_breakpoint[" .. lnum .. "] = true end" , {})
      
    end
  end
end

function M.clear_breakpoints()
  vim.fn.sign_unplace("dashBreakpoint", { buffer = bufname })
  
  if debug_running then
    vim.fn.rpcnotify(neovim_conn, 'nvim_exec_lua', "dash_breakpoint = {}" , {})
    
  end
end

function M.continue()
  vim.fn.rpcnotify(neovim_conn, "nvim_exec_lua", [[dash_continue = true]], {})
  vim.fn.rpcnotify(neovim_conn, "nvim_exec_lua", [[dash_step = nil]], {})
  
  if signPC then
    local bufname = vim.api.nvim_buf_get_name(0)
    vim.fn.sign_unplace("dashPC", { buffer = bufname })
    signPC = nil
  end
  local timer = vim.loop.new_timer()
  timer:start(0, 200, function()
    if dash_breaked then
      vim.schedule(function()
        local cur_lnum = vim.fn.rpcrequest(neovim_conn, "nvim_exec_lua", [[return dash_current_line]], {})
        
        local cur_filename = vim.fn.rpcrequest(neovim_conn, "nvim_exec_lua", [[return dash_return_filename]], {})
        local name = vim.api.nvim_buf_get_name(0)
        local extext = vim.fn.fnamemodify(name, ":e:e")
        local tangle = string.match(extext, ".*%.t")
        
        if tangle then
          local tangled = require"ntangle".get_location_list()
          local mapping = {}
          for lnum, line in ipairs(tangled) do
            local prefix, l = unpack(line)
            if l.lnum then
              mapping[l.lnum] = mapping[l.lnum] or {}
              table.insert(mapping[l.lnum], lnum)
            end
          end
          
          local bufname = vim.api.nvim_buf_get_name(0)
          local prefix, l = unpack(tangled[cur_lnum])
          signPC = vim.fn.sign_place(0, "dashPC", "dashPCDef", bufname, {lnum = l.lnum})
          vim.api.nvim_command("normal " .. l.lnum .. "ggzz")
          
        else
          local bufname = vim.api.nvim_buf_get_name(0)
          signPC = vim.fn.sign_place(0, "dashPC", "dashPCDef", bufname, {lnum = cur_lnum})
          vim.api.nvim_command("normal " .. cur_lnum .. "ggzz")
          
        end
        print("Debugger breaked on line " .. cur_lnum .. "!")
      end)
      dash_breaked = false
      timer:close()
    end
  end)
  
end

function M.inspect()
  local name = vim.fn.expand("<cword>")
  
  vim.fn.rpcnotify(neovim_conn, 'nvim_exec_lua', "dash_inspect_result_done = false", {})
  vim.fn.rpcnotify(neovim_conn, 'nvim_exec_lua', "dash_inspect_result = nil", {})
  vim.fn.rpcnotify(neovim_conn, 'nvim_exec_lua', "dash_inspect_name = " .. vim.inspect(name), {})
  
  local timer = vim.loop.new_timer()
  timer:start(0, 200, function()
    vim.schedule(function()
      local dash_inspect_result_done = vim.fn.rpcrequest(neovim_conn, 'nvim_exec_lua', [[return dash_inspect_result_done]], {})
      
      if dash_inspect_result_done then
        local dash_inspect_result = vim.fn.rpcrequest(neovim_conn, 'nvim_exec_lua', [[return dash_inspect_result]], {})
        
        local lines = vim.split(vim.inspect(dash_inspect_result), "\r*\n")
        
  
        local inspect_buf = vim.api.nvim_create_buf(false, true)
        
        vim.api.nvim_buf_set_lines(inspect_buf, 0, -1, true, lines)
        
        local max_width = 0
        for _, line in ipairs(lines) do
          max_width = math.max(vim.api.nvim_strwidth(line), max_width)
        end
        
        local opts = {
        	relative = "cursor",
          row = 1,
          col = 1,
        	width = max_width,
        	height = #lines,
        	style = 'minimal'
        }
        
        local win = vim.api.nvim_open_win(inspect_buf, false, opts)
        
        M._close_preview_autocmd({"CursorMoved", "CursorMovedI", "BufHidden", "BufLeave"}, win)
        timer:close()
      end
    end)
  end)
  
end

function M.vinspect()
  local _, srow, scol, _ = unpack(vim.fn.getpos("'<"))
  local _, erow, ecol, _ = unpack(vim.fn.getpos("'>"))
  
  assert(srow == erow, "only single row selection are supported!")
  
  local line = vim.api.nvim_buf_get_lines(0, srow-1, srow, true)[1]
  local name = string.sub(line, scol, ecol)
  
  vim.fn.rpcnotify(neovim_conn, 'nvim_exec_lua', "dash_inspect_result_done = false", {})
  vim.fn.rpcnotify(neovim_conn, 'nvim_exec_lua', "dash_inspect_result = nil", {})
  vim.fn.rpcnotify(neovim_conn, 'nvim_exec_lua', "dash_inspect_name = " .. vim.inspect(name), {})
  
  local timer = vim.loop.new_timer()
  timer:start(0, 200, function()
    vim.schedule(function()
      local dash_inspect_result_done = vim.fn.rpcrequest(neovim_conn, 'nvim_exec_lua', [[return dash_inspect_result_done]], {})
      
      if dash_inspect_result_done then
        local dash_inspect_result = vim.fn.rpcrequest(neovim_conn, 'nvim_exec_lua', [[return dash_inspect_result]], {})
        
        local lines = vim.split(vim.inspect(dash_inspect_result), "\r*\n")
        
  
        local inspect_buf = vim.api.nvim_create_buf(false, true)
        
        vim.api.nvim_buf_set_lines(inspect_buf, 0, -1, true, lines)
        
        local max_width = 0
        for _, line in ipairs(lines) do
          max_width = math.max(vim.api.nvim_strwidth(line), max_width)
        end
        
        local opts = {
        	relative = "cursor",
          row = 1,
          col = 1,
        	width = max_width,
        	height = #lines,
        	style = 'minimal'
        }
        
        local win = vim.api.nvim_open_win(inspect_buf, false, opts)
        
        M._close_preview_autocmd({"CursorMoved", "CursorMovedI", "BufHidden", "BufLeave"}, win)
        timer:close()
      end
    end)
  end)
  
end

function M.debug_buf()
  local name = vim.api.nvim_buf_get_name(0)
  local extext = vim.fn.fnamemodify(name, ":e:e")
  local tangle = string.match(extext, ".*%.t")
  
  local filename, ft
  if tangle then
    filename = require"ntangle".getRootFilename()
    
  else
    filename = vim.api.nvim_buf_get_name(0)
    
  end
  ft = vim.api.nvim_buf_get_option(0, "ft")
  
  M.debug(filename, ft)
end

function M.debug(filename, ft)
  if ft == "lua" then
    if neovim_handle then
      neovim_handle:kill()
      neovim_handle = nil
    end
    

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
    

    neovim_conn = nil
    for i=1,10 do
      local err, success
      success, neovim_conn = pcall(vim.fn.sockconnect, "pipe", pipe_address, { rpc = true })
      
      if success then
        break
      end
      vim.wait(200)
    end

    assert(neovim_conn, "Could not establish connection with debug instance")

    -- the name serverstart() is kind of
    -- misleading because it doesn't actually
    -- start a server, but only provides
    -- the caller with another pipe address
    -- to connect to the running instance
    local my_address = vim.fn.serverstart()
    
    -- inspect is used here to escape characters such as \, ", ...
    vim.fn.rpcnotify(neovim_conn, 'nvim_exec', [[lua dash_debug_conn = vim.fn.sockconnect("pipe", ]] .. vim.inspect(my_address) .. [[, {rpc = true})]], true)

    if not client_code_fn then
      client_code_fn = vim.fn.tempname()
      -- print("temp file " .. client_code_fn)
      local f = io.open(client_code_fn, "w")
      for line in vim.gsplit(client_code, "\r*\n") do
        f:write(line .. "\n")
      end
      f:close()
    end
    
    vim.fn.rpcnotify(neovim_conn, "nvim_exec", "luafile " .. client_code_fn, false)
    vim.wait(200)
    

    local bufname = vim.api.nvim_buf_get_name(0)
    local signs = vim.fn.sign_getplaced(bufname, {group="dashBreakpoint"})
    
    vim.fn.rpcnotify(neovim_conn, 'nvim_exec_lua', "dash_breakpoint = {}" , {})
    
    
    local name = vim.api.nvim_buf_get_name(0)
    local extext = vim.fn.fnamemodify(name, ":e:e")
    local tangle = string.match(extext, ".*%.t")
    
    if tangle then
      local tangled = require"ntangle".get_location_list()
      local mapping = {}
      for lnum, line in ipairs(tangled) do
        local prefix, l = unpack(line)
        if l.lnum then
          mapping[l.lnum] = mapping[l.lnum] or {}
          table.insert(mapping[l.lnum], lnum)
        end
      end
      
      for _, sign in ipairs(signs[1].signs) do
        local lnums = mapping[sign.lnum]
        for _, lnum in ipairs(lnums) do
          vim.fn.rpcnotify(neovim_conn, 'nvim_exec_lua', "dash_breakpoint[" .. lnum .. "] = true" , {})
        end
      end
      
    else
      for _, sign in ipairs(signs[1].signs) do
        vim.fn.rpcnotify(neovim_conn, 'nvim_exec_lua', "dash_breakpoint[" .. sign.lnum .. "] = true" , {})
      end
    end
    
    vim.fn.rpcnotify(neovim_conn, 'nvim_exec_lua', "dash_filename = " .. vim.inspect(filename), {})

    vim.fn.rpcnotify(neovim_conn, "nvim_exec_lua", [[debug.sethook(dash_every_line, "l", 0)]], {})
    
    vim.fn.rpcnotify(neovim_conn, "nvim_exec", "luafile " .. filename, false)
    

    local timer = vim.loop.new_timer()
    timer:start(0, 200, function()
      if dash_breaked then
        vim.schedule(function()
          local cur_lnum = vim.fn.rpcrequest(neovim_conn, "nvim_exec_lua", [[return dash_current_line]], {})
          
          local cur_filename = vim.fn.rpcrequest(neovim_conn, "nvim_exec_lua", [[return dash_return_filename]], {})
          local name = vim.api.nvim_buf_get_name(0)
          local extext = vim.fn.fnamemodify(name, ":e:e")
          local tangle = string.match(extext, ".*%.t")
          
          if tangle then
            local tangled = require"ntangle".get_location_list()
            local mapping = {}
            for lnum, line in ipairs(tangled) do
              local prefix, l = unpack(line)
              if l.lnum then
                mapping[l.lnum] = mapping[l.lnum] or {}
                table.insert(mapping[l.lnum], lnum)
              end
            end
            
            local bufname = vim.api.nvim_buf_get_name(0)
            local prefix, l = unpack(tangled[cur_lnum])
            signPC = vim.fn.sign_place(0, "dashPC", "dashPCDef", bufname, {lnum = l.lnum})
            vim.api.nvim_command("normal " .. l.lnum .. "ggzz")
            
          else
            local bufname = vim.api.nvim_buf_get_name(0)
            signPC = vim.fn.sign_place(0, "dashPC", "dashPCDef", bufname, {lnum = cur_lnum})
            vim.api.nvim_command("normal " .. cur_lnum .. "ggzz")
            
          end
          print("Debugger breaked on line " .. cur_lnum .. "!")
        end)
        dash_breaked = false
        timer:close()
      end
    end)
    

    -- @close_connect_to_neovim_debug
    -- @kill_neovim_instance_for_debug
  end
end
function M.step()
  vim.fn.rpcnotify(neovim_conn, "nvim_exec_lua", [[dash_step = true]], {})
  vim.fn.rpcnotify(neovim_conn, "nvim_exec_lua", [[dash_continue = true]], {})
  if signPC then
    local bufname = vim.api.nvim_buf_get_name(0)
    vim.fn.sign_unplace("dashPC", { buffer = bufname })
    signPC = nil
  end
  local timer = vim.loop.new_timer()
  timer:start(0, 200, function()
    if dash_breaked then
      vim.schedule(function()
        local cur_lnum = vim.fn.rpcrequest(neovim_conn, "nvim_exec_lua", [[return dash_current_line]], {})
        
        local cur_filename = vim.fn.rpcrequest(neovim_conn, "nvim_exec_lua", [[return dash_return_filename]], {})
        local name = vim.api.nvim_buf_get_name(0)
        local extext = vim.fn.fnamemodify(name, ":e:e")
        local tangle = string.match(extext, ".*%.t")
        
        if tangle then
          local tangled = require"ntangle".get_location_list()
          local mapping = {}
          for lnum, line in ipairs(tangled) do
            local prefix, l = unpack(line)
            if l.lnum then
              mapping[l.lnum] = mapping[l.lnum] or {}
              table.insert(mapping[l.lnum], lnum)
            end
          end
          
          local bufname = vim.api.nvim_buf_get_name(0)
          local prefix, l = unpack(tangled[cur_lnum])
          signPC = vim.fn.sign_place(0, "dashPC", "dashPCDef", bufname, {lnum = l.lnum})
          vim.api.nvim_command("normal " .. l.lnum .. "ggzz")
          
        else
          local bufname = vim.api.nvim_buf_get_name(0)
          signPC = vim.fn.sign_place(0, "dashPC", "dashPCDef", bufname, {lnum = cur_lnum})
          vim.api.nvim_command("normal " .. cur_lnum .. "ggzz")
          
        end
        print("Debugger breaked on line " .. cur_lnum .. "!")
      end)
      dash_breaked = false
      timer:close()
    end
  end)
  
end
function M._close_preview_autocmd(events, winnr)
  vim.api.nvim_command("autocmd "..table.concat(events, ',').." <buffer> ++once lua pcall(vim.api.nvim_win_close, "..winnr..", true)")
end

function M.execute(filename, ft, open_split, done)
  if previous_handle then
    if previous_handle:is_active() then
      previous_handle:kill()
      previous_handle = nil
    end
  end
  
  local buf
  if execute_win and vim.api.nvim_win_is_valid(execute_win) then
    local win_tab = vim.api.nvim_win_get_tabpage(execute_win)
    local cur_tab = vim.api.nvim_get_current_tabpage()
    if win_tab ~= cur_tab then
      vim.api.nvim_win_close(execute_win, true)
      execute_win = nil
    end
  end
  
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
    vim.api.nvim_command("setlocal buftype=nofile bufhidden=wipe nobuflisted nolist noswapfile nospell")
    vim.api.nvim_command("setlocal nonumber")
    vim.api.nvim_command("setlocal norelativenumber")
    execute_buf = vim.api.nvim_win_get_buf(0)
    
    local bufname
    while true do
      bufname = "Out #" .. out_counter
      local oldbufnr = vim.fn.bufnr(bufname)
      if oldbufnr == -1 then
        break
      end
      out_counter = out_counter + 1
    end
    vim.api.nvim_buf_set_name(execute_buf, bufname)
    out_counter = out_counter + 1
    vim.api.nvim_command("wincmd p")
    
    if previous then
      vim.api.nvim_buf_set_lines(execute_buf, 0, -1, true, previous)
    end
    
  else
    execute_buf = vim.api.nvim_create_buf(false, true)
    
  end
  buf = execute_buf
  
  local execute_win_height = vim.api.nvim_win_get_height(execute_win)
  
  vim.api.nvim_command("cclose")
  vim.fn.setqflist({})
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
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      
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
    		args = {"--headless", "-c", "luafile " .. filename, "-c", "exit"},
    		cwd = ".",
    	}, finish)
    
  elseif ft == "python" then
    handle, err = vim.loop.spawn("python",
    	{
    		stdio = {stdin, stdout, stderr},
    		args = {filename},
    		cwd = ".",
    	}, finish)
    
    
  elseif ft == "asm" then
    local link_program
    local execute_program
    handle, err = vim.loop.spawn("nasm",
    	{
    		stdio = {stdin, stdout, stderr},
        args = { "-felf64", filename },
    		cwd = ".",
    	}, function(code, signal)
        vim.schedule(function()
          if code == 0 then
            link_program()
          else
            finish(code, signal)
          end
        end)
      end)

    function link_program()
      local obj_file = vim.fn.fnamemodify(filename, ":r") .. ".o"

      output_lines = {}
      
      vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})
      
      local stdin = vim.loop.new_pipe(false)
      local stdout = vim.loop.new_pipe(false)
      local stderr = vim.loop.new_pipe(false)
      
      handle, err = vim.loop.spawn("ld",
        {
          stdio = {stdin, stdout, stderr},
          args = { obj_file },
          cwd = ".",
        }, function(code, signal)
          vim.schedule(function()
            if code == 0 then
              execute_program()
            else
              finish(code, signal)
            end
          end)
        end)

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
                
                if handle then
                  handle:kill()
                  handle = nil
                end
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
                
                if handle then
                  handle:kill()
                  handle = nil
                end
                error("dash.nvim: too many lines. Abort script")
              end
            end
            
            if ft == "lua" then
              for line in vim.gsplit(data, "\r*\n") do
                if string.match(line, "^E%d+: Error while creating lua chunk: ") then
                  local errnum, fn, lnum, errmsg = string.match(line, "^E(%d+): Error while creating lua chunk: (.-%.lua):(%d+): (.*)")
                  
                  
                  vim.fn.setqflist({{
                    filename = fn, 
                    lnum = lnum, 
                    nr = errnum,
                    text = errmsg,
                    type = 'E'
                  }})
                  open_quickfix = true
                  
                end
              end
            end
            
            if ft == "vim" then
              local filename
              local in_error = false
              local lnum
              local errors = {}
              for line in vim.gsplit(data, "\r*\n") do
                if string.match(line, "^Error detected while processing") then
                  filename = string.match(line, "^Error detected while processing (.+):")
                  
                  in_error = true
                elseif in_error and string.match(line, "^line") then
                  lnum = string.match(line, "^line (%d+)")
                  
                elseif in_error and string.match(line, "^E%d+: ") then
                  local errnum, errmsg = string.match(line, "^E(%d+): (.+)")
                  
                  table.insert(errors, {
                    filename = filename,
                    lnum = lnum,
                    nr = errnum,
                    text = errmsg,
                    type = 'E',
                  })
                  
                end
              end
            
              vim.fn.setqflist(errors)
              if #errors > 0 then
                open_quickfix = true
              end
            end
            
            if open_quickfix then
              -- vim.api.nvim_command("copen")
            end
            
          end
        end)
      end)
      

    end

    function execute_program()
      output_lines = {}
      
      vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})
      
      local stdin = vim.loop.new_pipe(false)
      local stdout = vim.loop.new_pipe(false)
      local stderr = vim.loop.new_pipe(false)
      
      handle, err = vim.loop.spawn("./a.out",
        {
          stdio = {stdin, stdout, stderr},
          cwd = ".",
        }, finish)

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
                
                if handle then
                  handle:kill()
                  handle = nil
                end
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
                
                if handle then
                  handle:kill()
                  handle = nil
                end
                error("dash.nvim: too many lines. Abort script")
              end
            end
            
            if ft == "lua" then
              for line in vim.gsplit(data, "\r*\n") do
                if string.match(line, "^E%d+: Error while creating lua chunk: ") then
                  local errnum, fn, lnum, errmsg = string.match(line, "^E(%d+): Error while creating lua chunk: (.-%.lua):(%d+): (.*)")
                  
                  
                  vim.fn.setqflist({{
                    filename = fn, 
                    lnum = lnum, 
                    nr = errnum,
                    text = errmsg,
                    type = 'E'
                  }})
                  open_quickfix = true
                  
                end
              end
            end
            
            if ft == "vim" then
              local filename
              local in_error = false
              local lnum
              local errors = {}
              for line in vim.gsplit(data, "\r*\n") do
                if string.match(line, "^Error detected while processing") then
                  filename = string.match(line, "^Error detected while processing (.+):")
                  
                  in_error = true
                elseif in_error and string.match(line, "^line") then
                  lnum = string.match(line, "^line (%d+)")
                  
                elseif in_error and string.match(line, "^E%d+: ") then
                  local errnum, errmsg = string.match(line, "^E(%d+): (.+)")
                  
                  table.insert(errors, {
                    filename = filename,
                    lnum = lnum,
                    nr = errnum,
                    text = errmsg,
                    type = 'E',
                  })
                  
                end
              end
            
              vim.fn.setqflist(errors)
              if #errors > 0 then
                open_quickfix = true
              end
            end
            
            if open_quickfix then
              -- vim.api.nvim_command("copen")
            end
            
          end
        end)
      end)
      
    end
  elseif ft == "go" then
    handle, err = vim.loop.spawn("cmd",
    	{
    		stdio = {stdin, stdout, stderr},
    		args = {"/c go run ."},
    		cwd = ".",
    	}, finish)
  elseif ft == "tex" or ft == "plaintex" then
    
    MAX_LINES = 100000
    handle, err = vim.loop.spawn("cmd",
      {
        stdio = {stdin, stdout, stderr},
        args = {"/c pdflatex -interaction=nonstopmode " .. filename},
        cwd = ".",
      }, finish)
  elseif ft == "fennel" then
    handle, err = vim.loop.spawn("cmd",
    	{
    		stdio = {stdin, stdout, stderr},
    		args = {"/c fennel " .. filename},
    		cwd = ".",
    	}, finish)
    
  elseif ft == "javascript" then
    handle, err = vim.loop.spawn("cmd",
    	{
    		stdio = {stdin, stdout, stderr},
    		args = {"/c node " .. filename},
    		cwd = ".",
    	}, finish)
    
  elseif ft == "vim" then
    handle, err = vim.loop.spawn("nvim",
    	{
    		stdio = {stdin, stdout, stderr},
    		args = {"--headless", "-u", "NONE", "-c", "source " .. filename, "-c", "exit"},
    		cwd = ".",
    	}, finish)
  elseif ft == "kotlin" then
    local path = vim.api.nvim_buf_get_name(0)
    path = path:gsub("\\", "/")
    local root = path:match("^(.*)/app/src/main/java")
    
    local done_compile = vim.schedule_wrap(function(code, signal)
      if code == 0 then
        local apk_dir = root .. "/app/build/outputs/apk/debug"
        local apks = vim.fn.glob(apk_dir .. "/*.apk")
        if apks == "" then
          finish(code, signal)
        end
        
        local apk = vim.split(apks, "\n")[1]
        
        local done_install = vim.schedule_wrap(function(code, signal)
          if code == 0 then
            local aapt_output = {}
            
            local done_aapt = vim.schedule_wrap(function(code, signal)
              if code == 0 then
                local pkg_name
                for _, line in ipairs(aapt_output) do
                  pkg_name = line:match([[package="([^"]*)"]])
                  if pkg_name then
                    break
                  end
                end
                
                local activity_name
                for i=1,#aapt_output do
                  local line = aapt_output[i]
                  if line:match("E: activity") then
                    for j=i+1,#aapt_output do
                      local line = aapt_output[j]
                      activity_name = line:match([[Raw: "(.*)"]])
                      if activity_name then
                        break
                      end
                    end
                    
                    local is_main = false
                    for j=i+1,#aapt_output do
                      local line = aapt_output[j]
                      if line:match("E: activity") then
                        break
                      end
                    
                      local name = line:match([[Raw: "(.*)"]])
                      if name and name == "android.intent.action.MAIN" then
                        is_main = true
                        break
                      end
                    end
                    
                    if is_main then
                      break
                    end
                  end
                end
                
                handle, err = vim.loop.spawn("cmd",
                	{
                		stdio = {stdin, stdout, stdin},
                		args = {string.format("/c adb shell am start -n %s/%s", pkg_name, activity_name)},
                		cwd = root,
                	}, finish)
              else
                finish(code, signal)
              end
            end)
            
            local aapt_stdout = vim.loop.new_pipe(false)
            local aapt_stderr = vim.loop.new_pipe(false)
            
            handle, err = vim.loop.spawn("cmd",
            	{
            		stdio = {stdin, aapt_stdout, aapt_stderr},
            		args = {string.format("/c aapt dump xmltree %s AndroidManifest.xml", apk)},
            		cwd = root,
            	}, done_aapt)
            
            aapt_stdout:read_start(function(err, data)
              assert(not err, err)
              if data then
                for line in vim.gsplit(data, "\n") do
                  table.insert(aapt_output, line)
                end
              end
            end)
            
            aapt_stderr:read_start(function(err, data)
              assert(not err, err)
              if data then
                for line in vim.gsplit(data, "\n") do
                  table.insert(aapt_output, line)
                end
              end
            end)
            
            
          else
            finish(code, signal)
          end
        end)
        
        handle, err = vim.loop.spawn("cmd",
        	{
        		stdio = {stdin, stdout, stderr},
        		args = {"/c adb install " .. apk},
        		cwd = root,
        	}, done_install)
        
      else
        local qflist = {} 
        for _, line in ipairs(output_lines) do
          if line:match("^%s*ERROR") then
            local filename, line_number, err_text = line:match("^%s*ERROR:([^.]+.%w+):(%d+):(.*)")
            
            table.insert(qflist, {
              filename = filename,
              lnum = line_number,
              text = err_text,
              type = "E",
            })
            
            vim.fn.setqflist(qflist)
            
          elseif line:match("^%s*e:") then
            local filename, line_number, err_text = line:match("^%s*e:%s*([^.]+.%w+):%s%((%d+),%s*%d+%):(.*)")
            table.insert(qflist, {
              filename = filename,
              lnum = line_number,
              text = err_text,
              type = "E",
            })
            
            vim.fn.setqflist(qflist)
            
          end
        end
        
        finish(code, signal)
      end
    end)
    
    handle, err = vim.loop.spawn("gradlew.bat",
    	{
    		stdio = {stdin, stdout, stderr},
    		args = {[[assembleDebug]]},
    		cwd = root,
    	}, done_compile)
    
  elseif ft == "cpp" or ft == "c" then
    local vs = M.find_sln()
    local build_path = vim.fn.fnamemodify(vs, ":h")
    
    if vs then
      local execute_program
      handle, err = vim.loop.spawn("MSBuild.exe",
      	{
      		stdio = {stdin, stdout, stderr},
          args = { vs },
      		cwd = ".",
      	}, function(code, signal)
          vim.schedule(function()
            if code == 0 then
              execute_program()
            else
              local error_lines, warning_lines = {}, {}
              for _, line in ipairs(output_lines) do
                if (string.find(line, ": error") or string.find(line, ": fatal error")) then
                  if string.find(line, "LNK") then
                    local fn,error_str = string.match(line, "^%s*(.+):.+: (.+) %[")
                    if fn and error_str then
                      table.insert(error_lines, {fn, -1, error_str})
                    end
                  elseif not string.find(line, "^ ") then
                    local fn,lnum,error_str = string.match(line, "^(.+)%((%d+),%d+%):[^:]+: (.+) %[")
                    if fn and lnum and error_str then
                      table.insert(error_lines, {fn, lnum, error_str})
                    end
                  end
                elseif string.find(line, ": warning") and not string.find(line, "^ ") then
                  local fn,lnum,warning_str = string.match(line, "^(.+)%((%d+),%d+%):[^:]+: (.+) %[")
                  if fn and lnum and warning_str then
                    table.insert(warning_lines, {fn, lnum, warning_str})
                  end
                elseif string.find(line, "Warning%(s%)") then
                  num_warnings = string.match(line, "(%d+)")
                elseif string.find(line, "Error%(s%)") then
                  num_errors = string.match(line, "(%d+)")
                end
              end
              
              local qflist = {}
              for _, line in ipairs(error_lines) do
                table.insert(qflist, {
                  filename = line[1],
                  lnum = line[2],
                  text = line[3],
                  type = "E",
                })
              end
              
              for _, line in ipairs(warning_lines) do
                table.insert(qflist, {
                  filename = line[1],
                  lnum = line[2],
                  text = line[3],
                  type = "W",
                })
              end
              
              vim.fn.setqflist(qflist)
              
              finish(code, signal)
            end
          end)
      end)
      
      function execute_program()
        local bin_path = vim.fn.fnamemodify(build_path, ":h") .. "/build/Debug"
        local exe_file = vim.fn.glob(bin_path .. "/*.exe")
      
      
        output_lines = {}
        
        vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})
        
        local stdin = vim.loop.new_pipe(false)
        local stdout = vim.loop.new_pipe(false)
        local stderr = vim.loop.new_pipe(false)
        
        handle, err = vim.loop.spawn(exe_file,
          {
            stdio = {stdin, stdout, stderr},
            cwd = ".",
          }, finish)
      
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
                  
                  if handle then
                    handle:kill()
                    handle = nil
                  end
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
                  
                  if handle then
                    handle:kill()
                    handle = nil
                  end
                  error("dash.nvim: too many lines. Abort script")
                end
              end
              
              if ft == "lua" then
                for line in vim.gsplit(data, "\r*\n") do
                  if string.match(line, "^E%d+: Error while creating lua chunk: ") then
                    local errnum, fn, lnum, errmsg = string.match(line, "^E(%d+): Error while creating lua chunk: (.-%.lua):(%d+): (.*)")
                    
                    
                    vim.fn.setqflist({{
                      filename = fn, 
                      lnum = lnum, 
                      nr = errnum,
                      text = errmsg,
                      type = 'E'
                    }})
                    open_quickfix = true
                    
                  end
                end
              end
              
              if ft == "vim" then
                local filename
                local in_error = false
                local lnum
                local errors = {}
                for line in vim.gsplit(data, "\r*\n") do
                  if string.match(line, "^Error detected while processing") then
                    filename = string.match(line, "^Error detected while processing (.+):")
                    
                    in_error = true
                  elseif in_error and string.match(line, "^line") then
                    lnum = string.match(line, "^line (%d+)")
                    
                  elseif in_error and string.match(line, "^E%d+: ") then
                    local errnum, errmsg = string.match(line, "^E(%d+): (.+)")
                    
                    table.insert(errors, {
                      filename = filename,
                      lnum = lnum,
                      nr = errnum,
                      text = errmsg,
                      type = 'E',
                    })
                    
                  end
                end
              
                vim.fn.setqflist(errors)
                if #errors > 0 then
                  open_quickfix = true
                end
              end
              
              if open_quickfix then
                -- vim.api.nvim_command("copen")
              end
              
            end
          end)
        end)
        
      end
    else
      local fn = vim.api.nvim_buf_get_name(0)
      fn = vim.fn.fnamemodify(fn, ":p")
      local pardir = vim.fn.fnamemodify(fn, ":h")
      local buildbat = vim.fn.glob(pardir .. "/build.bat") ~= ""
      
      if buildbat then
        local execute_program_bat
        handle, err = vim.loop.spawn("cmd",
        	{
        		stdio = {stdin, stdout, stderr},
        		args = {"/k", pardir .. "/build.bat" },
        		cwd = ".",
        	}, function(code, signal)
            vim.schedule(function()
              local exe_file = vim.fn.glob(pardir .. "/bin/*.exe")
              if code == 0 and exe_file ~= "" then
        
                execute_program_bat(exe_file)
              else
                finish(code, signal)
              end
            end)
          end)
        
        function execute_program_bat(exe_file)
          output_lines = {}
          
          vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})
          
          local stdin = vim.loop.new_pipe(false)
          local stdout = vim.loop.new_pipe(false)
          local stderr = vim.loop.new_pipe(false)
          
          handle, err = vim.loop.spawn(exe_file,
            {
              stdio = {stdin, stdout, stderr},
              cwd = ".",
            }, finish)
        
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
                    
                    if handle then
                      handle:kill()
                      handle = nil
                    end
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
                    
                    if handle then
                      handle:kill()
                      handle = nil
                    end
                    error("dash.nvim: too many lines. Abort script")
                  end
                end
                
                if ft == "lua" then
                  for line in vim.gsplit(data, "\r*\n") do
                    if string.match(line, "^E%d+: Error while creating lua chunk: ") then
                      local errnum, fn, lnum, errmsg = string.match(line, "^E(%d+): Error while creating lua chunk: (.-%.lua):(%d+): (.*)")
                      
                      
                      vim.fn.setqflist({{
                        filename = fn, 
                        lnum = lnum, 
                        nr = errnum,
                        text = errmsg,
                        type = 'E'
                      }})
                      open_quickfix = true
                      
                    end
                  end
                end
                
                if ft == "vim" then
                  local filename
                  local in_error = false
                  local lnum
                  local errors = {}
                  for line in vim.gsplit(data, "\r*\n") do
                    if string.match(line, "^Error detected while processing") then
                      filename = string.match(line, "^Error detected while processing (.+):")
                      
                      in_error = true
                    elseif in_error and string.match(line, "^line") then
                      lnum = string.match(line, "^line (%d+)")
                      
                    elseif in_error and string.match(line, "^E%d+: ") then
                      local errnum, errmsg = string.match(line, "^E(%d+): (.+)")
                      
                      table.insert(errors, {
                        filename = filename,
                        lnum = lnum,
                        nr = errnum,
                        text = errmsg,
                        type = 'E',
                      })
                      
                    end
                  end
                
                  vim.fn.setqflist(errors)
                  if #errors > 0 then
                    open_quickfix = true
                  end
                end
                
                if open_quickfix then
                  -- vim.api.nvim_command("copen")
                end
                
              end
            end)
          end)
          
        end
      end
    end
  elseif ft == "bf" then
    vim.schedule(function()
      if execute_win and vim.api.nvim_win_is_valid(execute_win) then
        vim.api.nvim_win_close(execute_win, true)
        execute_win = nil
      end
      
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
      
      local program = {}
      for i=1,#lines do 
        local line = lines[i]
        for j=1,string.len(line) do
          local c = line:sub(j, j)
          if c == "+" or c == "-" or c == "[" or c == "]" or c == "<" or c == ">" or c == "." or c == "," then
            table.insert(program, {
              ins = c,
              row = i-1,
              col = j-1,
            })
          end
          
        end
      end
      
      local stack = {}
      for i, c in ipairs(program) do
        if c.ins == "[" then
          table.insert(stack, i)
        elseif c.ins == "]" then
          assert(#stack > 0, "Mismatch ]")
          local j = stack[#stack]
          c.ref = j
          program[j].ref = i
          table.remove(stack)
        end
      end
      
      assert(#stack == 0, "Mismatch [")
      
      state_buf = vim.api.nvim_create_buf(false, true)
      parent_width = vim.api.nvim_win_get_width(0)
      parent_height = vim.api.nvim_win_get_height(0)
      win_width = 2
      win_height = 2
      state_win = vim.api.nvim_open_win(state_buf, false, {
        relative = "win",
        row = parent_height - win_height - 1,
        col = parent_width - win_width - 1,
        width = win_width,
        height = win_height,
        style = "minimal",
      })
      
      
      vim.api.nvim_buf_set_keymap(0, "n", "q", [[<cmd>lua require"dash".stop_bf()<CR>]], { noremap = true })
      print("Press 'q' to stop.")
      
      
      local tape = {}
      local ip = 1
      local dp = 1
      
      local output = {}
      
      timer = vim.loop.new_timer()
      timer:start(0, 50, function()
        local c = program[ip]
        
        if not c then
          timer:close()
          timer = nil
          vim.schedule(function()
            vim.api.nvim_buf_clear_namespace(0, ns_hl, 0, -1)
            
            vim.api.nvim_set_current_win(state_win)
            
          end)
          return
        end
        
      
        local sdp = dp
        
        if c.ins == "+" then
          tape[dp] = (tape[dp] or 0)+1
        elseif c.ins == "-" then
          tape[dp] = (tape[dp] or 0)-1
        elseif c.ins == "<" then
          dp = dp - 1
        elseif c.ins == ">" then
          dp = dp + 1
        elseif c.ins == "[" then
          if not tape[dp] or tape[dp] == 0 then
            ip = c.ref
          end
        elseif c.ins == "]" then
          if tape[dp] and tape[dp] ~= 0 then
            ip = c.ref
          end
        elseif c.ins == "." then
          table.insert(output, string.char(tape[dp] or 0))
        end
        
        if not tape[dp] then
          tape[dp] = 0
        end
        
        vim.schedule(function()
          vim.api.nvim_buf_clear_namespace(0, ns_hl, 0, -1)
          
          vim.api.nvim_buf_set_extmark(0, ns_hl, c.row, c.col, {
            hl_group = "IncSearch",
            end_col = c.col+1,
          })
          
          function a()
          end
          
      
          local lines = {}
          
          table.insert(lines, table.concat(tape, " ") or "")
          
          local start = 0
          for i=1,sdp-1 do
            start = start + string.len(tostring(tape[i])) + 1
          end
          
          local outlines = vim.split(table.concat(output), "\r*\n")
          for _, line in ipairs(outlines) do
            table.insert(lines, line)
          end
          
          vim.api.nvim_buf_set_lines(state_buf, 0, -1, true, lines)
          
          local max_width = 0
          for _, line in ipairs(lines) do
            max_width = math.max(string.len(line), max_width)
          end
          
          if max_width > win_width then
            win_width = max_width
            vim.api.nvim_win_set_config(state_win, {
              relative = "win",
              row = parent_height - win_height - 1,
              col = parent_width - win_width - 1,
              width = win_width,
              height = win_height,
            })
          end
          
          if #lines > win_height then
            win_height = #lines
            vim.api.nvim_win_set_config(state_win, {
              relative = "win",
              row = parent_height - win_height - 1,
              col = parent_width - win_width - 1,
              width = win_width,
              height = win_height,
            })
          end
          
          vim.api.nvim_buf_clear_namespace(state_buf, ns_hl2, 0, -1)
          local succ = pcall(vim.api.nvim_buf_set_extmark, state_buf, ns_hl2, 0, start, {
            hl_group = "IncSearch",
            end_col = start + string.len(tostring(tape[sdp]))
          })
          
          if not succ then
            timer:close()
            return
          end
          
          
        end)
        ip = ip+1
        
      end)
      
      function M.stop_bf()
        vim.api.nvim_buf_clear_namespace(0, ns_hl, 0, -1)
        
        vim.api.nvim_buf_del_keymap(0, "n", "q")
        
        vim.api.nvim_set_current_win(state_win)
        
        if timer then
          timer:close()
          timer = nil
        end
        
      end
      
    end)
    return
  end
  assert(handle, err)
  
  global_handle = handle
  
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
            
            if handle then
              handle:kill()
              handle = nil
            end
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
            
            if handle then
              handle:kill()
              handle = nil
            end
            error("dash.nvim: too many lines. Abort script")
          end
        end
        
        if ft == "lua" then
          for line in vim.gsplit(data, "\r*\n") do
            if string.match(line, "^E%d+: Error while creating lua chunk: ") then
              local errnum, fn, lnum, errmsg = string.match(line, "^E(%d+): Error while creating lua chunk: (.-%.lua):(%d+): (.*)")
              
              
              vim.fn.setqflist({{
                filename = fn, 
                lnum = lnum, 
                nr = errnum,
                text = errmsg,
                type = 'E'
              }})
              open_quickfix = true
              
            end
          end
        end
        
        if ft == "vim" then
          local filename
          local in_error = false
          local lnum
          local errors = {}
          for line in vim.gsplit(data, "\r*\n") do
            if string.match(line, "^Error detected while processing") then
              filename = string.match(line, "^Error detected while processing (.+):")
              
              in_error = true
            elseif in_error and string.match(line, "^line") then
              lnum = string.match(line, "^line (%d+)")
              
            elseif in_error and string.match(line, "^E%d+: ") then
              local errnum, errmsg = string.match(line, "^E(%d+): (.+)")
              
              table.insert(errors, {
                filename = filename,
                lnum = lnum,
                nr = errnum,
                text = errmsg,
                type = 'E',
              })
              
            end
          end
        
          vim.fn.setqflist(errors)
          if #errors > 0 then
            open_quickfix = true
          end
        end
        
        if open_quickfix then
          -- vim.api.nvim_command("copen")
        end
        
      end
    end)
  end)
  
  if handle then
    output_lines = {}
    
    previous_handle = handle
    
  end
end

function M.execute_buf()
  if neovim_visual then
    neovim_visual:kill()
    neovim_visual = nil
    if neovim_visual_timer then
      neovim_visual_timer:close()
    end
    
    return
  end
  

  local name = vim.api.nvim_buf_get_name(0)
  local extext = vim.fn.fnamemodify(name, ":e:e")
  local tangle = string.match(extext, ".*%.t")
  
  local filename, ft
  if tangle then
    filename = require"ntangle".getRootFilename()
    
  else
    filename = vim.api.nvim_buf_get_name(0)
    
  end
  ft = vim.api.nvim_buf_get_option(0, "ft")
  
  M.execute(filename, ft, true)
end

function M.execute_visual()
  ft = vim.api.nvim_buf_get_option(0, "ft")
  
  local _, start, _, _ = unpack(vim.fn.getpos("'<"))
  local _, finish, _, _ = unpack(vim.fn.getpos("'>"))
  local lines = vim.api.nvim_buf_get_lines(0, start-1, finish, true)
  

  if ft  == "lua" then
    local open_split = true
    local buf
    if execute_win and vim.api.nvim_win_is_valid(execute_win) then
      local win_tab = vim.api.nvim_win_get_tabpage(execute_win)
      local cur_tab = vim.api.nvim_get_current_tabpage()
      if win_tab ~= cur_tab then
        vim.api.nvim_win_close(execute_win, true)
        execute_win = nil
      end
    end
    
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
      vim.api.nvim_command("setlocal buftype=nofile bufhidden=wipe nobuflisted nolist noswapfile nospell")
      vim.api.nvim_command("setlocal nonumber")
      vim.api.nvim_command("setlocal norelativenumber")
      execute_buf = vim.api.nvim_win_get_buf(0)
      
      local bufname
      while true do
        bufname = "Out #" .. out_counter
        local oldbufnr = vim.fn.bufnr(bufname)
        if oldbufnr == -1 then
          break
        end
        out_counter = out_counter + 1
      end
      vim.api.nvim_buf_set_name(execute_buf, bufname)
      out_counter = out_counter + 1
      vim.api.nvim_command("wincmd p")
      
      if previous then
        vim.api.nvim_buf_set_lines(execute_buf, 0, -1, true, previous)
      end
      
    else
      execute_buf = vim.api.nvim_create_buf(false, true)
      
    end
    buf = execute_buf
    

    if not neovim_visual then
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
      
      neovim_visual_conn = M.try_connect(pipe_address)
      
      vim.fn.rpcnotify(neovim_visual_conn, "nvim_exec_lua", [[dash_output = {}]], {})
      vim.fn.rpcnotify(neovim_visual_conn, "nvim_exec_lua", [[function print(str) table.insert(dash_output, tostring(str)) end]], {})
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
      
    end

    if not neovim_visual_timer then
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
      
    end

    local fname = vim.fn.tempname()
    local f = io.open(fname, "w")
    for _, line in ipairs(lines) do
      f:write(line .. "\n")
    end
    f:close()
    
    vim.fn.rpcnotify(neovim_visual_conn, "nvim_exec", [[luafile ]] .. fname, false)
    
  elseif ft == "python" then
    local fname = vim.fn.tempname()
    local f = io.open(fname, "w")
    for _, line in ipairs(lines) do
      f:write(line .. "\n")
    end
    f:close()
    
    M.execute(fname, ft, true)
    
  elseif ft == "fennel" then
    local fname = vim.fn.tempname()
    local f = io.open(fname, "w")
    for _, line in ipairs(lines) do
      f:write(line .. "\n")
    end
    f:close()
    
    M.execute(fname, ft, true)
  elseif ft == "javascript" then
    local fname = vim.fn.tempname()
    local f = io.open(fname, "w")
    for _, line in ipairs(lines) do
      f:write(line .. "\n")
    end
    f:close()
    
    M.execute(fname, ft, true)
  end
end

function M.stop()
  if global_handle then
    global_handle:kill()
    global_handle = nil
  end
end
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

function M.execute_lines(lines, ft, show_pane, done)
  local fname = vim.fn.tempname()
  local f = io.open(fname, "w")
  for _, line in ipairs(lines) do
    f:write(line .. "\n")
  end
  f:close()
  
  local augmented = function()
    os.remove(fname)
    if done then
      done()
    end
  end
  M.execute(fname, ft, show_pane, augmented)
end

function M.test()
  local results = {}
  for ft, test in pairs(tests) do
    local done = false
    M.execute_lines(vim.split(test.str, "\n"), ft, false, function()
      done = true
    end)
    -- timeout 5 seconds
    local ok = false
    for i=1,100 do
      vim.wait(50)
      if done then
        ok = true
        break
      end
    end
    
    if not ok then
      results[ft] = "TIMEOUT"
    else
      if vim.deep_equal(previous, test.expected) then
        results[ft] = "OK"
      else
        results[ft] = "FAIL"
      end
    end
    
  end

  local result_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, result_buf)
  local lines = {}
  local text = {}
  local padding = 30
  for ft,result in pairs(results) do
    local line = ft
    local s = string.len(ft)
    for i=s+1,padding do
      line = line .. " "
    end
    
    line = line .. result
    table.insert(lines, line)
    table.insert(text, result)
  end
  vim.api.nvim_buf_set_lines(result_buf, 0, -1, true, lines)
  local ns_id = vim.api.nvim_create_namespace("")
  for i=1,#lines do
    local hl_group
    if text[i] == "OK" then
      hl_group = "Search"
    elseif text[i] == "TIMEOUT" then
      hl_group = "Substitute"
    else
      hl_group = "IncSearch"
    end
    vim.api.nvim_buf_add_highlight(result_buf, ns_id, hl_group, i-1, padding, -1)
  end
  
end


return M

