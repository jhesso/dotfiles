-- Current keyboard layout (US / FI ...). Updates instantly on layout switch via
-- the macOS distributed notification AppleSelectedInputSourcesChangedNotification.
local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Map macOS layout names to short labels; anything else -> first 2 letters
local SHORT = {
	["U.S."] = "US",
	["ABC"] = "US",
	["Finnish"] = "FI",
	["Finnish Extended"] = "FI",
	["Finnish Sámi-PC"] = "FI",
}

sbar.add("event", "input_source_change", "AppleSelectedInputSourcesChangedNotification")

local keyboard = sbar.add("item", "widgets.keyboard", {
	position = "right",
	icon = {
		padding_left = settings.module_padding,
		string = icons.keyboard,
		color = colors.sora.steel,
		font = {
			style = settings.font.style_map["Regular"],
			size = 15.0,
		},
	},
	label = {
		padding_right = settings.module_padding,
		string = "??",
		color = colors.white,
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 13.0,
		},
	},
	padding_right = 1,
	padding_left = 1,
})

local cmd = "defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources"
	.. " | awk -F' = ' '/KeyboardLayout Name/ {gsub(/[\";]/, \"\", $2); print $2; exit}'"

keyboard:subscribe({ "input_source_change", "forced", "system_woke" }, function(env)
	-- Give macOS a moment to write the new layout to its prefs
	sbar.delay(0.2, function()
		sbar.exec(cmd, function(name)
			name = (name or ""):gsub("%s+$", "")
			if name == "" then
				return
			end
			local short = SHORT[name] or name:sub(1, 2):upper()
			keyboard:set({ label = { string = short } })
		end)
	end)
end)

keyboard:subscribe("mouse.clicked", function(env)
	sbar.exec("open x-apple.systempreferences:com.apple.Keyboard-Settings.extension")
end)

sbar.add("bracket", "widgets.keyboard.bracket", { keyboard.name }, {
	background = { color = colors.bar.bg },
})

sbar.add("item", "widgets.keyboard.padding", {
	position = "right",
	width = settings.group_paddings,
})
