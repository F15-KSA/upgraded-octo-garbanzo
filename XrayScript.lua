local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local xrayActive = false
local XRAY_TRANSPARENCY = 0.25 

-- 1. Non-dirt filler blocks that will become see-through
local OTHER_FILLER = {
	["Stone"] = true,
	["Deepslate"] = true,
	["Netherrack"] = true,
	["SoulSand"] = true,
	["EndStone"] = true
}

local activeHighlights = {}

-- 2. Smart function to automatically catch any block containing the word "dirt"
local function isDirtBlock(name)
	local lowerName = string.lower(name)
	-- Explicitly ignores grass blocks so they don't get lines
	if string.find(lowerName, "grass") then return false end 
	-- Catches "Dirt", "dirt", "CoarseDirt", "dirt_block", etc.
	return string.find(lowerName, "dirt") ~= nil or string.find(lowerName, "mud") ~= nil
end

-- 3. Handles adding and removing the outlines smoothly
local function manageHighlight(part, state)
	if state then
		-- Only outlines dirt variants and netherrack blocks
		if (isDirtBlock(part.Name) or part.Name == "Netherrack") and not activeHighlights[part] then
			local hl = Instance.new("Highlight")
			hl.FillTransparency = 1 
			hl.OutlineColor = Color3.fromRGB(255, 85, 85) -- Red outline
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

-- 4. Scans the workspace and applies changes
local function applyXray()
	for _, object in ipairs(workspace:GetDescendants()) do
		if object:IsA("BasePart") then
			if OTHER_FILLER[object.Name] or isDirtBlock(object.Name) then
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
-- CREATE MOVEABLE MOBILE UI BUTTON (PERFECT FOR IPAD)
-- =========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XrayMobileGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local xrayButton = Instance.new("TextButton")
xrayButton.Size = UDim2.new(0, 110, 0, 50)
xrayButton.Position = UDim2.new(0.1, 0, 0.4, 0) -- Starts on the mid-left side
xrayButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
xrayButton.TextColor3 = Color3.fromRGB(255, 255, 255)
xrayButton.TextSize = 18
xrayButton.Text = "X-Ray: OFF"
xrayButton.Font = Enum.Font.SourceSansBold
xrayButton.Active = true
xrayButton.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = xrayButton

-- Button Tap functionality
xrayButton.MouseButton1Click:Connect(function()
	xrayActive = not xrayActive
	if xrayActive then
		xrayButton.Text = "X-Ray: ON"
		xrayButton.BackgroundColor3 = Color3.fromRGB(255, 85, 85) -- Active color
	else
		xrayButton.Text = "X-Ray: OFF"
		xrayButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Idle color
	end
	applyXray()
end)

-- Draggable logic for touch screen dragging
local dragging = false
local dragInput, dragStart, startPos

xrayButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = xrayButton.Position
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
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

-- Updates newly placed/loaded terrain dynamically
workspace.DescendantAdded:Connect(function(object)
	if xrayActive and object:IsA("BasePart") and (OTHER_FILLER[object.Name] or isDirtBlock(object.Name)) then
		object:SetAttribute("OriginalTransparency", object.Transparency)
		object.Transparency = XRAY_TRANSPARENCY
		manageHighlight(object, true)
	end
end)
