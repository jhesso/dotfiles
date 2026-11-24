require("items.apple")
require("items.menus")
require("items.spaces")
require("items.front_app")

-- The date/time and the right-side modules are too wide for a portrait screen,
-- so they are only drawn on landscape displays. Record every item they create...
local displays = require("helpers.displays")
local wide_items = {}
local sbar_add = sbar.add
sbar.add = function(kind, ...)
	local item = sbar_add(kind, ...)
	local args = { ... }
	local props = args[#args]
	local in_popup = type(props) == "table" and type(props.position) == "string" and props.position:match("^popup%.")
	if kind ~= "event" and kind ~= "bracket" and not in_popup and item and item.name then
		wide_items[#wide_items + 1] = item.name
	end
	return item
end

require("items.calendar")
require("items.widgets")

sbar.add = sbar_add

-- ...and keep them on the landscape displays, also when screens change
local function place_wide_items()
	for _, name in ipairs(wide_items) do
		sbar.set(name, { display = displays.landscape })
	end
end
local display_watch = sbar_add("item", "displays.watch", { drawing = false, updates = true })
display_watch:subscribe({ "display_change", "system_woke", "forced" }, function()
	displays.refresh(place_wide_items)
end)
displays.refresh(place_wide_items)
