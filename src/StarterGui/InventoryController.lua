-- StarterGui/InventoryGui/InventoryController (COMPLETE - WITH BUILDINGS)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local gui = script.Parent

-- UI References
local inventoryButton = gui:WaitForChild("InventoryButton")
local mainFrame = gui:WaitForChild("MainFrame")
local titleBar = mainFrame:WaitForChild("TitleBar")
local titleText = titleBar:WaitForChild("TitleText")
local deleteButton = titleBar:WaitForChild("DeleteButton")
local closeButton = titleBar:WaitForChild("CloseButton")
local tabContainer = mainFrame:WaitForChild("TabContainer")
local contentFrame = mainFrame:WaitForChild("ContentFrame")

-- Tabs
local habitatsTab = tabContainer:WaitForChild("HabitatsTab")
local incubatorsTab = tabContainer:WaitForChild("IncubatorsTab")
local eggsTab = tabContainer:WaitForChild("EggsTab")
local buildingsTab = tabContainer:FindFirstChild("BuildingsTab")

-- Remote Events
local placeHabitatRemote = ReplicatedStorage:WaitForChild("PlaceHabitat")
local placeIncubatorRemote = ReplicatedStorage:WaitForChild("PlaceIncubator")
local removeHabitatRemote = ReplicatedStorage:WaitForChild("RemoveHabitat")
local removeIncubatorRemote = ReplicatedStorage:WaitForChild("RemoveIncubator")

-- Models
local habitatModels = ReplicatedStorage:WaitForChild("HabitatModels")
local incubatorModels = ReplicatedStorage:FindFirstChild("IncubatorModels")
local buildingModels = ReplicatedStorage:FindFirstChild("BuildingModels")

-- Variables
local currentTab = "Habitats"
local deletingMode = false
local placingMode = false
local preview = nil
local currentItemName = nil
local currentUniqueID = nil
local currentRotation = 0
local currentCategory = nil

-- Tab colors
local TAB_COLORS = {
	Habitats = Color3.fromRGB(100, 180, 100),
	Incubators = Color3.fromRGB(180, 100, 180),
	Eggs = Color3.fromRGB(255, 200, 100),
	Buildings = Color3.fromRGB(220, 100, 220)
}

-- Create item card
local function createItemCard(itemData, layoutOrder)
	local card = Instance.new("Frame")
	card.Name = itemData.uniqueId
	card.Size = UDim2.new(0, 200, 0, 140)
	card.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
	card.BorderSizePixel = 0
	card.LayoutOrder = layoutOrder

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 15)
	cardCorner.Parent = card

	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 60, 0, 60)
	icon.Position = UDim2.new(0, 15, 0, 15)
	icon.BackgroundTransparency = 1
	icon.Text = itemData.icon
	icon.TextSize = 40
	icon.Parent = card

	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -90, 0, 30)
	nameLabel.Position = UDim2.new(0, 85, 0, 15)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = itemData.displayName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 16
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextWrapped = true
	nameLabel.Parent = card

	-- Info
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(1, -90, 0, 30)
	infoLabel.Position = UDim2.new(0, 85, 0, 45)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = itemData.info or ""
	infoLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
	infoLabel.TextSize = 12
	infoLabel.Font = Enum.Font.Gotham
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.TextWrapped = true
	infoLabel.Parent = card

	-- Action button
	local actionButton = Instance.new("TextButton")
	actionButton.Size = UDim2.new(0, 80, 0, 30)
	actionButton.Position = UDim2.new(1, -90, 1, -40)
	actionButton.BackgroundColor3 = itemData.buttonColor or Color3.fromRGB(60, 180, 60)
	actionButton.Text = itemData.buttonText or "USE"
	actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	actionButton.TextSize = 12
	actionButton.Font = Enum.Font.GothamBold
	actionButton.Parent = card

	local actionCorner = Instance.new("UICorner")
	actionCorner.CornerRadius = UDim.new(0, 8)
	actionCorner.Parent = actionButton

	actionButton.MouseButton1Click:Connect(function()
		if itemData.action then
			itemData.action()
		end
		mainFrame.Visible = false
	end)

	return card
end

-- Update content
local function updateContent()
	-- Clear existing
	for _, child in pairs(contentFrame:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local items = {}
	local order = 1

	if currentTab == "Habitats" then
		local habitatsFolder = player:FindFirstChild("Habitats")
		if habitatsFolder then
			for _, habitat in pairs(habitatsFolder:GetChildren()) do
				local habitatType = habitat.Value
				local icon = "??"
				if habitatType == "Fire" then icon = "??"
				elseif habitatType == "Water" then icon = "??"
				elseif habitatType == "Earth" then icon = "??"
				elseif habitatType == "Plant" then icon = "??"
				elseif habitatType == "Electric" then icon = "?"
				end

				table.insert(items, {
					uniqueId = habitat.Name,
					displayName = habitatType .. " Habitat",
					icon = icon,
					info = "Houses " .. habitatType .. " monsters",
					buttonText = "PLACE",
					buttonColor = Color3.fromRGB(100, 180, 100),
					action = function()
						startPlacement(habitatType, habitat.Name, "Habitat")
					end
				})
			end
		end

	elseif currentTab == "Incubators" then
		local incubatorsFolder = player:FindFirstChild("Incubators")
		if incubatorsFolder then
			for _, incubator in pairs(incubatorsFolder:GetChildren()) do
				local incubatorType = incubator.Value
				local speedValue = incubator:FindFirstChild("Speed")
				local speed = speedValue and speedValue.Value or 1.0

				local icon = "??"
				local speedText = ""
				if incubatorType == "SuperIncubator" then 
					icon = "?"
					speedText = "50% faster"
				elseif incubatorType == "UltraIncubator" then 
					icon = "??"
					speedText = "100% faster"
				end

				table.insert(items, {
					uniqueId = incubator.Name,
					displayName = incubatorType:gsub("Incubator", " Incubator"),
					icon = icon,
					info = speedText ~= "" and speedText or "Normal speed",
					buttonText = "PLACE",
					buttonColor = Color3.fromRGB(180, 100, 180),
					action = function()
						startPlacement(incubatorType, incubator.Name, "Incubator")
					end
				})
			end
		end

	elseif currentTab == "Eggs" then
		local eggsFolder = player:FindFirstChild("Eggs")
		if eggsFolder then
			for _, egg in pairs(eggsFolder:GetChildren()) do
				local eggTypeValue = egg:FindFirstChild("EggType")
				local hatchTimeValue = egg:FindFirstChild("HatchTime")
				local rarityValue = egg:FindFirstChild("Rarity")

				if eggTypeValue and hatchTimeValue and rarityValue then
					table.insert(items, {
						uniqueId = egg.Name,
						displayName = eggTypeValue.Value:gsub("Egg", " Egg"),
						icon = "??",
						info = "?? " .. hatchTimeValue.Value .. "s hatch time",
						rarity = rarityValue.Value,
						buttonText = "USE",
						buttonColor = Color3.fromRGB(255, 200, 100),
						action = function()
							print("?? Selected egg:", egg.Name)
						end
					})
				end
			end
		end

	elseif currentTab == "Buildings" then
		local buildingsFolder = player:FindFirstChild("Buildings")
		if buildingsFolder then
			for _, building in pairs(buildingsFolder:GetChildren()) do
				local buildingType = building.Value

				table.insert(items, {
					uniqueId = building.Name,
					displayName = buildingType:gsub("([A-Z])", " %1"):sub(2),
					icon = "??",
					info = "Breed monsters to create hybrids",
					buttonText = "PLACE",
					buttonColor = Color3.fromRGB(220, 100, 220),
					action = function()
						startPlacement(buildingType, building.Name, "Building")
					end
				})
			end
		end
	end

	-- Create cards
	for i, itemData in ipairs(items) do
		local card = createItemCard(itemData, i)
		card.Parent = contentFrame
	end

	-- Empty message
	if #items == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Name = "EmptyMessage"
		emptyLabel.Size = UDim2.new(1, 0, 0, 100)
		emptyLabel.Position = UDim2.new(0, 0, 0, 50)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "No " .. currentTab:lower() .. " in inventory"
		emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		emptyLabel.TextSize = 18
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.Parent = contentFrame
	end

	contentFrame.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#items / 4) * 155 + 50)
end

-- Start placement
function startPlacement(itemType, uniqueName, category)
	local modelsFolder, modelName

	if category == "Incubator" then
		modelsFolder = incubatorModels or habitatModels
		if incubatorModels and incubatorModels:FindFirstChild(itemType) then
			modelName = itemType
		else
			modelName = "HabitatFire"
		end
	elseif category == "Building" then
		modelsFolder = buildingModels
		modelName = itemType
	else
		modelsFolder = habitatModels
		modelName = "Habitat" .. itemType
	end

	if not modelsFolder then
		warn("Models folder not found for", category)
		return
	end

	local baseModel = modelsFolder:FindFirstChild(modelName)
	if not baseModel then
		warn("Base model not found:", modelName)
		return
	end

	local previewModel

	if baseModel:IsA("BasePart") then
		local wrapper = Instance.new("Model")
		local clone = baseModel:Clone()
		clone.Name = "VisualPart"
		clone.Transparency = 0.5
		clone.CanCollide = false
		clone.Anchored = true

		if category == "Incubator" then
			if itemType == "NormalIncubator" then
				clone.Color = Color3.fromRGB(255, 255, 100)
			elseif itemType == "SuperIncubator" then
				clone.Color = Color3.fromRGB(100, 255, 255)
			elseif itemType == "UltraIncubator" then
				clone.Color = Color3.fromRGB(255, 100, 255)
			end
		elseif category == "Building" then
			clone.Color = Color3.fromRGB(180, 100, 220)
		end

		clone.Parent = wrapper
		wrapper.Name = "Preview" .. category
		wrapper.PrimaryPart = clone
		wrapper.Parent = workspace
		previewModel = wrapper
	else
		local clone = baseModel:Clone()
		clone.Name = "Preview" .. category

		if not clone.PrimaryPart then
			local prim = clone:FindFirstChildWhichIsA("BasePart")
			if prim then
				clone.PrimaryPart = prim
			else
				warn("Model has no PrimaryPart")
				return
			end
		end

		for _, part in ipairs(clone:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = 0.5
				part.CanCollide = false
				part.Anchored = true

				if category == "Incubator" then
					if itemType == "NormalIncubator" then
						part.Color = Color3.fromRGB(255, 255, 100)
					elseif itemType == "SuperIncubator" then
						part.Color = Color3.fromRGB(100, 255, 255)
					elseif itemType == "UltraIncubator" then
						part.Color = Color3.fromRGB(255, 100, 255)
					end
				elseif category == "Building" then
					part.Color = Color3.fromRGB(180, 100, 220)
				end
			end
		end

		clone.Parent = workspace
		previewModel = clone
	end

	preview = previewModel
	currentItemName = itemType
	currentUniqueID = uniqueName
	currentCategory = category
	currentRotation = 0
	placingMode = true
end

-- Switch tab
local function switchTab(tabName)
	currentTab = tabName

	-- Update colors
	habitatsTab.BackgroundColor3 = tabName == "Habitats" and TAB_COLORS.Habitats or Color3.fromRGB(60, 60, 60)
	incubatorsTab.BackgroundColor3 = tabName == "Incubators" and TAB_COLORS.Incubators or Color3.fromRGB(60, 60, 60)
	eggsTab.BackgroundColor3 = tabName == "Eggs" and TAB_COLORS.Eggs or Color3.fromRGB(60, 60, 60)

	if buildingsTab then
		buildingsTab.BackgroundColor3 = tabName == "Buildings" and TAB_COLORS.Buildings or Color3.fromRGB(60, 60, 60)
	end

	updateContent()
end

-- Connect UI events
inventoryButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = not mainFrame.Visible
	if mainFrame.Visible then
		updateContent()
	end
end)

closeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
end)

deleteButton.MouseButton1Click:Connect(function()
	deletingMode = not deletingMode
	deleteButton.Text = deletingMode and "??? Delete: ON" or "??? Delete: OFF"
	deleteButton.BackgroundColor3 = deletingMode and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 100, 100)
end)

habitatsTab.MouseButton1Click:Connect(function()
	switchTab("Habitats")
end)

incubatorsTab.MouseButton1Click:Connect(function()
	switchTab("Incubators")
end)

eggsTab.MouseButton1Click:Connect(function()
	switchTab("Eggs")
end)

if buildingsTab then
	buildingsTab.MouseButton1Click:Connect(function()
		switchTab("Buildings")
	end)
end

-- Deletion system
mouse.Button1Down:Connect(function()
	if deletingMode then
		local target = mouse.Target
		if target then
			local plotName = player:GetAttribute("AssignedPlot")
			local plot = workspace:FindFirstChild("PlotsF") and workspace.PlotsF:FindFirstChild(plotName)

			if plot and target:IsDescendantOf(plot) then
				local object = target
				while object and object.Parent ~= plot do
					object = object.Parent
				end

				if object and object:IsA("Model") and object.Name:match("_") then
					local objectType = object:GetAttribute("Type")

					if objectType == "Incubator" then
						removeIncubatorRemote:FireServer(object.Name)
					elseif objectType == "BreedingMachine" then
						removeBreedingMachineRemote:FireServer(object.Name)
					else
						removeHabitatRemote:FireServer(object.Name)
					end

					deletingMode = false
					deleteButton.Text = "??? Delete: OFF"
					deleteButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
				end
			end
		end
	end
end)

-- Placement preview
RunService.RenderStepped:Connect(function()
	if placingMode and preview and preview.PrimaryPart then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Blacklist
		params.FilterDescendantsInstances = {preview}

		local result = workspace:Raycast(mouse.UnitRay.Origin, mouse.UnitRay.Direction * 500, params)
		if result then
			local pos = result.Position
			local height = preview.PrimaryPart.Size.Y / 2
			local cf = CFrame.new(pos + Vector3.new(0, height, 0)) * CFrame.Angles(0, math.rad(currentRotation), 0)
			preview:PivotTo(cf)

			local plotName = player:GetAttribute("AssignedPlot")
			local plot = workspace:FindFirstChild("PlotsF") and workspace.PlotsF:FindFirstChild(plotName)
			local canPlace = false

			if plot and plot:IsA("BasePart") then
				local plotSize = plot.Size
				local plotCenter = plot.Position
				local plotMin = plotCenter - plotSize / 2
				local plotMax = plotCenter + plotSize / 2

				local previewCF, previewSize = preview:GetBoundingBox()
				local previewMin = previewCF.Position - previewSize / 2
				local previewMax = previewCF.Position + previewSize / 2

				canPlace = previewMin.X >= plotMin.X and previewMax.X <= plotMax.X and
					previewMin.Z >= plotMin.Z and previewMax.Z <= plotMax.Z
			end

			local color = canPlace and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)

			for _, part in ipairs(preview:GetDescendants()) do
				if part:IsA("BasePart") then
					if currentCategory == "Incubator" and canPlace then
						-- Keep incubator colors
					elseif currentCategory == "Building" and canPlace then
						part.Color = Color3.fromRGB(180, 100, 220)
						part.Transparency = 0.5
					else
						part.Color = color
					end
				end
			end
		end
	end
end)

-- Handle placement/rotation/cancel
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	if placingMode then
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if not preview then return end

			local previewCF, previewSize = preview:GetBoundingBox()
			local pos = previewCF.Position

			local plotName = player:GetAttribute("AssignedPlot")
			local plot = workspace:FindFirstChild("PlotsF") and workspace.PlotsF:FindFirstChild(plotName)

			if plot and plot:IsA("BasePart") then
				local plotSize = plot.Size
				local plotCenter = plot.Position
				local plotMin = plotCenter - plotSize / 2
				local plotMax = plotCenter + plotSize / 2

				local previewMin = pos - previewSize / 2
				local previewMax = pos + previewSize / 2

				local canPlace = previewMin.X >= plotMin.X and previewMax.X <= plotMax.X and
					previewMin.Z >= plotMin.Z and previewMax.Z <= plotMax.Z

				if canPlace then
					if currentCategory == "Incubator" then
						placeIncubatorRemote:FireServer(currentUniqueID, pos, currentRotation)
					elseif currentCategory == "Building" then
						placeBreedingMachineRemote:FireServer(currentUniqueID, pos, currentRotation)
					else
						placeHabitatRemote:FireServer(currentUniqueID, pos, currentRotation)
					end

					preview:Destroy()
					preview = nil
					placingMode = false
				end
			end
		end

	elseif input.KeyCode == Enum.KeyCode.R and placingMode then
		currentRotation = currentRotation + 45

	elseif input.KeyCode == Enum.KeyCode.Escape and placingMode then
		if preview then
			preview:Destroy()
			preview = nil
		end
		placingMode = false
	end
end)

-- Initialize
switchTab("Habitats")

print("? Inventory Controller with Buildings loaded!")
