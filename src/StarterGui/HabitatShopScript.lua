-- CLIENT SCRIPT: Habitat Shop Controller (COMPLETE - FIXED PRICES)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local screenGui = script.Parent

-- Get UI elements
local shopFrame = screenGui:WaitForChild("ShopFrame")
local closeButton = shopFrame:WaitForChild("TitleBar"):WaitForChild("CloseButton")

local tabContainer = shopFrame:WaitForChild("TabContainer")
local habitatTab = tabContainer:WaitForChild("HabitatTab")
local incubatorTab = tabContainer:WaitForChild("IncubatorTab")

local contentFrame = shopFrame:WaitForChild("ContentFrame")

-- Remote events
local openShopRemote = ReplicatedStorage:WaitForChild("OpenShopHabitats")
local buyItemRemote = ReplicatedStorage:WaitForChild("BuyItem")
local buyResultRemote = ReplicatedStorage:WaitForChild("BuyResult")

-- Variables
local currentTab = "habitat"
local shopData = {}

print("?? CLIENT: Habitat Shop Controller Loading...")

-- Function to create item cards dynamically
local function createItemCard(itemId, itemData, layoutOrder)
	print("?? CLIENT: Creating card for", itemData.name, "Price:", itemData.price)  -- DEBUG

	local card = Instance.new("Frame")
	card.Name = itemId
	card.Size = UDim2.new(0, 240, 0, 140)
	card.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	card.BorderSizePixel = 0
	card.LayoutOrder = layoutOrder
	card.Parent = contentFrame

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = card

	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 50, 0, 50)
	icon.Position = UDim2.new(0, 15, 0, 15)
	icon.BackgroundTransparency = 1
	icon.Text = itemData.icon
	icon.TextSize = 35
	icon.Parent = card

	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -80, 0, 25)
	nameLabel.Position = UDim2.new(0, 75, 0, 15)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = itemData.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 16
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	-- Price (DIRECTLY FROM SERVER DATA)
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(1, -80, 0, 20)
	priceLabel.Position = UDim2.new(0, 75, 0, 40)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "?? " .. itemData.price .. " Coins"  -- USE SERVER PRICE
	priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	priceLabel.TextSize = 14
	priceLabel.Font = Enum.Font.Gotham
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.Parent = card

	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -20, 0, 35)
	descLabel.Position = UDim2.new(0, 10, 0, 70)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = itemData.description
	descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	descLabel.TextSize = 12
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextWrapped = true
	descLabel.Parent = card

	-- Special info for incubators (speed bonus)
	if itemData.speed and itemData.speed > 1 then
		local speedLabel = Instance.new("TextLabel")
		speedLabel.Size = UDim2.new(1, -20, 0, 15)
		speedLabel.Position = UDim2.new(0, 10, 0, 95)
		speedLabel.BackgroundTransparency = 1
		speedLabel.Text = "? " .. math.floor((itemData.speed - 1) * 100) .. "% Faster"
		speedLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		speedLabel.TextSize = 11
		speedLabel.Font = Enum.Font.GothamBold
		speedLabel.Parent = card
	end

	-- Buy button
	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(0, 80, 0, 30)
	buyButton.Position = UDim2.new(1, -90, 1, -40)
	buyButton.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
	buyButton.Text = "BUY"
	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyButton.TextSize = 14
	buyButton.Font = Enum.Font.GothamBold
	buyButton.Parent = card

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 6)
	buyCorner.Parent = buyButton

	-- Buy button click event
	buyButton.MouseButton1Click:Connect(function()
		print("?? CLIENT: Buying", itemId, "for", itemData.price, "coins")
		buyItemRemote:FireServer(itemId)
		shopFrame.Visible = false
	end)

	return card
end

-- Function to update content based on current tab
local function updateContent()
	print("?? CLIENT: Updating content for tab:", currentTab)

	-- Clear existing content
	for _, child in pairs(contentFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "UIGridLayout" then
			child:Destroy()
		end
	end

	-- Filter items by current tab
	local order = 1
	for itemId, itemData in pairs(shopData) do
		if itemData.type == currentTab then
			print("  Adding:", itemData.name, "Price:", itemData.price)
			createItemCard(itemId, itemData, order)
			order += 1
		end
	end

	-- Update scroll canvas size
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, math.ceil(order / 3) * 155)
end

-- Function to switch between tabs
local function switchTab(tabName)
	currentTab = tabName

	-- Update tab colors
	if tabName == "habitat" then
		habitatTab.BackgroundColor3 = Color3.fromRGB(60, 150, 60)
		incubatorTab.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	else
		habitatTab.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		incubatorTab.BackgroundColor3 = Color3.fromRGB(150, 60, 150)
	end

	updateContent()
end

-- Event connections
closeButton.MouseButton1Click:Connect(function()
	shopFrame.Visible = false
end)

habitatTab.MouseButton1Click:Connect(function()
	switchTab("habitat")
end)

incubatorTab.MouseButton1Click:Connect(function()
	switchTab("incubator")
end)

-- Handle shop opening from server
openShopRemote.OnClientEvent:Connect(function(data)
	print("========================================")
	print("?? CLIENT: Received shop data from server!")
	print("========================================")

	shopData = data

	-- Debug: Print all prices received
	for itemId, itemData in pairs(shopData) do
		print("  ", itemData.name, "=", itemData.price, "coins")
	end
	print("========================================")

	switchTab("habitat")
	shopFrame.Visible = true
end)

-- Handle purchase feedback
buyResultRemote.OnClientEvent:Connect(function(success, message)
	if success then
		print("? Purchase successful:", message)
	else
		warn("? Purchase failed:", message)
	end
end)

print("? CLIENT: Habitat Shop Controller loaded!")