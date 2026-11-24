local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local battery = sbar.add("item", "widgets.battery", {
	position = "right",
	icon = {
		padding_left = settings.module_padding,
		string = icons.battery._100,
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
	update_freq = 120,
})

battery:subscribe({ "routine", "forced", "power_source_change", "system_woke" }, function(env)
	sbar.exec("pmset -g batt", function(batt_info)
		local found, _, charge = batt_info:find("(%d+)%%")
		if not found then
			return
		end
		charge = tonumber(charge)

		local charging = batt_info:find("AC Power") ~= nil

		local icon = icons.battery._0
		local color = colors.semantic.error
		if charging then
			icon = icons.battery.charging
			color = colors.semantic.ok
		else
			if charge > 80 then
				icon = icons.battery._100
				color = colors.sora.sage
			elseif charge > 60 then
				icon = icons.battery._75
				color = colors.sora.sage
			elseif charge > 40 then
				icon = icons.battery._50
				color = colors.sora.gold
			elseif charge > 20 then
				icon = icons.battery._25
				color = colors.semantic.warn
			end
		end

		battery:set({
			icon = { string = icon, color = color },
			label = { string = charge .. "%", color = color },
		})
	end)
end)

battery:subscribe("mouse.clicked", function(env)
	sbar.exec("open x-apple.systempreferences:com.apple.Battery-Settings.extension")
end)

sbar.add("bracket", "widgets.battery.bracket", { battery.name }, {
	background = { color = colors.bar.bg },
})

sbar.add("item", "widgets.battery.padding", {
	position = "right",
	width = settings.group_paddings,
})
