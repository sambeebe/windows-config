-- ~/.config/wezterm/wezterm.lua
local wezterm = require("wezterm")
local config = wezterm.config_builder and wezterm.config_builder() or {}

-- Appearance
-- config.color_scheme = "Catppuccin Mocha"
-- config.font = wezterm.font("JetBrains Mono")
config.font_size = 15.0
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.95
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true

-- Behavior
config.scrollback_lines = 10003
config.enable_scroll_bar = false
config.audible_bell = "Disabled"
-- No desktop toasts: neither from programs (OSC 9 / OSC 777) nor from
-- WezTerm's own update checker.
config.notification_handling = "NeverShow"
config.check_for_updates = false
config.default_prog = { "/usr/bin/zsh" }

-- Keybindings
config.keys = {
	-- Split panes
	{ key = "d", mods = "ALT|SHIFT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "D", mods = "CTRL|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "w", mods = "CTRL|SHIFT", action = wezterm.action.CloseCurrentPane({ confirm = false }) },

	-- Pane navigation
	{ key = "h", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Left") },
	{ key = "l", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Right") },
	{ key = "k", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Up") },
	{ key = "j", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Down") },

	-- Pane resize. WezTerm's default is CTRL|SHIFT|ALT+Arrow, but GNOME grabs
	-- that for move-to-workspace-{left,right,up,down} so it never reaches us.
	-- Step of 3 rather than the default 1 — one cell per press is unusably slow.
	{ key = "H", mods = "ALT|SHIFT", action = wezterm.action.AdjustPaneSize({ "Left", 3 }) },
	{ key = "L", mods = "ALT|SHIFT", action = wezterm.action.AdjustPaneSize({ "Right", 3 }) },
	{ key = "K", mods = "ALT|SHIFT", action = wezterm.action.AdjustPaneSize({ "Up", 3 }) },
	{ key = "J", mods = "ALT|SHIFT", action = wezterm.action.AdjustPaneSize({ "Down", 3 }) },

	-- Font size
	{ key = "+", mods = "CTRL", action = wezterm.action.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = wezterm.action.DecreaseFontSize },
	{ key = "3", mods = "CTRL", action = wezterm.action.ResetFontSize },
	-- Ctrl+C: Copy when text is selected, otherwise send SIGINT
	{
		key = "c",
		mods = "CTRL",
		action = wezterm.action_callback(function(window, pane)
			local has_selection = window:get_selection_text_for_pane(pane) ~= ""
			if has_selection then
				window:perform_action(wezterm.action.CopyTo("Clipboard"), pane)
			else
				window:perform_action(wezterm.action.SendKey({ key = "c", mods = "CTRL" }), pane)
			end
		end),
	},
	-- Ctrl+V to paste
	{
		key = "v",
		mods = "CTRL",
		action = wezterm.action.PasteFrom("Clipboard"),
	},

	-- Selection keys: forward standard xterm escape sequences to the shell
	-- (overrides WezTerm defaults like Ctrl+Shift+Arrow = tab nav)
	{ key = "LeftArrow",  mods = "SHIFT",      action = wezterm.action.SendString("\x1b[1;2D") },
	{ key = "RightArrow", mods = "SHIFT",      action = wezterm.action.SendString("\x1b[1;2C") },
	{ key = "LeftArrow",  mods = "CTRL|SHIFT", action = wezterm.action.SendString("\x1b[1;6D") },
	{ key = "RightArrow", mods = "CTRL|SHIFT", action = wezterm.action.SendString("\x1b[1;6C") },
	{ key = "Home",       mods = "SHIFT",      action = wezterm.action.SendString("\x1b[1;2H") },
	{ key = "End",        mods = "SHIFT",      action = wezterm.action.SendString("\x1b[1;2F") },
}

-- -- Mouse bindings
-- config.mouse_bindings = {
-- 	{
-- 		event = { Up = { streak = 4, button = "Left" } },
-- 		mods = "NONE",
-- 		action = wezterm.action.CompleteSelection("ClipboardAndPrimarySelection"),
-- 	},
-- }

return config
