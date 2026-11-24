-- Bluetooth: click for a popup of paired devices; click a device to connect /
-- disconnect it. The header row turns Bluetooth on/off. Right-click opens
-- the Bluetooth settings. Needs `blueutil` (brew install blueutil).
local colors = require("colors")
local settings = require("settings")

local blueutil = "/opt/homebrew/bin/blueutil"
local popup_width = 250
local NAME_CHARS = 14 -- device names longer than this are cut (full name shows on hover)

sbar.add("event", "bluetooth_update")

local bluetooth = sbar.add("item", "widgets.bluetooth", {
	position = "right",
	icon = {
		-- No SF Symbol exists for Bluetooth; use the Nerd Font glyph (nf-md-bluetooth)
		string = "\u{F00AF}",
		font = "MonaspiceNe Nerd Font:Regular:16.0",
		color = colors.grey,
		padding_left = settings.module_padding,
		padding_right = settings.module_padding,
	},
	label = {
		drawing = false,
		color = colors.sora.primary,
		padding_left = 0,
		padding_right = settings.module_padding,
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 13.0,
		},
	},
	padding_right = 1,
	padding_left = 1,
	update_freq = 30,
	popup = { align = "center" },
})

sbar.add("bracket", "widgets.bluetooth.bracket", { bluetooth.name }, {
	background = { color = colors.bar.bg },
})

sbar.add("item", "widgets.bluetooth.padding", {
	position = "right",
	width = settings.group_paddings,
})

-- `blueutil --format json` output: sbar.exec hands it over already parsed into a
-- table; fall back to pattern matching if it arrives as a string.
local function parse_devices(result)
	if type(result) == "table" then
		return result
	end
	local devices = {}
	for obj in tostring(result or ""):gmatch("{(.-)}") do
		local address = obj:match('"address"%s*:%s*"(.-)"')
		if address then
			table.insert(devices, {
				address = address,
				name = obj:match('"name"%s*:%s*"(.-)"') or address,
				connected = obj:match('"connected"%s*:%s*true') ~= nil,
			})
		end
	end
	return devices
end

-- Show the number of connected devices next to the glyph (hidden when 0).
-- The icon's right padding shrinks while the number is shown, so the total
-- padding around the module stays the same.
local function set_count(count, color)
	local show = count > 0
	bluetooth:set({
		icon = { color = color, padding_right = show and 6 or settings.module_padding },
		label = { drawing = show, string = tostring(count) },
	})
end

-- Bar icon: cyan when something is connected, grey when not, red when Bluetooth is off
local function update_icon()
	sbar.exec(blueutil .. " -p", function(power)
		if tostring(power):match("^%s*0") then
			set_count(0, colors.semantic.error)
			return
		end
		sbar.exec(blueutil .. " --connected --format json", function(result)
			local count = #parse_devices(result)
			set_count(count, count > 0 and colors.sora.primary or colors.grey)
		end)
	end)
end

local header = sbar.add("item", "widgets.bluetooth.header", {
	position = "popup." .. bluetooth.name,
	width = popup_width,
	align = "center",
	icon = { drawing = false },
	label = { string = "Loading…", color = colors.grey },
	background = { height = 2, color = colors.grey, y_offset = -15 },
	click_script = blueutil .. " -p toggle; sleep 1; sketchybar --trigger bluetooth_update",
})

local function render_popup()
	sbar.remove("/bluetooth.device\\.*/")
	header:set({ label = { string = "Loading…", color = colors.grey } })
	sbar.exec(blueutil .. " -p 2>&1", function(power)
		power = tostring(power or "")
		if not power:match("^%s*[01]") then
			-- blueutil missing, or macOS has not granted Bluetooth access
			header:set({ label = { string = "blueutil failed: " .. power:sub(1, 40), color = colors.semantic.error } })
			return
		end
		local on = power:match("^%s*1") ~= nil
		header:set({
			label = {
				string = on and "Bluetooth on  ·  click to turn off" or "Bluetooth off  ·  click to turn on",
				color = on and colors.sora.primary or colors.semantic.error,
			},
		})

		if not on then
			return
		end

		sbar.exec(blueutil .. " --paired --format json", function(result)
			for i, dev in ipairs(parse_devices(result)) do
				local action = dev.connected and "--disconnect" or "--connect"
				local busy = dev.connected and "Disconnecting…" or "Connecting…"
				local row = sbar.add("item", "bluetooth.device." .. i, {
					position = "popup." .. bluetooth.name,
					width = popup_width,
					icon = {
						string = dev.name,
						color = dev.connected and colors.white or colors.grey,
						width = popup_width * 0.5,
						max_chars = NAME_CHARS, -- long names are cut to fit the left half
						align = "left",
					},
					scroll_texts = false,
					label = {
						string = dev.connected and "Connected" or "Connect",
						color = dev.connected and colors.sora.sage or colors.sora.primary,
						width = popup_width * 0.5,
						align = "right",
					},
					-- show the status again while (dis)connecting, even though the row is hovered
					click_script = 'sketchybar --set $NAME label="'
						.. busy
						.. '" label.drawing=on icon.max_chars='
						.. NAME_CHARS
						.. " icon.width="
						.. math.floor(popup_width * 0.5)
						.. "; "
						.. blueutil
						.. " "
						.. action
						.. " "
						.. dev.address
						.. "; sketchybar --trigger bluetooth_update",
				})

				-- Hover: hide the status and let the name use the whole row
				row:subscribe("mouse.entered", function()
					row:set({ icon = { max_chars = 0, width = popup_width }, label = { drawing = false } })
				end)
				row:subscribe("mouse.exited", function()
					row:set({ icon = { max_chars = NAME_CHARS, width = popup_width * 0.5 }, label = { drawing = true } })
				end)
			end
		end)
	end)
end

local function popup_open()
	return bluetooth:query().popup.drawing == "on"
end

local function close_popup()
	bluetooth:set({ popup = { drawing = false } })
	sbar.remove("/bluetooth.device\\.*/")
end

bluetooth:subscribe({ "routine", "forced", "system_woke" }, update_icon)

bluetooth:subscribe("bluetooth_update", function()
	update_icon()
	if popup_open() then
		render_popup()
	end
end)

bluetooth:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "right" then
		sbar.exec("open 'x-apple.systempreferences:com.apple.BluetoothSettings'")
		return
	end
	if popup_open() then
		close_popup()
	else
		bluetooth:set({ popup = { drawing = true } })
		render_popup()
	end
end)

bluetooth:subscribe("mouse.exited.global", close_popup)
