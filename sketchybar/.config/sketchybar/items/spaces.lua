-- AeroSpace workspaces (replaces native macOS Spaces; old version: spaces.lua.native)
-- Updated via the `aerospace_workspace_change` event fired from aerospace.toml
local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")
local displays = require("helpers.displays")

local WORKSPACES = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" }
-- Always shown (matches persistent-workspaces in aerospace.toml); others only when occupied/focused
local PERSISTENT = { ["1"] = true, ["2"] = true, ["3"] = true, ["4"] = true, ["9"] = true, ["10"] = true }

sbar.add("event", "aerospace_workspace_change")

local spaces = {}
local brackets = {}
local paddings = {}
local hidden_by_menus = false

for _, ws in ipairs(WORKSPACES) do
	local space = sbar.add("item", "space." .. ws, {
		icon = {
			font = { family = settings.font.text, style = settings.font.style_map["Heavy"] },
			string = ws,
			padding_left = 15,
			padding_right = 8,
			color = colors.white,
			highlight_color = colors.orange,
		},
		label = {
			padding_right = 20,
			color = colors.white,
			highlight_color = colors.sora.primary,
			font = "sketchybar-app-font:Regular:16.0",
			y_offset = -1,
			string = " —",
		},
		padding_right = 1,
		padding_left = 1,
		background = {
			color = colors.bar.bg,
			border_width = 2,
			height = 28,
			border_color = colors.black,
		},
		click_script = "aerospace workspace " .. ws,
	})
	spaces[ws] = space

	-- Single item bracket for space items to achieve double border on highlight
	brackets[ws] = sbar.add("bracket", "space.bracket." .. ws, { space.name }, {
		background = {
			color = colors.transparent,
			border_color = colors.bg2,
			height = 30,
			border_width = 2,
		},
	})

	paddings[ws] = sbar.add("item", "space.padding." .. ws, {
		width = settings.group_paddings,
	})
end

local function icon_line_for(apps)
	if not apps or #apps == 0 then
		return " —"
	end
	local line = ""
	for _, app in ipairs(apps) do
		local icon = app_icons[app] or app_icons["default"]
		line = line .. " " .. icon
	end
	return line
end

local function update()
	sbar.exec("aerospace list-workspaces --focused", function(focused_out)
		local focused = (focused_out or ""):match("%S+")
		sbar.exec("aerospace list-windows --all --format '%{workspace}|%{app-name}'", function(win_out)
			-- workspace -> ordered, de-duplicated app list
			local apps, seen = {}, {}
			for line in (win_out or ""):gmatch("[^\r\n]+") do
				local ws, app = line:match("^(.-)|(.*)$")
				if ws and app and app ~= "" then
					apps[ws] = apps[ws] or {}
					seen[ws] = seen[ws] or {}
					if not seen[ws][app] then
						seen[ws][app] = true
						table.insert(apps[ws], app)
					end
				end
			end

			sbar.exec(
				"aerospace list-workspaces --monitor all --format '%{workspace}|%{monitor-appkit-nsscreen-screens-id}'",
				function(mon_out)
					local display = {}
					for line in (mon_out or ""):gmatch("[^\r\n]+") do
						local ws, id = line:match("^(.-)|(%d+)")
						if ws then
							-- AeroSpace's screen number -> SketchyBar's display number
							display[ws] = displays.sb_display(tonumber(id))
						end
					end

					sbar.animate("tanh", 10, function()
						for _, ws in ipairs(WORKSPACES) do
							local selected = ws == focused
							local occupied = apps[ws] ~= nil
							local visible = (PERSISTENT[ws] or occupied or selected) and not hidden_by_menus
							local d = display[ws] or "active"

							spaces[ws]:set({
								drawing = visible,
								display = d,
								icon = { highlight = selected },
								label = { string = icon_line_for(apps[ws]), highlight = selected },
								background = { border_color = selected and colors.highlight or colors.bar.bg },
							})
							brackets[ws]:set({
								drawing = visible,
								background = { border_color = selected and colors.grey or colors.bg2 },
							})
							paddings[ws]:set({ drawing = visible, display = d })
						end
					end)
				end
			)
		end)
	end)
end

-- Hidden observer that refreshes on anything that can change workspace contents
local observer = sbar.add("item", { drawing = false, updates = true })
observer:subscribe({
	"aerospace_workspace_change",
	"front_app_switched",
	"space_windows_change",
}, update)
-- Screens may have changed: re-match AeroSpace and SketchyBar screen numbers first
observer:subscribe({ "display_change", "system_woke", "forced" }, function()
	displays.refresh(update)
end)

local spaces_indicator = sbar.add("item", {
	padding_left = -3,
	padding_right = 0,
	icon = {
		padding_left = 8,
		padding_right = 9,
		color = colors.grey,
		string = icons.switch.on,
	},
	label = {
		width = 0,
		padding_left = 0,
		padding_right = 8,
		string = "Spaces",
		color = colors.bg1,
	},
	background = {
		color = colors.with_alpha(colors.grey, 0.0),
		border_color = colors.with_alpha(colors.bg1, 0.0),
	},
})

spaces_indicator:subscribe("swap_menus_and_spaces", function(env)
	local currently_on = spaces_indicator:query().icon.value == icons.switch.on
	spaces_indicator:set({
		icon = currently_on and icons.switch.off or icons.switch.on,
	})
	-- menus.lua toggles every /space\..*/ item; re-apply our own visibility rules on top
	hidden_by_menus = currently_on
	update()
end)

spaces_indicator:subscribe("mouse.entered", function(env)
	sbar.animate("tanh", 30, function()
		spaces_indicator:set({
			background = {
				color = { alpha = 1.0 },
				border_color = { alpha = 1.0 },
			},
			icon = { color = colors.bg1 },
			label = { width = "dynamic" },
		})
	end)
end)

spaces_indicator:subscribe("mouse.exited", function(env)
	sbar.animate("tanh", 30, function()
		spaces_indicator:set({
			background = {
				color = { alpha = 0.0 },
				border_color = { alpha = 0.0 },
			},
			icon = { color = colors.grey },
			label = { width = 0 },
		})
	end)
end)

spaces_indicator:subscribe("mouse.clicked", function(env)
	sbar.trigger("swap_menus_and_spaces")
end)

displays.refresh(update)
