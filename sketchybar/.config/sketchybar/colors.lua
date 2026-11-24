local themes = {
	sora = {
		black = 0xff0e1018,
		white = 0xffc8d0e0,
		red = 0xffc46c78,
		green = 0xff90c8a0,
		blue = 0xff80c8e0,
		yellow = 0xffd4b878,
		orange = 0xffd0a888,
		magenta = 0xffb0a0d8,
		grey = 0xff586478,
		shadow = 0xff0a0c12,

		-- accent set (exposed as colors.sora.*)
		accent = {
			cyan = 0xff80c8e0,
			purple = 0xffb0a0d8,
			sage = 0xff90c8a0,
			rose = 0xffd0909c,
			gold = 0xffd4b878,
			peach = 0xffd0a888,
			teal = 0xff78b8b0,
			steel = 0xff8898b8,
			-- the bar's own accent: apple, clock, active space, default icon
			primary = 0xff80c8e0,
		},

		-- status, not syntax: thresholds and failures only. warn must not be
		-- gold, the cran below it in the cpu/ram ramp.
		semantic = {
			error = 0xffc46c78,
			warn = 0xffd0a888,
			ok = 0xff90c8a0,
			info = 0xff80c8e0,
		},

		highlight = 0xff8898b8,
		bar = { bg = 0xcc0e1018, border = 0xff222838 },
		popup = { bg = 0xc014161e, border = 0xff586478 },
		bg1 = 0xff1e2430,
		bg2 = 0xff222838,
	},
}

local t = themes.sora

return {
	black = t.black,
	white = t.white,
	red = t.red,
	green = t.green,
	blue = t.blue,
	yellow = t.yellow,
	orange = t.orange,
	magenta = t.magenta,
	grey = t.grey,
	shadow = t.shadow,
	transparent = 0x00000000,

	sora = t.accent,
	semantic = t.semantic,
	highlight = t.highlight,
	bar = t.bar,
	popup = t.popup,
	bg1 = t.bg1,
	bg2 = t.bg2,

	with_alpha = function(color, alpha)
		if alpha > 1.0 or alpha < 0.0 then
			return color
		end
		return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
	end,
}
