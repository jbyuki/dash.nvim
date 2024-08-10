##../dash
@find_android_project_root+=
local path = vim.api.nvim_buf_get_name(0)
path = path:gsub("\\", "/")
local root = path:match("^(.*)/app/src/main/java")

@invoke_gradle_to_build_and_install+=
local done_compile = vim.schedule_wrap(function(code, signal)
  if code == 0 then
    @find_output_apk
    @install_apk_and_launch
  else
    @parse_output_gradle
    @put_gradle_errors_in_quickfix
    finish(code, signal)
  end
end)

handle, err = vim.loop.spawn("gradlew.bat",
	{
		stdio = {stdin, stdout, stderr},
		args = {[[assembleDebug]]},
		cwd = root,
	}, done_compile)

@find_output_apk+=
local apk_dir = root .. "/app/build/outputs/apk/debug"
local apks = vim.fn.glob(apk_dir .. "/*.apk")
if apks == "" then
  finish(code, signal)
end

local apk = vim.split(apks, "\n")[1]

@install_apk_and_launch+=
local done_install = vim.schedule_wrap(function(code, signal)
  if code == 0 then
    @launch_apk
  else
    vim.schedule(function() print(vim.inspect(adb_install_output)) end)
    finish(code, signal)
  end
end)

@create_output_pipe

handle, err = vim.loop.spawn("cmd",
	{
		stdio = {stdin, adb_install_stdout, adb_install_stderr},
		args = {"/c adb install " .. apk},
		cwd = root,
	}, done_install)

@register_adb_output_pipes

@install_apk_and_launch-=
local adb_install_output = {}

@create_output_pipe+=
local adb_install_stdout = vim.loop.new_pipe(false)
local adb_install_stderr = vim.loop.new_pipe(false)


@register_adb_output_pipes+=
adb_install_stdout:read_start(function(err, data)
  assert(not err, err)
  if data then
    for line in vim.gsplit(data, "\n") do
      table.insert(adb_install_output , line)
    end
  end
end)

adb_install_stderr:read_start(function(err, data)
  assert(not err, err)
  if data then
    for line in vim.gsplit(data, "\n") do
      table.insert(adb_install_output, line)
    end
  end
end)

@launch_apk+=
local aapt_output = {}

local done_aapt = vim.schedule_wrap(function(code, signal)
  if code == 0 then
    @parse_aapt_output
    @launch_activity
  else
    vim.schedule(function() print(vim.inspect(aapt_output)) end)
    finish(code, signal)
  end
end)

@create_output_pipe
handle, err = vim.loop.spawn("cmd",
	{
		stdio = {stdin, aapt_stdout, aapt_stderr},
		args = {string.format("/c aapt dump xmltree %s AndroidManifest.xml", apk)},
		cwd = root,
	}, done_aapt)

@register_new_output_pipe

@create_output_pipe+=
local aapt_stdout = vim.loop.new_pipe(false)
local aapt_stderr = vim.loop.new_pipe(false)

@register_new_output_pipe+=
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

@parse_aapt_output+=
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
    @find_name_of_activity
    local is_main = false
    @check_if_main_activity
    if is_main then
      break
    end
  end
end

@find_name_of_activity+=
for j=i+1,#aapt_output do
  local line = aapt_output[j]
  activity_name = line:match([[Raw: "(.*)"]])
  if activity_name then
    break
  end
end

@check_if_main_activity+=
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

@launch_activity+=
handle, err = vim.loop.spawn("cmd",
	{
		stdio = {stdin, stdout, stdin},
		args = {string.format("/c adb shell am start -n %s/%s", pkg_name, activity_name)},
		cwd = root,
	}, finish)
