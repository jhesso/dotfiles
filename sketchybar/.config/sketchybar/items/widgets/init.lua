local settings = require("settings")

-- Edge padding: keeps the right-most module's border from being clipped by the
-- bar edge (the calendar used to provide this before it moved to the center)
sbar.add("item", "widgets.edge.padding", { position = "right", width = settings.group_paddings })

require("items.widgets.battery")
require("items.widgets.airpods")
require("items.widgets.volume")
require("items.widgets.bluetooth")
require("items.widgets.wifi")
require("items.widgets.ram")
require("items.widgets.cpu")
require("items.widgets.keyboard")
-- require("items.widgets.music")
