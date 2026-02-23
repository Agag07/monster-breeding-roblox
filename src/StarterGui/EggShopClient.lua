-- EggShopClient.lua (Updated Version)
-- Put this as LocalScript inside your EggShopGui

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local screenGui = script.Parent

-- Get UI elements (matching your current structure)
local eggShopFrame = screenGui:WaitForChild("EggShopFrame")
local titleBar = eggShopFrame:WaitForChild("TitleBar")
local closeButton = titleBar:WaitForChild("CloseButton")
local contentFrame = eggShopFrame:WaitForChild("ContentFrame")

-- Create Title if it doesn't exist
local title = titleBar:FindFirstChild("Title")
if not title then
	title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -120, 1, 0)
	title.Position = UDim2.new(0, 20, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "?? EGG SHOP"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = titleBar
end

-- Create Result Frame if it doesn't exist
local resultFrame = screenGui:FindFirstChild("ResultFrame")
if not resultFrame then
	resultFrame = Instance.new("Frame")
	resultFrame.Name = "ResultFrame"
	resultFrame.Size = UDim2.new(0, 400, 0, 300)
	resultFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
	resultFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	resultFrame.BorderSizePixel = 0
	resultFrame.Visible = false
	resultFrame.Parent = screenGui

	local resultCorner = Instance.new("UICorner")
	resultCorner.CornerRadius = UDim.new(0, 12)
	resultCorner.Parent = resultFrame

	-- Result title
	local resultTitle = Instance.new("TextLabel")
	resultTitle.Name = "ResultTitle"
	resultTitle.Size = UDim2.new(1, 0, 0, 60)
	resultTitle.BackgroundTransparency = 1
	resultTitle.Text = "?? EGG PURCHASED! ??"
	resultTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
	resultTitle.TextSize = 20
	resultTitle.Font = Enum.Font.GothamBold
	resultTitle.Parent = resultFrame

	-- Egg name
	local eggNameLabel = Instance.new("TextLabel")
	eggNameLabel.Name = "EggNameLabel"
	eggNameLabel.Size = UDim2.new(1, -20, 0, 40)
	eggNameLabel.Position = UDim2.new(0, 10, 0, 70)
	eggNameLabel.BackgroundTransparency = 1
	eggNameLabel.Text = ""
	eggNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	eggNameLabel.TextSize = 24
	eggNameLabel.Font = Enum.Font.Gotham
	eggNameLabel.Parent = resultFrame

	-- Hatch time
	local hatchTimeLabel = Instance.new("TextLabel")
	hatchTimeLabel.Name = "HatchTimeLabel"
	hatchTimeLabel.Size = UDim2.new(1, -20, 0, 30)
	hatchTimeLabel.Position = UDim2.new(0, 10, 0, 120)
	hatchTimeLabel.BackgroundTransparency = 1
	hatchTimeLabel.Text = ""
	hatchTimeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	hatchTimeLabel.TextSize = 18
	hatchTimeLabel.Font = Enum.Font.Gotham
	hatchTimeLabel.Parent = resultFrame

	-- Instructions
	local instructionLabel = Instance.new("TextLabel")
	instructionLabel.Name = "InstructionLabel"
	instructionLabel.Size = UDim2.new(1, -20, 0, 50)
	instructionLabel.Position = UDim2.new(0, 10, 0, 160)
	instructionLabel.BackgroundTransparency = 1
	instructionLabel.Text = "Place this egg in an incubator to hatch it!"
	instructionLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
	instructionLabel.TextSize = 16
	instructionLabel.Font = Enum.Font.Gotham
	instructionLabel.TextWrapped = true
	instructionLabel.Parent = resultFrame

	-- OK button
	local okButton = Instance.new("TextButton")
	okButton.Name = "OkButton"
	okButton.Size = UDim2.new(0, 100, 0, 40)
	okButton.Position = UDim2.new(0.5, -50, 1, -60)
	okButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	okButton.Text = "OK"
	okButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	okButton.TextSize = 18
	okButton.Font = Enum.Font.GothamBold
	okButton.BorderSizePixel = 0
	okButton.Parent = resultFrame

	local okCorner = Instance.new("UICorner")
	okCorner.CornerRadius = UDim.new(0, 8)
	okCorner.Parent = okButton
end

-- Get result frame elements
local resultTitle = resultFrame:WaitForChild("ResultTitle")
local eggNameLabel = resultFrame:WaitForChild("EggNameLabel")
local hatchTimeLabel = resultFrame:WaitForChild("HatchTimeLabel")
local instructionLabel = resultFrame:WaitForChild("InstructionLabel")
local okButton = resultFrame:WaitForChild("OkButton")

-- Ensure UIGridLayout exists in ContentFrame
local gridLayout = contentFrame:FindFirstChild("UIGridLayout")
if not gridLayout then
	gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 240, 0, 160)
	gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = contentFrame
end

-- Remote events
local openEggShopRemote = ReplicatedStorage:WaitForChild("OpenEggShop")
local buyEggRemote = ReplicatedStorage:WaitForChild("BuyEgg")
local eggResultRemote = ReplicatedStorage:WaitForChild("EggResult")

-- Function to create egg cards
local function createEggCard(eggType, eggData, layoutOrder)
	local card = Instance.new("Frame")
	card.Name = eggType
	card.Size = UDim2.new(0, 240, 0, 160)
	card.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	card.BorderSizePixel = 0
	card.LayoutOrder = layoutOrder
	card.Parent = contentFrame

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = card

	-- Egg icon
	local eggIcon = Instance.new("TextLabel")
	eggIcon.Size = UDim2.new(0, 60, 0, 60)
	eggIcon.Position = UDim2.new(0, 15, 0, 15)
	eggIcon.BackgroundTransparency = 1
	eggIcon.Text = "??"
	eggIcon.TextSize = 40
	eggIcon.Parent = card

	-- Egg name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -90, 0, 25)
	nameLabel.Position = UDim2.new(0, 85, 0, 15)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = eggData.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 16
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	-- Price label
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(1, -90, 0, 20)
	priceLabel.Position = UDim2.new(0, 85, 0, 45)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "?? " .. eggData.price .. " Coins"
	priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	priceLabel.TextSize = 14
	priceLabel.Font = Enum.Font.Gotham
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.Parent = card

	-- Hatch time label
	local hatchLabel = Instance.new("TextLabel")
	hatchLabel.Size = UDim2.new(1, -20, 0, 25)
	hatchLabel.Position = UDim2.new(0, 10, 0, 85)
	hatchLabel.BackgroundTransparency = 1
	hatchLabel.Text = "?? Hatch Time: " .. eggData.hatchTime .. "s"
	hatchLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
	hatchLabel.TextSize = 12
	hatchLabel.Font = Enum.Font.Gotham
	hatchLabel.TextXAlignment = Enum.TextXAlignment.Left
	hatchLabel.Parent = card

	-- Buy button
	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(0, 80, 0, 30)
	buyButton.Position = UDim2.new(1, -90, 1, -40)
	buyButton.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
	buyButton.Text = "BUY"
	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyButton.TextSize = 14
	buyButton.Font = Enum.Font.GothamBold
	buyButton.BorderSizePixel = 0
	buyButton.Parent = card

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 6)
	buyCorner.Parent = buyButton

	-- Buy button functionality
	buyButton.MouseButton1Click:Connect(function()
		print("?? Buying egg:", eggType)
		buyEggRemote:FireServer(eggType)
		eggShopFrame.Visible = false
	end)

	-- Hover effects
	buyButton.MouseEnter:Connect(function()
		local tween = TweenService:Create(buyButton, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(80, 200, 80)
		})
		tween:Play()
	end)

	buyButton.MouseLeave:Connect(function()
		local tween = TweenService:Create(buyButton, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(60, 180, 60)
		})
		tween:Play()
	end)

	return card
end

-- Function to show purchase result
local function showResult(success, data)
	if success and data then
		resultTitle.Text = "?? EGG PURCHASED! ??"
		resultTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
		eggNameLabel.Text = data.name
		eggNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		hatchTimeLabel.Text = "Hatch Time: " .. data.hatchTime .. " seconds"
		hatchTimeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		instructionLabel.Text = "Place this egg in an incubator to hatch it!"
		instructionLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
	else
		resultTitle.Text = "? PURCHASE FAILED"
		resultTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
		eggNameLabel.Text = "Purchase Failed"
		eggNameLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		hatchTimeLabel.Text = data or "Unknown error"
		hatchTimeLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		instructionLabel.Text = ""
	end

	resultFrame.Visible = true

	-- Animate result popup
	local tween = TweenService:Create(resultFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 450, 0, 350)
	})
	tween:Play()
end

-- Event connections
closeButton.MouseButton1Click:Connect(function()
	eggShopFrame.Visible = false
end)

okButton.MouseButton1Click:Connect(function()
	resultFrame.Visible = false
	resultFrame.Size = UDim2.new(0, 400, 0, 300)
end)

-- Handle shop opening
openEggShopRemote.OnClientEvent:Connect(function(shopData)
	print("?? CLIENT: Received egg shop data!", shopData)

	-- Clear existing cards
	for _, child in pairs(contentFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Create cards for each egg type
	local order = 1
	for eggType, eggData in pairs(shopData) do
		createEggCard(eggType, eggData, order)
		order += 1
	end

	-- Update canvas size
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, math.ceil(order / 3) * 175)

	-- Show shop
	eggShopFrame.Visible = true
end)

-- Handle purchase results
eggResultRemote.OnClientEvent:Connect(showResult)

-- Initialize as hidden
eggShopFrame.Visible = false
resultFrame.Visible = false

print("? Egg Shop Controller loaded!")
