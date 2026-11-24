-- AirPods battery (lowest bud). Hidden when no AirPods are connected.
-- Click to toggle a popup with left / right / case levels.
local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local script = "/bin/bash " .. os.getenv("HOME") .. "/.config/sketchybar/helpers/airpods.sh"

local airpods = sbar.add("item", "widgets.airpods", {
	position = "right",
	drawing = false,
	icon = {
		padding_left = settings.module_padding,
		string = icons.airpods,
		color = colors.sora.sage,
		font = {
			style = settings.font.style_map["Regular"],
			size = 14.0,
		},
	},
	label = {
		padding_right = settings.module_padding,
		string = "??%",
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 13.0,
		},
		width = 42 + settings.module_padding, -- a fixed width includes the padding
	},
	padding_right = 1,
	padding_left = 1,
	update_freq = 30,
	-- Keep polling while hidden (default "when_shown" would never re-show it)
	updates = true,
	popup = { align = "center" },
})

local detail = sbar.add("item", "widgets.airpods.detail", {
	position = "popup." .. airpods.name,
	icon = { drawing = false },
	label = {
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 13.0,
		},
		padding_left = 10,
		padding_right = 10,
	},
})

local bracket = sbar.add("bracket", "widgets.airpods.bracket", { airpods.name }, {
	drawing = false,
	background = { color = colors.bar.bg },
})

local padding = sbar.add("item", "widgets.airpods.padding", {
	position = "right",
	drawing = false,
	width = settings.group_paddings,
})

local function color_for(level)
	if level > 60 then
		return colors.sora.sage
	elseif level > 40 then
		return colors.sora.gold
	elseif level > 20 then
		return colors.semantic.warn
	end
	return colors.semantic.error
end

local function show(visible)
	airpods:set({ drawing = visible })
	bracket:set({ drawing = visible })
	padding:set({ drawing = visible })
	if not visible then
		airpods:set({ popup = { drawing = false } })
	end
end

-- volume_change usually fires when audio switches to/from the AirPods -> faster pickup
airpods:subscribe({ "routine", "forced", "system_woke", "volume_change" }, function(env)
	sbar.exec(script, function(out)
		local l, r, k = (out or ""):match("^(%d*)|(%d*)|(%d*)")
		l, r, k = tonumber(l), tonumber(r), tonumber(k)

		-- Buds in the case / disconnected: hide
		if not l and not r then
			show(false)
			return
		end

		local lowest = math.min(l or 100, r or 100)
		local color = color_for(lowest)
		show(true)
		airpods:set({
			icon = { color = color },
			label = { string = lowest .. "%", color = color },
		})

		local function fmt(v)
			return v and (v .. "%") or "—"
		end
		detail:set({ label = { string = "L " .. fmt(l) .. "   R " .. fmt(r) .. "   Case " .. fmt(k) } })
	end)
end)

airpods:subscribe("mouse.clicked", function(env)
	airpods:set({ popup = { drawing = "toggle" } })
end)

airpods:subscribe("mouse.exited.global", function(env)
	airpods:set({ popup = { drawing = false } })
end)
