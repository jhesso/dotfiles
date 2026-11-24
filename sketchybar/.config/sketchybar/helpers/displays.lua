-- Display helpers shared by items.
--
-- AeroSpace and SketchyBar number the screens differently:
--   AeroSpace  %{monitor-appkit-nsscreen-screens-id} = index in macOS NSScreen.screens
--   SketchyBar `display` / "arrangement-id"            = SketchyBar's own order
-- With 2 screens they happened to match; with 3 (DisplayLink) they don't.
-- This module matches the two lists by screen position/size, and also lists
-- the landscape displays (so wide modules can skip portrait screens).

local M = {
	ns_to_sb = {}, -- NSScreen index -> SketchyBar arrangement-id
	landscape = "active", -- e.g. "1,3": SketchyBar ids of non-portrait displays
}

-- NSScreen frames, one per line: "<index> <x> <y> <w> <h>" (Cocoa coords, y up from main screen's bottom)
local NSSCREENS = [[osascript -l JavaScript -e 'ObjC.import("AppKit"); $.NSScreen.screens.js.map((s, i) => { const f = s.frame; return [i + 1, f.origin.x, f.origin.y, f.size.width, f.size.height].join(" ") }).join("\n")']]

local function parse_sb(result)
	if type(result) == "table" then
		local list = {}
		for _, d in ipairs(result) do
			local f = d.frame or {}
			list[#list + 1] = { id = d["arrangement-id"], x = f.x, y = f.y, w = f.w, h = f.h }
		end
		return list
	end
	-- fallback if the JSON arrives as a string
	local list = {}
	for id, x, y, w, h in tostring(result or ""):gmatch(
		'"arrangement%-id"%s*:%s*(%d+).-"x"%s*:%s*(%-?[%d%.]+).-"y"%s*:%s*(%-?[%d%.]+).-"w"%s*:%s*(%-?[%d%.]+).-"h"%s*:%s*(%-?[%d%.]+)'
	) do
		list[#list + 1] = { id = tonumber(id), x = tonumber(x), y = tonumber(y), w = tonumber(w), h = tonumber(h) }
	end
	return list
end

local function close(a, b)
	return a and b and math.abs(a - b) < 2
end

-- Re-read both screen lists, then call cb()
function M.refresh(cb)
	sbar.exec("sketchybar --query displays", function(sb_result)
		local sb = parse_sb(sb_result)
		sbar.exec(NSSCREENS, function(ns_out)
			local ns = {}
			for idx, x, y, w, h in tostring(ns_out or ""):gmatch("(%d+) (%-?[%d%.]+) (%-?[%d%.]+) (%-?[%d%.]+) (%-?[%d%.]+)") do
				ns[#ns + 1] = { idx = tonumber(idx), x = tonumber(x), y = tonumber(y), w = tonumber(w), h = tonumber(h) }
			end

			local map = {}
			local main_h = ns[1] and ns[1].h or 0 -- NSScreen.screens[1] is the main screen
			for _, n in ipairs(ns) do
				local top_y = main_h - (n.y + n.h) -- Cocoa (y up) -> SketchyBar/CG (y down)
				for _, d in ipairs(sb) do
					if close(n.x, d.x) and close(top_y, d.y) and close(n.w, d.w) and close(n.h, d.h) then
						map[n.idx] = d.id
					end
				end
			end
			M.ns_to_sb = map

			local wide = {}
			for _, d in ipairs(sb) do
				if d.w and d.h and d.w >= d.h then
					wide[#wide + 1] = tostring(d.id)
				end
			end
			M.landscape = #wide > 0 and table.concat(wide, ",") or "active"

			if cb then
				cb()
			end
		end)
	end)
end

-- SketchyBar display for an AeroSpace NSScreen index (falls back to the same number)
function M.sb_display(ns_index)
	return M.ns_to_sb[ns_index] or ns_index
end

return M
