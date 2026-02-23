-- ServerScriptService/IncubatorPlacementHandler.lua (COMPLETE)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameDataManager = require(game.ServerScriptService.Systems.GameDataManager)

-- Create remote events for incubators
local placeIncubatorRemote = ReplicatedStorage:FindFirstChild("PlaceIncubator")
if not placeIncubatorRemote then
	placeIncubatorRemote = Instance.new("RemoteEvent")
	placeIncubatorRemote.Name = "PlaceIncubator"
	placeIncubatorRemote.Parent = ReplicatedStorage
end

local removeIncubatorRemote = ReplicatedStorage:FindFirstChild("RemoveIncubator")
if not removeIncubatorRemote then
	removeIncubatorRemote = Instance.new("RemoteEvent")
	removeIncubatorRemote.Name = "RemoveIncubator"
	removeIncubatorRemote.Parent = ReplicatedStorage
end

local IncubatorModels = ReplicatedStorage:FindFirstChild("IncubatorModels")
local HabitatModels = ReplicatedStorage:WaitForChild("HabitatModels")
local Plots = workspace:WaitForChild("PlotsF")

-- Incubator prices for refund calculation
local incubatorPrices = {
	["NormalIncubator"] = 250,
	["SuperIncubator"] = 750,
	["UltraIncubator"] = 1500,
}

-- Handle placing incubator
placeIncubatorRemote.OnServerEvent:Connect(function(player, incubatorId, position, rotation)
	local incubatorsFolder = player:FindFirstChild("Incubators")
	if not incubatorsFolder then return end

	local valueObject = incubatorsFolder:FindFirstChild(incubatorId)
	if not valueObject then
		warn("? Incubator value not found:", incubatorId)
		return
	end

	local incubatorType = valueObject.Value
	local baseModel = nil

	-- Try to find incubator model, fallback to habitat model
	if IncubatorModels then
		baseModel = IncubatorModels:FindFirstChild(incubatorType)
	end

	if not baseModel then
		-- Fallback: Use Fire habitat model but modify it
		baseModel = HabitatModels:FindFirstChild("HabitatFire")
		if not baseModel then
			warn("? No model found for incubator:", incubatorType)
			return
		end
	end

	local model = baseModel:Clone()
	model.Name = incubatorId

	-- Ensure PrimaryPart
	if model:IsA("BasePart") then
		local wrapper = Instance.new("Model")
		model.Anchored = true

		-- Color incubators differently from habitats
		if incubatorType == "NormalIncubator" then
			model.Color = Color3.fromRGB(255, 255, 100) -- Yellow
		elseif incubatorType == "SuperIncubator" then
			model.Color = Color3.fromRGB(100, 255, 255) -- Cyan
		elseif incubatorType == "UltraIncubator" then
			model.Color = Color3.fromRGB(255, 100, 255) -- Magenta
		end

		model.Parent = wrapper
		wrapper.PrimaryPart = model
		wrapper.Name = incubatorId
		model = wrapper
	elseif not model.PrimaryPart then
		local primary = model:FindFirstChildWhichIsA("BasePart")
		if primary then
			model.PrimaryPart = primary

			-- Color all parts for multi-part models
			for _, part in pairs(model:GetDescendants()) do
				if part:IsA("BasePart") then
					if incubatorType == "NormalIncubator" then
						part.Color = Color3.fromRGB(255, 255, 100)
					elseif incubatorType == "SuperIncubator" then
						part.Color = Color3.fromRGB(100, 255, 255)
					elseif incubatorType == "UltraIncubator" then
						part.Color = Color3.fromRGB(255, 100, 255)
					end
				end
			end
		else
			warn("? Model missing PrimaryPart")
			return
		end
	end

	local plotName = player:GetAttribute("AssignedPlot")
	local plot = Plots:FindFirstChild(plotName)
	if not plot then
		warn("? Plot not found for player:", plotName)
		return
	end

	-- Check if position is inside the plot bounds
	local pos = position
	local size = plot.Size
	local center = plot.Position
	local min = center - size / 2
	local max = center + size / 2

	local inside =
		pos.X >= min.X and pos.X <= max.X and
		pos.Z >= min.Z and pos.Z <= max.Z

	if not inside then
		warn("? Attempt to place incubator outside of assigned plot:", player.Name)
		return
	end

	-- Position the model
	local finalCFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotation), 0)
	model:PivotTo(finalCFrame)
	model.Parent = plot

	-- Check for collision with other placed objects (habitats AND incubators)
	local touching = false
	for _, other in ipairs(plot:GetChildren()) do
		if other:IsA("Model") and other ~= model and other:FindFirstChildWhichIsA("BasePart") and other.Name:match("_") then
			local aCFrame, aSize = other:GetBoundingBox()
			local bCFrame, bSize = model:GetBoundingBox()

			local aMin = aCFrame.Position - aSize / 2
			local aMax = aCFrame.Position + aSize / 2
			local bMin = bCFrame.Position - bSize / 2
			local bMax = bCFrame.Position + bSize / 2

			local function boxesIntersect(minA, maxA, minB, maxB)
				return (
					minA.X <= maxB.X and maxA.X >= minB.X and
						minA.Y <= maxB.Y and maxA.Y >= minB.Y and
						minA.Z <= maxB.Z and maxA.Z >= minB.Z
				)
			end

			if boxesIntersect(aMin, aMax, bMin, bMax) then
				touching = true
				break
			end
		end
	end

	if touching then
		warn("? Collision detected: cannot place incubator on top of another object")
		model:Destroy()
		return
	end

	-- Add incubator-specific attributes
	model:SetAttribute("Type", "Incubator")
	model:SetAttribute("IncubatorType", incubatorType)

	-- Get speed multiplier from inventory item
	local speedValue = valueObject:FindFirstChild("Speed")
	if speedValue then
		model:SetAttribute("Speed", speedValue.Value)
	else
		model:SetAttribute("Speed", 1.0) -- Default speed
	end

	-- Remove from inventory
	valueObject:Destroy()

	-- Save placement to profile
	GameDataManager:SavePlotPlacement(player, "Incubator", incubatorId, pos, rotation)

	-- Mark incubator as placed
	local profile = GameDataManager:GetProfile(player)
	if profile and profile.Data.Inventory.Incubators[incubatorId] then
		profile.Data.Inventory.Incubators[incubatorId].placed = true
	end

	print("? Incubator placed for", player.Name, "type:", incubatorType)
end)

-- Handle removing incubator (replace this section in IncubatorPlacementHandler)
removeIncubatorRemote.OnServerEvent:Connect(function(player, incubatorId)
	local plotName = player:GetAttribute("AssignedPlot")
	local plot = Plots:FindFirstChild(plotName)
	if not plot then return end

	local incubator = plot:FindFirstChild(incubatorId)
	if not incubator then 
		warn("? Incubator not found:", incubatorId)
		return 
	end

	-- Check if it's actually an incubator
	if incubator:GetAttribute("Type") ~= "Incubator" then
		warn("? Object is not an incubator:", incubatorId)
		return
	end

	-- Get incubator type for refund
	local incubatorType = incubator:GetAttribute("IncubatorType")
	if incubatorType and incubatorPrices[incubatorType] then
		-- Give back 50% of original price
		local refund = math.floor(incubatorPrices[incubatorType] * 0.5)
		GameDataManager:ModifyCoins(player, refund)
		print("?? Refunded", refund, "coins to", player.Name, "for incubator")
	end

	-- Remove from plot data and return to inventory
	GameDataManager:RemovePlotPlacement(player, incubatorId)

	incubator:Destroy()
	print("??? Incubator removed:", incubatorId, "by", player.Name)
end)