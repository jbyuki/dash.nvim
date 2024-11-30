##../dash
@spawn_glslc_for_glsl+=
local parent = vim.fn.fnamemodify(filename, ":p:h")
local root = vim.fn.fnamemodify(filename, ":t:r")
local ext = vim.fn.fnamemodify(filename, ":e")

@callback_for_glsl_finish

@find_vulkan_version

handle, err = vim.loop.spawn("cmd",
	{
		stdio = {stdin, stdout, stderr},
		args = {"/c " .. bin .. " " .. filename .. " -o " .. parent .. "\\" .. root .. "_" .. ext .. ".spv" },
		cwd = ".",
	}, finish_glsl)

@find_vulkan_version+=
local bin = vim.fs.joinpath(vim.g.glslc_dir, "glslc.exe")

@callback_for_glsl_finish+=
local finish_glsl = function(code, signal)
  vim.schedule(function()
    if #output_lines == 0 then
      @close_output_split
      if done then
        done()
      end
    else
      finish()
    end
  end)
end
