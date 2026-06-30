local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local xrayActive = false
local XRAY_TRANSPARENCY = 0.25 

-- Elements we want to completely IGNORE so they stay fully visible
local IGNORE_LIST = {
	["Diamond"] = true,
	["Iron"] = true,
	["Gold"] = true,
	["Coal"] = true,
	["Ore"] = true,
	["Chest"] = true,
	["Spawner"] = true
}

local activeHighlights = {}

-- Checks if a block should get a red outline (Dirt / Netherrack types)
local function shouldOutline(name)
	local lowerName = string.lower(name)
	if string.find(lowerName, "grass") then return false end
	return string.find(lowerName, "dirt") ~= nil or string.find(lowerName, "nether") ~= nil or string.find(lowerName, "mud") ~= nil
end

local function manageHighlight(part, state)
	if state then
		if shouldOutline(part.Name) and not activeHighlights[part] then
			local hl = Instance.new("Highlight")
			hl.FillTransparency = 1 
			hl.OutlineColor = Color3.fromRGB(255, 85, 85)
			hl.OutlineTransparency = 0.1 
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop 
			hl.Adornee = part
			hl.Parent = part
			activeHighlights[part] = hl
		end
	else
		if activeHighlights[part] then
			activeHighlights[part]:Destroy()
			activeHighlights[part] = nil
		end
	end
end

local function applyXray()
	for _, object in ipairs(workspace:GetDescendants()) do
		-- Target any physical block mesh or part in the world
		if object:IsA("BasePart") then
			local nameLower = string.lower(object.Name)
			
			-- Make sure we aren't hiding your own character, tools, or skyboxes
			local isPlayer = object:FindFirstAncestorOfClass("Model") and object:FindFirstAncestorOfClass("Model"):FindFirstChild("Humanoid")
			local isImportant = false
			
			for ignoreName, _ in pairs(IGNORE_LIST) do
				if string.find(string.lower(object.Name), string.lower(ignoreName)) then
					isImportant = true
					break
				end
			end
			
			-- If it's a regular world block, apply X-ray
			if not isPlayer and not isImportant and object.CanCollide then
				if xrayActive then
					if not object:GetAttribute("OriginalTransparency") then
						object:SetAttribute("OriginalTransparency", object.Transparency)
					end
					object.Transparency = XRAY_TRANSPARENCY
					manageHighlight(object, true)
				else
					local original = object:GetAttribute("OriginalTransparency")
					if original then object.Transparency = original end
					manageHighlight(object, false)
				end
			end
		end
	end
end

-- =========================================================
-- MOVEABLE MOBILE UI BUTTON
-- =========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XrayMobileGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local xrayButton = Instance.new("TextButton")
xrayButton.Size = UDim2.new(0, 110, 0, 50)
xrayButton.Position = UDim2.new(0.02, 0, 0.35, 0)
xrayButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
xrayButton.TextColor3 = Color3.fromRGB(255, 255, 255)
xrayButton.TextSize = 16
xrayButton.Text = "X-Ray: OFF"
xrayButton.Font = Enum.Font.SourceSansBold
xrayButton.Active = true
xrayButton.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = xrayButton

xrayButton.MouseButton1Click:Connect(function()
	xrayActive = not xrayActive
	if xrayActive then
		xrayButton.Text = "X-Ray: ON"
		xrayButton.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
	else
		xrayButton.Text = "X-Ray: OFF"
		xrayButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	end
	applyXray()
end)

-- Dragging logic
local dragging = false
local dragInput, dragStart, startPos

xrayButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = xrayButton.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)

xrayButton.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		xrayButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

workspace.DescendantAdded:Connect(function(object)
	if xrayActive and object:IsA("BasePart") and object.CanCollide then
		local isPlayer = object:FindFirstAncestorOfClass("Model") and object:FindFirstAncestorOfClass("Model"):FindFirstChild("Humanoid")
		if not isPlayer then
			object:SetAttribute("OriginalTransparency", object.Transparency)
			object.Transparency = XRAY_TRANSPARENCY
			manageHighlight(object, true)
		end
	end
end)
