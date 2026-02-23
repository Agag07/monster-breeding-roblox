-- ServerScriptService/PlaceHabitatHandler.lua (COMPLETE FIXED VERSION)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HabitatModels = ReplicatedStorage:WaitForChild("HabitatModels")
local PlaceHabitatRemote = ReplicatedStorage:WaitForChild("PlaceHabitat")
local Plots = workspace:WaitForChild("PlotsF")
local GameDataManager = require(game.ServerScriptService.Systems.GameDataManager)

PlaceHabitatRemote.OnServerEvent:Connect(function(player, habitatId, position, rotation)
	local habitatFolder = player:FindFirstChild("Habitats")
	if not habitatFolder then return end

	local valueObject = habitatFolder:FindFirstChild(habitatId)
	if not valueObject then
		warn("? Habitat value not found:", habitatId)
		return
	end

	local habitatType = valueObject.Value
	local baseModel = HabitatModels:FindFirstChild("Habitat" .. habitatType)
	if not baseModel then
		warn("? Base model not found for Habitat" .. habitatType)
		return
	end

	-- ?? FIX: Clone and ensure we always have a proper Model with attributes
	local model

	if baseModel:IsA("BasePart") then
		-- If the base is just a Part, wrap it in a Model
		print("?? Wrapping Part in Model for:", habitatType)

		local wrapper = Instance.new("Model")
		wrapper.Name = habitatId

		local clonedPart = baseModel:Clone()
		clonedPart.Name = "HabitatPart"
		clonedPart.Anchored = true
		clonedPart.Parent = wrapper

		wrapper.PrimaryPart = clonedPart
		model = wrapper

	elseif baseModel:IsA("Model") then
		-- If it's already a Model, clone it
		model = baseModel:Clone()
		model.Name = habitatId

		-- Ensure PrimaryPart exists
		if not model.PrimaryPart then
			local primary = model:FindFirstChildWhichIsA("BasePart")
			if primary then
				model.PrimaryPart = primary
				print("?? Set PrimaryPart to:", primary.Name)
			else
				warn("? Model missing PrimaryPart and no BasePart found")
				return
			end
		end
	else
		warn("? Unknown base model type:", baseModel.ClassName)
		return
	end

	-- Verify we have a valid model with PrimaryPart
	if not model.PrimaryPart then
		warn("? Failed to create valid model with PrimaryPart")
		return
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
		warn("? Attempt to place outside of assigned plot:", player.Name)
		return
	end

	-- Position the model first (before adding to plot)
	local finalCFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotation), 0)
	model:PivotTo(finalCFrame)

	-- ?? FIX: Set ownership attributes on the MODEL (not individual parts)
	model:SetAttribute("Owner", player.UserId)
	model:SetAttribute("HabitatId", habitatId)
	model:SetAttribute("Element", habitatType)
	model:SetAttribute("Type", "Habitat")
	model:SetAttribute("Level", 1)

	-- Add to plot
	model.Parent = plot

	-- Check for collision with other placed objects
	local touching = false
	for _, other in ipairs(plot:GetChildren()) do
		if other:IsA("Model") and other ~= model and other.Name ~= "Sign" and other:FindFirstChildWhichIsA("BasePart") then
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
		warn("? Collision detected: cannot place on top of another object")
		model:Destroy()
		return
	end

	-- Remove from inventory
	valueObject:Destroy()

	-- Save placement to profile
	GameDataManager:SavePlotPlacement(player, "Habitat", habitatId, pos, rotation)

	-- Mark habitat as placed in inventory
	local profile = GameDataManager:GetProfile(player)
	if profile and profile.Data.Inventory.Habitats[habitatId] then
		profile.Data.Inventory.Habitats[habitatId].placed = true
	end

	print("? Habitat placed for", player.Name, "type:", habitatType, "ID:", habitatId, "ModelType:", model.ClassName)

	-- Debug: Print attributes to verify they were set
	print("  +- Attributes set:")
	print("    • Owner:", model:GetAttribute("Owner"))
	print("    • HabitatId:", model:GetAttribute("HabitatId"))
	print("    • Element:", model:GetAttribute("Element"))
	print("    • Type:", model:GetAttribute("Type"))
	print("    • Level:", model:GetAttribute("Level"))
end)

print("? PlaceHabitatHandler loaded with Part wrapping fix")