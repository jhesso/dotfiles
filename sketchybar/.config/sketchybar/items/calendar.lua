local settings = require("settings")
local colors = require("colors")

-- Date + time, centered in the bar (date on the left, time on the right).
-- Center items are drawn left-to-right in the order they are added.

local cal = sbar.add("item", {
	icon = {
		string = "􀉉",
		color = colors.sora.steel,
		padding_left = 8,
		font = {
			style = settings.font.style_map["Bold"],
			size = 14.0,
		},
	},
	label = {
		color = colors.sora.steel,
		padding_right = 8,
		font = {
			style = settings.font.style_map["Bold"],
			size = 12.0,
		},
	},
	position = "center",
	update_freq = 30,
	padding_left = 1,
	padding_right = 1,
	background = {
		color = colors.bar.bg,
		border_width = 2,
	},
})

sbar.add("item", { position = "center", width = settings.group_paddings })

local clock = sbar.add("item", {
	icon = {
		string = "􀐫",
		color = colors.sora.primary,
		padding_left = 8,
		font = {
			style = settings.font.style_map["Bold"],
			size = 14.0,
		},
	},
	label = {
		color = colors.sora.primary,
		padding_right = 8,
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 13.0,
		},
	},
	position = "center",
	update_freq = 1,
	padding_left = 1,
	padding_right = 1,
	background = {
		color = colors.bar.bg,
		border_width = 2,
	},
})

-- Double border for clock
sbar.add("bracket", { clock.name }, {
	background = {
		color = colors.transparent,
		height = 26,
		border_color = colors.bg2,
	},
})

-- Double border for calendar
sbar.add("bracket", { cal.name }, {
	background = {
		color = colors.transparent,
		height = 26,
		border_color = colors.bg2,
	},
})

clock:subscribe({ "forced", "routine", "system_woke" }, function(env)
	clock:set({ label = os.date("%H:%M") })
end)

cal:subscribe({ "forced", "routine", "system_woke" }, function(env)
	cal:set({ label = os.date("%a. %d %b.") })
end)

-- ── Month popup (left-click the date) ────────────────────────────────────────
-- Simple month grid, weeks start on Monday, ISO week numbers on the left,
-- today in red. Rows are lines of Menlo (monospaced, ships with macOS) with
-- fixed pixel widths, so the columns line up.
--
-- Note: in SketchyBar a fixed `width` is the whole box INCLUDING the padding;
-- the text starts `padding_left` px into that box.
--
-- An item only has two text parts (icon + label), so today's row is built as:
--   icon  = "wk  dd dd    dd dd" (today's number blanked out)
--   label = today's number in red, pulled left onto the blank with a negative padding

local CAL_FONT = "Menlo:Bold:13.0"
local CW = 13.0 * 1233 / 2048 -- Menlo character width in px
local CELL = 24 -- popup row height
local PAD = 12 -- outer padding left/right
local WK_W = math.floor(2 * CW + 0.5) -- week number column
local GAP = math.floor(2 * CW + 0.5) -- gap between week number and Monday
local DAYS_W = math.floor(20 * CW + 0.5) -- "dd dd dd dd dd dd dd"
local ROW_W = PAD + WK_W + GAP + DAYS_W + PAD

local function px(chars)
	return math.floor(chars * CW + 0.5)
end

cal:set({ popup = { align = "center", height = CELL } })

local function add_row(name, week, days, week_color)
	sbar.add("item", "calendar.popup." .. name, {
		position = "popup." .. cal.name,
		padding_left = 0,
		padding_right = 0,
		icon = {
			string = week,
			font = CAL_FONT,
			color = week_color,
			width = PAD + WK_W,
			padding_left = PAD,
			padding_right = 0,
		},
		label = {
			string = days,
			font = CAL_FONT,
			color = week_color == colors.grey and colors.grey or colors.white,
			width = GAP + DAYS_W + PAD,
			padding_left = GAP,
			padding_right = 0,
		},
	})
end

local function add_today_row(name, week, days_blanked, col, day)
	local icon_w = px(4 + 20) -- "wk  " + days
	local today_x = PAD + px(4 + col * 3) -- where today's number starts
	local label_pl = today_x - (PAD + icon_w) -- negative: pulls the number back left
	sbar.add("item", "calendar.popup." .. name, {
		position = "popup." .. cal.name,
		padding_left = 0,
		padding_right = 0,
		icon = {
			string = week .. "  " .. days_blanked,
			font = CAL_FONT,
			color = colors.white,
			width = PAD + icon_w,
			padding_left = PAD,
			padding_right = 0,
		},
		label = {
			string = string.format("%2d", day),
			font = CAL_FONT,
			color = colors.red,
			width = ROW_W - (PAD + icon_w), -- rest of the row, so every row is ROW_W wide
			padding_left = label_pl,
			padding_right = 0,
		},
	})
end

local function build_month()
	sbar.remove("/calendar\\.popup\\..*/")

	local now = os.date("*t")
	local first = os.time({ year = now.year, month = now.month, day = 1, hour = 12 })
	local days_in_month = os.date("*t", os.time({ year = now.year, month = now.month + 1, day = 0, hour = 12 })).day
	local offset = (os.date("*t", first).wday + 5) % 7 -- 0 = Monday ... 6 = Sunday

	-- Month title
	sbar.add("item", "calendar.popup.title", {
		position = "popup." .. cal.name,
		width = ROW_W,
		align = "center",
		icon = { drawing = false },
		label = {
			string = os.date("%B %Y"),
			color = colors.sora.primary,
			font = { style = settings.font.style_map["Bold"], size = 14.0 },
		},
	})

	add_row("header", "Wk", "Mo Tu We Th Fr Sa Su", colors.grey)

	local rows = 0
	local day = 1 - offset
	while day <= days_in_month do
		local cells, today_col = {}, nil
		local week_no = os.date("%V", os.time({ year = now.year, month = now.month, day = math.max(day, 1), hour = 12 }))
		week_no = string.format("%2d", tonumber(week_no))
		for col = 0, 6 do
			local d = day + col
			if d >= 1 and d <= days_in_month then
				if d == now.day then
					today_col = col
					cells[#cells + 1] = "  "
				else
					cells[#cells + 1] = string.format("%2d", d)
				end
			else
				cells[#cells + 1] = "  "
			end
		end
		rows = rows + 1
		if today_col then
			add_today_row("week" .. rows, week_no, table.concat(cells, " "), today_col, now.day)
		else
			add_row("week" .. rows, week_no, table.concat(cells, " "), colors.sora.steel)
		end
		day = day + 7
	end
end

-- Track open/closed ourselves: querying the item has no popup info while the
-- popup is empty, which is the case before the first open.
local month_open = false

local function close_month()
	month_open = false
	cal:set({ popup = { drawing = false } })
	sbar.remove("/calendar\\.popup\\..*/")
end

cal:subscribe("mouse.clicked", function(env)
	if month_open then
		close_month()
	else
		build_month()
		month_open = true
		cal:set({ popup = { drawing = true } })
	end
end)

cal:subscribe("mouse.exited.global", close_month)
