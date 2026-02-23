local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- ?? Find a free plot inside Workspace.PlotsF
local function findFreePlot()
	local folder = Workspace:FindFirstChild("PlotsF")
	if not folder then
		warn("? Folder 'PlotsF' not found in Workspace")
		return nil
	end

	for _, plot in pairs(folder:GetChildren()) do
		if plot:IsA("Part") and plot.Name:lower():match("^plot%d+$") then
			if not plot:GetAttribute("Owner") then
				return plot
			end
		end
	end

	return nil
end

-- ?? Update the sign text with the player's name
local function updateSign(plot, player)
	local signModel = plot:FindFirstChild("Sign")
	if not signModel or not signModel:IsA("Model") then
		warn("?? 'Sign' model not found in " .. plot.Name)
		return
	end

	local textPart = signModel:FindFirstChild("Text")
	if not textPart or not textPart:IsA("Part") then
		warn("?? 'Text' part not found in the Sign of " .. plot.Name)
		return
	end

	local gui = textPart:FindFirstChildOfClass("SurfaceGui")
	if not gui then
		warn("?? SurfaceGui not found in the 'Text' part of the Sign in " .. plot.Name)
		return
	end

	local label = gui:FindFirstChildOfClass("TextLabel")
	if label then
		label.Text = player.Name
	else
		warn("?? TextLabel not found in the SurfaceGui of the Sign in " .. plot.Name)
	end
end

-- ?? Reset sign when releasing a plot
local function clearSign(plot)
	local signModel = plot:FindFirstChild("Sign")
	if not signModel then return end

	local textPart = signModel:FindFirstChild("Text")
	if not textPart then return end

	local gui = textPart:FindFirstChildOfClass("SurfaceGui")
	if not gui then return end

	local label = gui:FindFirstChildOfClass("TextLabel")
	if label then
		label.Text = "FREE"
	end
end

-- ?? Assign a plot to a player
local function assignPlot(player)
	local plot = findFreePlot()
	if not plot then
		warn("? No available plots for " .. player.Name)
		return
	end

	plot:SetAttribute("Owner", player.UserId)
	player:SetAttribute("AssignedPlot", plot.Name)

	updateSign(plot, player)

	print("? Plot assigned:", plot.Name, "?", player.Name)
end

-- ?? Release plot when player leaves
local function releasePlot(player)
	local plotName = player:GetAttribute("AssignedPlot")
	if not plotName then return end

	local folder = Workspace:FindFirstChild("PlotsF")
	if not folder then return end

	local plot = folder:FindFirstChild(plotName)
	if plot and plot:GetAttribute("Owner") == player.UserId then
		plot:SetAttribute("Owner", nil)
		clearSign(plot)
		print("?? Plot released:", plot.Name)
	end
end

-- ?? Connect player events
Players.PlayerAdded:Connect(assignPlot)
Players.PlayerRemoving:Connect(releasePlot)
