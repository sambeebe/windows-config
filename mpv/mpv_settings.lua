-- nextfile.lua
-- Navigate to next/previous file in the current directory without a playlist

local mp = require("mp")
local utils = require("mp.utils")

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

-- Jump by step (+1 for next, -1 for prev)
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
			end
			return
		end
	end
end

-- Bind keys (Ctrl+Left and Ctrl+Right)
mp.add_key_binding("CTRL+LEFT", "prev-file", function()
	jump(-1)
end)
mp.add_key_binding("CTRL+RIGHT", "next-file", function()
	jump(1)
end)

local msg = require("mp.msg")
local utils = require("mp.utils")

local start_time = nil
local end_time = nil

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

local mp = require("mp")
local utils = require("mp.utils")
local msg = require("mp.msg")

local clip_points = {}

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
	local dir, _ = utils.split_path(input_path)

	for i = 1, count - 1 do
		local start_time = clip_points[i]
		local end_time = clip_points[i + 1]

		if end_time <= start_time then
			msg.warn("Skipping invalid segment: " .. start_time .. " >= " .. end_time)
		else
			local duration = end_time - start_time
			local output_path = utils.join_path(dir, string.format("clip_%d_%d.mp4", start_time, end_time))

			local args = {
				"ffmpeg",
				"-ss",
				tostring(start_time),
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

-- Key bindings
mp.add_key_binding("a", "add_clip_point", add_clip_point)
mp.add_key_binding("t", "trim_clips", trim_clips)
mp.add_key_binding("r", "reset_clip_points", reset_clip_points)

function copy_path_to_clipboard()
	local path = mp.get_property("path")
	if not path then
		mp.osd_message("No file loaded")
		return
	end

	local args = {
		"powershell",
		"-NoProfile",
		"-Command",
		string.format("Set-Clipboard -Value '%s'", path),
	}

	local result = utils.subprocess({ args = args, cancellable = false })
	if result.status == 0 then
		mp.osd_message("Copied path to clipboard")
	else
		mp.osd_message("Failed to copy to clipboard")
		msg.error("Clipboard copy failed: " .. (result.error or "unknown"))
	end
end

mp.add_key_binding("c", "copy_path_to_clipboard", copy_path_to_clipboard)

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
		msg.error("Explorer command failed: " .. (result.error or "unknown"))
	end
end

mp.add_key_binding("o", "open_in_explorer", open_in_explorer)

function jump_n_frames(n, backward)
	local fps = mp.get_property_number("container-fps")
	if not fps or fps <= 0 then
		mp.osd_message("FPS not available")
		return
	end

	local direction = backward and -1 or 1
	local jump = direction * (n / fps)

	mp.commandv("seek", jump, "relative+exact")
	mp.osd_message(string.format("Jumped %s %d frames", backward and "back" or "ahead", n))
end

function jump_n_frames(n, backward)
	local fps = mp.get_property_number("container-fps")
	if not fps or fps <= 0 then
		mp.osd_message("FPS not available")
		return
	end

	local direction = backward and -1 or 1
	local jump = direction * (n / fps)

	mp.commandv("seek", jump, "relative+exact")
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
		end -- loop around
	elseif direction == "prev" then
		for i = #clip_points, 1, -1 do
			if clip_points[i] < pos then
				index = i
				break
			end
		end
		if not index then
			index = #clip_points
		end -- loop around
	end

	if index then
		mp.commandv("seek", clip_points[index], "absolute+exact")
		mp.osd_message(string.format("Jumped to clip point [%d]: %.2f", index, clip_points[index]))
	end
end

mp.add_key_binding("v", "jump_next_clip_point", function()
	jump_to_clip_point("next")
end)

mp.add_key_binding("V", "jump_prev_clip_point", function()
	jump_to_clip_point("prev")
end)
