-- Avatar color
avatar:color(vectors.hexToRGB("FDCD6B"))

-- Host only instructions
if not host:isHost() then return end

-- Table setup
local colors = {}

-- Action variables
colors.hover     = vectors.hexToRGB("FDCD6B")
colors.active    = vectors.hexToRGB("DB8049")
colors.primary   = "#FDCD6B"
colors.secondary = "#DB8049"

-- Return variables
return colors