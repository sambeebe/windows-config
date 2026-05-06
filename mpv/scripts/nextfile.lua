-- nextfile.lua
-- Navigate to next/previous file in the current directory without a playlist
-- Also supports clip points, trimming, copying path, opening Explorer,
-- frame jumps, first/last frame jumps, and moving files into a/b/c folders.

local mp = require("mp")
local utils = require("mp.utils")
local msg = require("mp.msg")

local clip_points = {}
local start_time = nil
local end_time = nil


-- Build a sorted list of files in this file's directory
local function get_files()
	local path = mp.get_property("path")
	if not path then
		return nil
	end

	local dir, name = utils.split_path(path)
	local files = utils.readdir(dir, "files") or {}
	table.sort(files)

	return dir, files, name
end


-- Jump by step (+1 for next, -1 for previous)
local function jump(step)
	local dir, files, name = get_files()
	if not dir then
		return
	end

	for i, fname in ipairs(files) do
		if fname == name then
			local target = files[i + step]
			if target then
				mp.commandv("loadfile", utils.join_path(dir, target), "replace")
			else
				mp.osd_message("No " .. (step > 0 and "next" or "previous") .. " file")
			end
			return
		end
	end
end


-- Next / previous file
mp.add_key_binding("CTRL+LEFT", "prev-file", function()
	jump(-1)
end)

mp.add_key_binding("CTRL+RIGHT", "next-file", function()
	jump(1)
end)


-- Start / end markers
function set_start()
	start_time = mp.get_property_number("time-pos")
	msg.info("Start time set: " .. tostring(start_time))
	mp.osd_message("Clip start: " .. string.format("%.2f", start_time))
end

function set_end()
	end_time = mp.get_property_number("time-pos")
	msg.info("End time set: " .. tostring(end_time))
	mp.osd_message("Clip end: " .. string.format("%.2f", end_time))
end


-- Clip points
function add_clip_point()
	local time = mp.get_property_number("time-pos", 0)
	table.insert(clip_points, time)
	table.sort(clip_points)

	mp.osd_message("📍 Clip point added at " .. string.format("%.2f", time), 1.5)
	msg.info("Clip point added: " .. time)
end

function trim_clips()
	local count = #clip_points

	if count < 2 then
		mp.osd_message("Need at least 2 clip points")
		return
	end

	local input_path = mp.get_property("path")
	if not input_path then
		mp.osd_message("No file loaded")
		return
	end

	local dir, _ = utils.split_path(input_path)

	for i = 1, count - 1 do
		local clip_start = clip_points[i]
		local clip_end = clip_points[i + 1]

		if clip_end <= clip_start then
			msg.warn("Skipping invalid segment: " .. clip_start .. " >= " .. clip_end)
		else
			local duration = clip_end - clip_start
			local output_path = utils.join_path(
				dir,
				string.format("clip_%d_%d.mp4", clip_start, clip_end)
			)

			local args = {
				"ffmpeg",
				"-ss",
				tostring(clip_start),
				"-i",
				input_path,
				"-t",
				tostring(duration),
				"-c",
				"copy",
				output_path,
			}

			msg.info("Running ffmpeg: " .. table.concat(args, " "))
			utils.subprocess_detached({ args = args })
		end
	end

	mp.osd_message("Trimmed " .. (count - 1) .. " segments.")
end

function reset_clip_points()
	clip_points = {}
	mp.osd_message("Clip points reset")
end

mp.add_key_binding("a", "add_clip_point", add_clip_point)
mp.add_key_binding("t", "trim_clips", trim_clips)
mp.add_key_binding("r", "reset_clip_points", reset_clip_points)


-- Copy current file path to clipboard
function copy_path_to_clipboard()
	local path = mp.get_property("path")
	if not path then
		mp.osd_message("No file loaded")
		return
	end

	local escaped_path = path:gsub("'", "''")

	local args = {
		"powershell",
		"-NoProfile",
		"-Command",
		string.format("Set-Clipboard -LiteralPath '%s'", escaped_path),
	}

	local result = utils.subprocess({ args = args, cancellable = false })

	if result.status == 0 then
		mp.osd_message("Copied path to clipboard")
	else
		mp.osd_message("Failed to copy to clipboard")
		msg.error("Clipboard copy failed: " .. (result.error or result.stderr or "unknown"))
	end
end

mp.add_key_binding("c", "copy_path_to_clipboard", copy_path_to_clipboard)


-- Open current file in File Explorer
function open_in_explorer()
	local path = mp.get_property("path")
	if not path then
		mp.osd_message("No file loaded")
		return
	end

	local args = {
		"explorer",
		"/select," .. path,
	}

	local result = utils.subprocess({ args = args, cancellable = false })

	if result.status == 0 then
		mp.osd_message("Opened in File Explorer")
	else
		mp.osd_message("Failed to open File Explorer")
		msg.error("Explorer command failed: " .. (result.error or result.stderr or "unknown"))
	end
end

mp.add_key_binding("o", "open_in_explorer", open_in_explorer)


-- Jump N frames forward/backward
function jump_n_frames(n, backward)
	local fps = mp.get_property_number("container-fps")

	if not fps or fps <= 0 then
		mp.osd_message("FPS not available")
		return
	end

	local direction = backward and -1 or 1
	local jump_amount = direction * (n / fps)

	mp.commandv("seek", jump_amount, "relative+exact")
	mp.osd_message(string.format("Jumped %s %d frames", backward and "back" or "ahead", n))
end

mp.add_key_binding("v", "jump_ahead_12", function()
	jump_n_frames(12, false)
end, { repeatable = true })

mp.add_key_binding("V", "jump_back_12", function()
	jump_n_frames(12, true)
end, { repeatable = true })

mp.add_key_binding("g", "jump_ahead_24", function()
	jump_n_frames(24, false)
end, { repeatable = true })

mp.add_key_binding("G", "jump_back_24", function()
	jump_n_frames(24, true)
end, { repeatable = true })

mp.add_key_binding("h", "jump_ahead_48", function()
	jump_n_frames(48, false)
end, { repeatable = true })

mp.add_key_binding("H", "jump_back_48", function()
	jump_n_frames(48, true)
end, { repeatable = true })


-- Jump to first / last frame
function go_to_first_frame()
	mp.commandv("seek", "0", "absolute+exact")
	mp.osd_message("First frame")
end

function go_to_last_frame()
	local duration = mp.get_property_number("duration")
	local fps = mp.get_property_number("container-fps", 30)

	if not duration then
		mp.osd_message("Duration not available")
		return
	end

	-- Seek just before EOF so mpv lands on the final visible frame.
	local last_frame_time = math.max(0, duration - (1 / fps))

	mp.commandv("seek", tostring(last_frame_time), "absolute+exact")
	mp.osd_message("Last frame")
end

mp.add_key_binding("HOME", "go_to_first_frame", go_to_first_frame)
mp.add_key_binding("END", "go_to_last_frame", go_to_last_frame)


-- Jump between saved clip points
-- Changed from v/V to ALT+v/ALT+V to avoid overriding frame-jump bindings.
function jump_to_clip_point(direction)
	local pos = mp.get_property_number("time-pos", 0)

	if #clip_points == 0 then
		mp.osd_message("No clip points set")
		return
	end

	local index = nil

	if direction == "next" then
		for i, pt in ipairs(clip_points) do
			if pt > pos then
				index = i
				break
			end
		end

		if not index then
			index = 1
		end
	elseif direction == "prev" then
		for i = #clip_points, 1, -1 do
			if clip_points[i] < pos then
				index = i
				break
			end
		end

		if not index then
			index = #clip_points
		end
	end

	if index then
		mp.commandv("seek", clip_points[index], "absolute+exact")
		mp.osd_message(string.format(
			"Jumped to clip point [%d]: %.2f",
			index,
			clip_points[index]
		))
	end
end

mp.add_key_binding("ALT+v", "jump_next_clip_point", function()
	jump_to_clip_point("next")
end)

mp.add_key_binding("ALT+V", "jump_prev_clip_point", function()
	jump_to_clip_point("prev")
end)


-- Helpers for moving current file into a/b/c subfolders
local function ps_quote(s)
	return "'" .. tostring(s):gsub("'", "''") .. "'"
end

local function get_neighbor_file(current_dir, current_name)
	local files = utils.readdir(current_dir, "files") or {}
	table.sort(files)

	for i, fname in ipairs(files) do
		if fname == current_name then
			local next_file = files[i + 1] or files[i - 1]

			if next_file then
				return utils.join_path(current_dir, next_file)
			end

			return nil
		end
	end

	return nil
end

function move_current_file_to_folder(folder_name)
	local path = mp.get_property("path")

	if not path then
		mp.osd_message("No file loaded")
		return
	end

	local dir, name = utils.split_path(path)
	local target_dir = utils.join_path(dir, folder_name)
	local target_path = utils.join_path(target_dir, name)
	local neighbor = get_neighbor_file(dir, name)

	-- Load another file first so Windows releases the current video file handle.
	if neighbor then
		mp.commandv("loadfile", neighbor, "replace")
	else
		mp.commandv("stop")
	end

	mp.add_timeout(0.75, function()
		local command = table.concat({
			"$ErrorActionPreference = 'Stop';",
			"$src =", ps_quote(path), ";",
			"$dstDir =", ps_quote(target_dir), ";",
			"$dst =", ps_quote(target_path), ";",

			-- NOTE: New-Item uses -Path here, not -LiteralPath.
			"if (!(Test-Path -LiteralPath $dstDir)) {",
			"New-Item -ItemType Directory -Force -Path $dstDir | Out-Null;",
			"}",

			"if (Test-Path -LiteralPath $dst) {",
			"throw 'Target file already exists';",
			"}",

			"Move-Item -LiteralPath $src -Destination $dst;"
		}, " ")

		local result = utils.subprocess({
			args = {
				"powershell",
				"-NoProfile",
				"-ExecutionPolicy",
				"Bypass",
				"-Command",
				command
			},
			cancellable = false
		})

		if result.status == 0 then
			mp.osd_message("Moved to folder " .. folder_name)
			msg.info("Moved file to: " .. target_path)
		else
			mp.osd_message("Failed to move to folder " .. folder_name)
			msg.error("Move failed stdout: " .. tostring(result.stdout))
			msg.error("Move failed stderr: " .. tostring(result.stderr))
			msg.error("Move failed error: " .. tostring(result.error))
		end
	end)
end

-- Disabled by default: easy to mash by accident and these MOVE files on disk.
-- Uncomment to re-enable, or rebind to something less reachable.
-- mp.add_key_binding("ALT+a", "move_file_to_folder_a", function()
-- 	move_current_file_to_folder("a")
-- end)
--
-- mp.add_key_binding("ALT+b", "move_file_to_folder_b", function()
-- 	move_current_file_to_folder("b")
-- end)
--
-- mp.add_key_binding("ALT+c", "move_file_to_folder_c", function()
-- 	move_current_file_to_folder("c")
-- end)

