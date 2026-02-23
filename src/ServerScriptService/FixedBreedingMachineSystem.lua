-- ServerScriptService/FixedBreedingMachineSystem.lua
-- SIMPLIFIED VERSION - Uses existing breeding machines in workspace
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GameDataManager = require(game.ServerScriptService.Systems.GameDataManager)

-- Create remote events
local unlockBreedingTierRemote = ReplicatedStorage:FindFirstChild("UnlockBreedingTier")
if not unlockBreedingTierRemote then
	unlockBreedingTierRemote = Instance.new("RemoteEvent")
	unlockBreedingTierRemote.Name = "UnlockBreedingTier"
	unlockBreedingTierRemote.Parent = ReplicatedStorage
end

local openBreedingUIRemote = ReplicatedStorage:FindFirstChild("OpenBreedingUI")
if not openBreedingUIRemote then
	openBreedingUIRemote = Instance.new("RemoteEvent")
	openBreedingUIRemote.Name = "OpenBreedingUI"
	openBreedingUIRemote.Parent = ReplicatedStorage
end

-- Breeding machine tier configuration
local BREEDING_TIERS = {
	[1] = {
		tier = 1,
		price = 500,
		monstersRequired = 0, -- Always available
		machineName = "BreedingMachine1",
		color = Color3.fromRGB(150, 100, 200), -- Purple
		name = "Basic Breeding Machine"
	},
	[2] = {
		tier = 2,
		price = 1500,
		monstersRequired = 10, -- Unlock at 10 unique monsters
		machineName = "BreedingMachine2",
		color = Color3.fromRGB(100, 150, 255), -- Blue
		name = "Advanced Breeding Machine"
	},
	[3] = {
		tier = 3,
		price = 3000,
		monstersRequired = 25, -- Unlock at 25 unique monsters
		machineName = "BreedingMachine3",
		color = Color3.fromRGB(255, 200, 100), -- Gold
		name = "Master Breeding Machine"
	}
}

-- Function to update machine visual state (works with Parts and Models)
local function updateMachineVisualState(machine, state, progress)
	if not machine then return end

	-- Find the main part to apply effects to
	local mainPart = nil

	if machine:IsA("BasePart") then
		-- It's already a part
		mainPart = machine
	elseif machine:IsA("Model") then
		-- It's a model, find the primary part
		mainPart = machine.PrimaryPart or machine:FindFirstChildWhichIsA("BasePart")
	end

	if not mainPart then 
		warn("?? No part found in machine to apply visual state")
		return 
	end

	if state == "locked" then
		-- Locked state - dark and inactive
		mainPart.Material = Enum.Material.Glass
		mainPart.Transparency = 0.5

		-- Remove any lights
		local light = mainPart:FindFirstChild("PointLight")
		if light then light:Destroy() end

	elseif state == "unlocked" then
		-- Unlocked and available - bright and glowing
		mainPart.Material = Enum.Material.Neon
		mainPart.Transparency = 0.2

		-- Add glow
		local light = mainPart:FindFirstChild("PointLight")
		if not light then
			light = Instance.new("PointLight")
			light.Brightness = 1
			light.Range = 15
			light.Color = mainPart.Color
			light.Parent = mainPart
		end

	elseif state == "brewing" then
		-- Breeding in progress - animated
		mainPart.Material = Enum.Material.Neon
		mainPart.Transparency = 0.1

		-- Bright pulsing light
		local light = mainPart:FindFirstChild("PointLight")
		if not light then
			light = Instance.new("PointLight")
			light.Brightness = 2
			light.Range = 20
			light.Color = mainPart.Color
			light.Parent = mainPart
		end

		-- Add particles
		local particles = mainPart:FindFirstChild("BreedingParticles")
		if not particles then
			particles = Instance.new("ParticleEmitter")
			particles.Name = "BreedingParticles"
			particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			particles.Color = ColorSequence.new(mainPart.Color)
			particles.Lifetime = NumberRange.new(1, 2)
			particles.Rate = 50
			particles.Speed = NumberRange.new(2)
			particles.SpreadAngle = Vector2.new(180, 180)
			particles.Parent = mainPart
		end

	elseif state == "ready_to_collect" then
		-- Egg ready to collect - glowing brightly
		mainPart.Material = Enum.Material.Neon
		mainPart.Transparency = 0.1

		-- Very bright light
		local light = mainPart:FindFirstChild("PointLight")
		if not light then
			light = Instance.new("PointLight")
			light.Parent = mainPart
		end
		light.Brightness = 3
		light.Range = 25
		light.Color = Color3.fromRGB(100, 255, 100)

		-- Remove breeding particles, add completion sparkles
		local oldParticles = mainPart:FindFirstChild("BreedingParticles")
		if oldParticles then oldParticles:Destroy() end

		local sparkles = mainPart:FindFirstChild("CompletionSparkles")
		if not sparkles then
			sparkles = Instance.new("ParticleEmitter")
			sparkles.Name = "CompletionSparkles"
			sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 100))
			sparkles.Lifetime = NumberRange.new(0.5, 1)
			sparkles.Rate = 100
			sparkles.Speed = NumberRange.new(5)
			sparkles.SpreadAngle = Vector2.new(360, 360)
			sparkles.Parent = mainPart
		end
	end
end

-- Function to create proximity prompt for interaction (works with Parts and Models)
local function createProximityPrompt(machine, isUnlocked, tier, price, monstersRequired)
	-- Remove ALL old prompts (search recursively)
	for _, descendant in pairs(machine:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			print("??? Removing old proximity prompt from:", descendant.Parent.Name)
			descendant:Destroy()
		end
	end

	-- Also check direct child
	local oldPrompt = machine:FindFirstChild("ProximityPrompt")
	if oldPrompt then 
		print("??? Removing old direct proximity prompt")
		oldPrompt:Destroy() 
	end

	-- Find a part to attach prompt to
	local attachPart = nil

	if machine:IsA("BasePart") then
		-- It's already a part
		attachPart = machine
	elseif machine:IsA("Model") then
		-- It's a model, find a part
		attachPart = machine.PrimaryPart or machine:FindFirstChildWhichIsA("BasePart")
	end

	if not attachPart then 
		warn("?? No part found to attach proximity prompt")
		return 
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = isUnlocked and "Open Breeding Menu" or "Unlock (Requires " .. monstersRequired .. " monsters)"
	prompt.ObjectText = "Tier " .. tier .. " Breeding Machine"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Enabled = true
	prompt.Parent = attachPart

	print("? Created proximity prompt on:", attachPart.Name, "ActionText:", prompt.ActionText)

	return prompt
end

-- Function to check if player can unlock a tier
local function canUnlockTier(player, tier)
	local profile = GameDataManager:GetProfile(player)
	if not profile then return false, "No profile" end

	local tierData = BREEDING_TIERS[tier]
	if not tierData then return false, "Invalid tier" end

	-- Check monster collection requirement
	local monstersCollected = profile.Data.Stats.MonstersCollected or 0
	if monstersCollected < tierData.monstersRequired then
		return false, "Need " .. tierData.monstersRequired .. " monsters (have " .. monstersCollected .. ")"
	end

	-- Check coins
	if profile.Data.Coins < tierData.price then
		return false, "Need " .. tierData.price .. " coins"
	end

	return true, "OK"
end

-- Function to find breeding machines (works with both Models and Parts)
local function findBreedingMachine(plot, machineName)
	-- First try to find directly in plot
	local machine = plot:FindFirstChild(machineName)
	if machine then return machine end

	-- If not found, search in descendants (maybe nested)
	for _, descendant in pairs(plot:GetDescendants()) do
		if descendant.Name == machineName then
			return descendant
		end
	end

	return nil
end

-- ?? CRITICAL FIX: Function to find the breeding machine model from a part
local function findBreedingMachineFromPart(part)
	-- Start from the part and go up until we find something with BreedingMachine type
	local current = part

	while current do
		if current:GetAttribute("Type") == "BreedingMachine" then
			return current
		end
		current = current.Parent

		-- Stop if we reach workspace or nil
		if current == workspace or not current then
			break
		end
	end

	return nil
end

-- Function to setup breeding machines for a plot
local function setupBreedingMachinesForPlot(plot, player)
	print("?? Setting up breeding machines for plot:", plot.Name)

	-- Get player's profile to check unlocked tiers
	local profile = GameDataManager:GetProfile(player)
	if not profile then 
		warn("? No profile found for player")
		return 
	end

	-- Initialize BreedingMachines data if not exists
	if not profile.Data.BreedingMachines then
		profile.Data.BreedingMachines = {
			[1] = {unlocked = false},
			[2] = {unlocked = false},
			[3] = {unlocked = false}
		}
	end

	-- Setup all 3 tier machines
	for _, tierData in ipairs(BREEDING_TIERS) do
		-- Find the machine (works with Parts or Models)
		local machine = findBreedingMachine(plot, tierData.machineName)

		if machine then
			print("? Found machine:", tierData.machineName, "Type:", machine.ClassName)

			-- If it's a Part, we work directly with it
			-- If it's a Model, we work with the model
			local workingObject = machine

			-- Set attributes
			workingObject:SetAttribute("Type", "BreedingMachine")
			workingObject:SetAttribute("Tier", tierData.tier)
			workingObject:SetAttribute("Price", tierData.price)
			workingObject:SetAttribute("MonstersRequired", tierData.monstersRequired)

			-- Check if this tier is unlocked
			local isUnlocked = profile.Data.BreedingMachines[tierData.tier] and 
				profile.Data.BreedingMachines[tierData.tier].unlocked

			-- Set unlock attribute
			workingObject:SetAttribute("Unlocked", isUnlocked)

			-- Set initial visual state
			if isUnlocked then
				updateMachineVisualState(workingObject, "unlocked")
			else
				updateMachineVisualState(workingObject, "locked")
			end

			-- Color the machine based on tier
			if workingObject:IsA("BasePart") then
				-- It's a single part
				workingObject.Color = tierData.color
			else
				-- It's a Model, color all parts
				for _, part in pairs(workingObject:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Color = tierData.color
					end
				end
			end

			-- Create proximity prompt
			createProximityPrompt(workingObject, isUnlocked, tierData.tier, tierData.price, tierData.monstersRequired)

			print("? Setup complete for", tierData.name, "- Unlocked:", isUnlocked)
		else
			warn("?? Machine not found:", tierData.machineName, "in plot", plot.Name)
			warn("   Available children in plot:")
			for _, child in pairs(plot:GetChildren()) do
				print("   -", child.Name, child.ClassName)
			end
		end
	end

	print("? Breeding machines setup complete for plot:", plot.Name)
end

-- Handle unlocking breeding tier
unlockBreedingTierRemote.OnServerEvent:Connect(function(player, tier)
	print("?? Unlock request for Tier", tier, "from", player.Name)

	local profile = GameDataManager:GetProfile(player)
	if not profile then return end

	-- Check if can unlock
	local canUnlock, reason = canUnlockTier(player, tier)
	if not canUnlock then
		warn("? Cannot unlock:", reason)
		unlockBreedingTierRemote:FireClient(player, false, reason)
		return
	end

	-- Deduct coins
	local tierData = BREEDING_TIERS[tier]
	GameDataManager:ModifyCoins(player, -tierData.price)

	-- Mark as unlocked
	if not profile.Data.BreedingMachines then
		profile.Data.BreedingMachines = {}
	end
	profile.Data.BreedingMachines[tier] = {unlocked = true}

	-- Update machine in world
	local plotName = player:GetAttribute("AssignedPlot")
	local plot = workspace:FindFirstChild("PlotsF") and workspace.PlotsF:FindFirstChild(plotName)
	if plot then
		local machine = plot:FindFirstChild(tierData.machineName)
		if machine then
			machine:SetAttribute("Unlocked", true)
			updateMachineVisualState(machine, "unlocked")

			-- Update proximity prompt
			createProximityPrompt(machine, true, tier, tierData.price, tierData.monstersRequired)
		end
	end

	print("? Tier", tier, "unlocked for", player.Name)
	unlockBreedingTierRemote:FireClient(player, true, "Tier " .. tier .. " unlocked!")
end)

-- ?? CRITICAL FIX: Handle proximity prompt interaction
local function setupProximityPromptHandler()
	local ProximityPromptService = game:GetService("ProximityPromptService")

	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		print("?? Proximity prompt triggered by:", player.Name)

		local promptParent = prompt.Parent
		print("?? Prompt parent:", promptParent, "Type:", promptParent and promptParent.ClassName)

		if not promptParent then 
			warn("? Prompt has no parent!")
			return 
		end

		-- ?? FIXED: Find the actual breeding machine from the part
		local machine = findBreedingMachineFromPart(promptParent)
		print("?? Machine found:", machine)

		if not machine then
			warn("? Could not find breeding machine from prompt parent")
			warn("? Prompt parent name:", promptParent.Name)
			warn("? Prompt parent has Type attribute:", promptParent:GetAttribute("Type"))
			return
		end

		local machineType = machine:GetAttribute("Type")
		print("?? Machine type:", machineType)

		if machineType ~= "BreedingMachine" then 
			warn("? Not a breeding machine, type is:", machineType)
			return 
		end

		local tier = machine:GetAttribute("Tier")
		local isUnlocked = machine:GetAttribute("Unlocked")
		local isBreedingReady = machine:GetAttribute("BreedingReady")
		local isBreeding = machine:GetAttribute("BreedingStartTime")

		print("?? Tier:", tier, "Unlocked:", isUnlocked, "BreedingReady:", isBreedingReady, "IsBreeding:", isBreeding ~= nil)

		-- Check if breeding is complete and ready for collection
		if isBreedingReady then
			print("?? This prompt should be the collection prompt - it will handle collection")
			-- The collection prompt handles this - do nothing here
			return
		end

		if isUnlocked then
			-- Check if machine is currently breeding (but not ready for collection)
			if isBreeding and not isBreedingReady then
				print("?? Machine is currently breeding - cannot open UI")
				-- Don't open UI while breeding
				return
			end

			-- Machine is unlocked and not breeding - open breeding UI
			print("?? Opening breeding UI for machine:", machine.Name)
			openBreedingUIRemote:FireClient(player, machine.Name)
		else
			-- Machine is locked - show unlock UI
			print("?? Showing unlock UI for Tier", tier)
			unlockBreedingTierRemote:FireClient(player, "ShowUnlockUI", tier)
		end
	end)

	print("? Proximity prompt handler setup complete")
end

-- Initialize when player joins
Players.PlayerAdded:Connect(function(player)
	-- Wait for plot assignment
	repeat task.wait(0.5) until player:GetAttribute("AssignedPlot")

	task.wait(2) -- Extra delay for plot setup

	local plotName = player:GetAttribute("AssignedPlot")
	local plot = workspace:FindFirstChild("PlotsF") and workspace.PlotsF:FindFirstChild(plotName)

	if plot then
		setupBreedingMachinesForPlot(plot, player)
	else
		warn("? Plot not found:", plotName)
	end
end)

-- Setup proximity prompt handler
setupProximityPromptHandler()

-- Update machine states periodically (for breeding timers)
task.spawn(function()
	while true do
		task.wait(1) -- Update every second

		for _, player in pairs(Players:GetPlayers()) do
			local plotName = player:GetAttribute("AssignedPlot")
			local plot = workspace:FindFirstChild("PlotsF") and workspace.PlotsF:FindFirstChild(plotName)

			if plot then
				for _, machine in pairs(plot:GetChildren()) do
					if machine:GetAttribute("Type") == "BreedingMachine" then
						local startTime = machine:GetAttribute("BreedingStartTime")
						local duration = machine:GetAttribute("BreedingDuration")

						if startTime and duration then
							local elapsed = tick() - startTime
							local remaining = duration - elapsed

							if remaining <= 0 then
								-- Breeding complete!
								updateMachineVisualState(machine, "ready_to_collect")
							else
								-- Still brewing
								updateMachineVisualState(machine, "brewing")
							end
						end
					end
				end
			end
		end
	end
end)

print("?? Fixed Breeding Machine System loaded (Using Existing Machines)!")
print("?? Tier Requirements:")
for _, tier in ipairs(BREEDING_TIERS) do
	print("  Tier " .. tier.tier .. " (" .. tier.machineName .. "):", tier.price, "coins,", tier.monstersRequired, "monsters")
end

--[[
?? CRITICAL FIXES IN THIS VERSION:
1. ? Added findBreedingMachineFromPart() function (lines 235-250)
2. ? Updated proximity prompt handler to use this function (lines 395-420)
3. ? Now correctly sends machine.Name instead of wrong object
4. ? Better debug output showing actual machine name being sent

The problem was: The proximity prompt is attached to a PART inside the machine,
but we need to send the MACHINE (Model/Part with Type attribute) name to the client.
This function walks up the hierarchy to find the actual breeding machine object.
--]]