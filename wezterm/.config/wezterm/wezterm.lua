local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.automatically_reload_config = true
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "RESIZE"
config.enable_tab_bar = true
config.default_cursor_style = "BlinkingBar"
config.color_scheme = "Nord (Gogh)"
config.font_size = 24
config.font = wezterm.font("FiraMono Nerd Font", { weight = "Regular", stretch = "Normal", style = "Normal" })

config.background = {
	{
		source = {
			File = wezterm.home_dir .. "/.wp_assets/wp2.jpg",
		},
		hsb = {
			hue = 1.0,
			saturation = 1.02,
			brightness = 0.25,
		},
	},
	{
		source = {
			Color = "#282c35",
		},
		opacity = 0.55,
	},
}

config.window_padding = {
	top = 0,
	bottom = 0,
	left = 3,
	right = 3,
}

config.default_prog = { "/bin/zsh", "-l" }

config.enable_scroll_bar = true
config.scrollback_lines = 10000

config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

config.adjust_window_size_when_changing_font_size = false
config.font_size = 14.0

config.inactive_pane_hsb = {
	saturation = 0.9,
	brightness = 0.7,
}

config.keys = {
	{ key = "v", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom("Clipboard") }, -- copy
	{ key = "c", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo("Clipboard") }, -- past
	{ key = "Enter", mods = "ALT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) }, -- horizontal split
	{ key = "Enter", mods = "CTRL|ALT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) }, -- vertical split
	{ key = "h", mods = "CTRL|ALT", action = wezterm.action.ActivatePaneDirection("Left") }, -- activate left window
	{ key = "l", mods = "CTRL|ALT", action = wezterm.action.ActivatePaneDirection("Right") }, -- activate right window
	{ key = "k", mods = "CTRL|ALT", action = wezterm.action.ActivatePaneDirection("Up") }, -- activate upper window
	{ key = "j", mods = "CTRL|ALT", action = wezterm.action.ActivatePaneDirection("Down") }, -- activate bottom window
	{ key = "n", mods = "CTRL|SHIFT", action = wezterm.action.SpawnTab("CurrentPaneDomain") }, -- open new tab
	{ key = "Tab", mods = "CTRL", action = wezterm.action.ActivateTabRelative(1) }, -- activate tab left
	{ key = "Tab", mods = "CTRL|SHIFT", action = wezterm.action.ActivateTabRelative(-1) }, -- activate tab right
	{ key = "x", mods = "CTRL|SHIFT", action = wezterm.action.CloseCurrentPane({ confirm = false }) }, -- close current tab
}

config.initial_cols = 120
config.initial_rows = 32

return config
