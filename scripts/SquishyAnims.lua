-- Kills script if squAPI cannot be found
local s, squapi = pcall(require, "lib.SquAPI")
if not s then return {} end

-- Required scripts
local parts   = require("lib.PartsAPI")
local sync    = require("lib.LetThatSyncFig")
local lerp    = require("lib.LerpAPI")
local ground  = require("lib.GroundCheck")
local pose    = require("scripts.Posing")
local effects = require("scripts.SyncedVariables")

-- Animation setup
local anims = animations.Giraffe

-- Synced variables setup
local earFlick = sync.new("AnimsEarFlicks", true):config()

-- Calculate parent's rotations
local function calculateParentRot(m)
	
	local parent = m:getParent()
	if not parent then
		return m:getOffsetRot()
	end
	return calculateParentRot(parent) + m:getOffsetRot()
	
end

-- Lerp table
local legLerp = lerp.new(1, 0.5)

-- Squishy ears
local ears = squapi.ear:new(
	parts.group.LeftEar,
	parts.group.RightEar,
	0,              -- Range Multiplier (0)
	false,          -- Horizontal (false)
	1,              -- Bend Strength (1)
	earFlick.curr, -- Do Flick (earFlick)
	400,            -- Flick Chance (400)
	0.05,           -- Stiffness (0.05)
	0.9             -- Bounce (0.9)
)

-- Tails table
local tailParts = {
	
	parts.group.Tail
	
}

-- Squishy tail
local tail = squapi.tail:new(
	tailParts,
	0,    -- Intensity X (0)
	0,    -- Intensity Y (0)
	0,    -- Speed X (0)
	0,    -- Speed Y (0)
	2,    -- Bend (2)
	1,    -- Velocity Push (1)
	0,    -- Initial Offset (0)
	0,    -- Seg Offset (0)
	0.01, -- Stiffness (0.01)
	0.9,  -- Bounce (0.9)
	60,   -- Fly Offset (60)
	-90,  -- Down Limit (-90)
	25    -- Up Limit (25)
)

-- Head table
local headParts = {
	
	parts.group.UpperBody,
	parts.group.Neck3,
	parts.group.Neck2,
	parts.group.Neck1
	
}

-- Squishy smooth torso
local head = squapi.smoothHead:new(
	headParts,
	1,  -- Strength (1)
	0.2,  -- Tilt (0.2)
	1,    -- Speed (1)
	false -- Keep Original Head Pos (false)
)

-- Head variable
local headStrength = head.strength[1] * #head.strength

-- Squishy vanilla legs
local frontLeftLeg = squapi.leg:new(
	parts.group.FrontLeftLeg,
	0.3,  -- Strength (0.25)
	false, -- Right Leg (false)
	false  -- Keep Position (false)
)

local frontRightLeg = squapi.leg:new(
	parts.group.FrontRightLeg,
	0.3, -- Strength (0.25)
	true, -- Right Leg (true)
	false -- Keep Position (false)
)

local backLeftLeg = squapi.leg:new(
	parts.group.BackLeftLeg,
	0.3, -- Strength (0.25)
	true, -- Right Leg (true)
	false -- Keep Position (false)
)

local backRightLeg = squapi.leg:new(
	parts.group.BackRightLeg,
	0.3,  -- Strength (0.25)
	false, -- Right Leg (false)
	false  -- Keep Position (false)
)

-- Leg strength variables
local frontLeftLegStrength  = frontLeftLeg.strength
local frontRightLegStrength = frontRightLeg.strength
local backLeftLegStrength   = backLeftLeg.strength
local backRightLegStrength  = backRightLeg.strength

-- Squishy taur
local taur = squapi.taur:new(
	parts.group.LowerBody,
	parts.group.FrontLegs,
	parts.group.BackLegs
)

-- Squishy crouch
squapi.crouch(anims.crouch)

function events.TICK()
	
	-- Variables
	local onGround = ground()
	local inWater  = player:isInWater()
	
	legLerp.target = (onGround or inWater or pose.elytra or effects.cF) and 1 or 0
	taur.target    = (onGround or player:getVehicle() or effects.cF) and 0 or taur.target
	
	-- Body lean overrides
	local bodyShouldBend = not (pose.crouch or pose.sleep)
	for i in ipairs(head.strength) do
		head.strength[i] = (headStrength / #head.strength) * (bodyShouldBend and 1 or 0)
	end
	
	-- Control ear flick based on variables
	ears.doEarFlick = earFlick.curr
	
end

function events.RENDER(delta, context)
	
	-- Adjust leg strengths
	frontLeftLeg.strength  = frontLeftLegStrength  * legLerp.currPos
	frontRightLeg.strength = frontRightLegStrength * legLerp.currPos
	backLeftLeg.strength   = backLeftLegStrength   * legLerp.currPos
	backRightLeg.strength  = backRightLegStrength  * legLerp.currPos
	
	parts.group.NeckPivot
		:rot(-parts.group.LowerBody:getRot())
	
	-- Offset smooth torso in various parts
	-- Note: acts strangely with `parts.group.body`
	for _, group in ipairs(parts.group.UpperBody:getChildren()) do
		if group ~= parts.group.Body then
			group:rot(-calculateParentRot(group:getParent()))
		end
	end
	
end

-- Host only instructions
if not host:isHost() then return end

-- Required scripts
local s, pageNav, acts, colors = pcall(require, "scripts.ActionWheel")
if not s then return end -- Kills script early if ActionWheel.lua isnt found
pcall(require, "scripts.Anims") -- Tries to find script, not required

-- Check for if page already exists
local pageExists = action_wheel:getPage("Anims")

-- Pages
local parentPage = action_wheel:getPage("Main")
local animsPage  = pageExists or action_wheel:newPage("Anims")

-- Actions
if not pageExists then
	acts.animsPage = parentPage:newAction()
		:item("jukebox")
		:onLeftClick(function() pageNav.descend(animsPage) end)
end

acts.animsEarsToggle = animsPage:newAction()
	:item("bone")
	:toggleItem("feather")
	:onToggle(function(bool)
		earFlick:update(bool)
	end)
	:toggled(earFlick.curr)

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		if acts.animsPage then
			acts.animsPage
				:title(toJson(
					{text = "Animation Settings", bold = true, color = colors.primary}
				))
				:hoverColor(colors.hover)
		end
		
		acts.animsEarsToggle
			:title(toJson(
				{
					"",
					{text = "Ear Flick Toggle\n\n", bold = true, color = colors.primary},
					{text = "Toggles the ability for the ears to flick.", color = colors.secondary}
				}
			))
			:hoverColor(colors.hover)
			:toggleColor(colors.active)
		
	end
	
end