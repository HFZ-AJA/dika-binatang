-- Script ini harus diletakkan di StarterPlayer/StarterPlayerScripts
-- GUI Taskbar & Fitur Lari Cepat dengan input angka

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local DEFAULT_RUN_SPEED = 16

local isFast = false
local inputSpeed = nil

local function setRunSpeed(button, speedBox)
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local speedValue = tonumber(speedBox.Text)
		if speedValue and speedValue > 0 then
			isFast = true
			humanoid.WalkSpeed = speedValue
			button.Text = "Sprint: Active (" .. speedValue .. ")"
			button.BackgroundColor3 = Color3.new(0, 1, 0)
		else
			isFast = false
			humanoid.WalkSpeed = DEFAULT_RUN_SPEED
			button.Text = "Sprint: OFF"
			button.BackgroundColor3 = Color3.new(1, 0, 0)
		end
	end
end

local function resetRunSpeed(button, speedBox)
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		isFast = false
		humanoid.WalkSpeed = DEFAULT_RUN_SPEED
		button.Text = "Sprint: OFF"
		button.BackgroundColor3 = Color3.new(1, 0, 0)
		speedBox.Text = ""
	end
end

local JUMP_POWER = 100
local isInfiniteJumpActive = false

local function toggleInfiniteJump(button)
	isInfiniteJumpActive = not isInfiniteJumpActive
	if isInfiniteJumpActive then
		LocalPlayer.CharacterAdded:Connect(function(char)
			local human = char:WaitForChild("Humanoid")
			human:SetAttribute("CanJump", true)
			human.JumpPower = JUMP_POWER
		end)
		UserInputService.JumpRequest:Connect(function()
			if isInfiniteJumpActive and LocalPlayer.Character then
				LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end)
	else
		if LocalPlayer.Character then
			LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = 50
		end
	end
	button.Text = isInfiniteJumpActive and "INFINITE JUMP: ON" or "INFINITE JUMP: OFF"
	button.BackgroundColor3 = isInfiniteJumpActive and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
end

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DikDik26_Tools"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Toggle Button (hanya ini yang muncul di awal)
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 120, 0, 40)
ToggleButton.Position = UDim2.new(0, 20, 0, 20)
ToggleButton.BackgroundColor3 = Color3.fromRGB(25, 5, 33)
ToggleButton.Text = "⚜️DikDik26⚜️"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 18
ToggleButton.Parent = ScreenGui

-- MainFrame (Taskbar)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 210)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -105)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

-- Title
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚜️ DikDik26 ⚜️"
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 22
Title.Parent = MainFrame

-- Kelompok Fitur Lari Cepat (Speed Controls)
local SpeedControlsFrame = Instance.new("Frame")
SpeedControlsFrame.Name = "SpeedControlsFrame"
SpeedControlsFrame.Size = UDim2.new(0.9, 0, 0, 95)
SpeedControlsFrame.Position = UDim2.new(0.05, 0, 0, 45)
SpeedControlsFrame.BackgroundTransparency = 1
SpeedControlsFrame.Parent = MainFrame

-- Input Speed TextBox (1)
local SpeedInputBox = Instance.new("TextBox")
SpeedInputBox.Name = "SpeedInputBox"
SpeedInputBox.Size = UDim2.new(1, 0, 0, 30)
SpeedInputBox.Position = UDim2.new(0, 0, 0, 0)
SpeedInputBox.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
SpeedInputBox.TextColor3 = Color3.fromRGB(255,255,255)
SpeedInputBox.Font = Enum.Font.Gotham
SpeedInputBox.TextSize = 16
SpeedInputBox.PlaceholderText = "Enter the speed number (eg: 40)"
SpeedInputBox.Text = ""
SpeedInputBox.Parent = SpeedControlsFrame

-- Tombol Lari Cepat (2)
local SpeedButton = Instance.new("TextButton")
SpeedButton.Name = "SpeedButton"
SpeedButton.Size = UDim2.new(1, 0, 0, 30)
SpeedButton.Position = UDim2.new(0, 0, 0, 35)
SpeedButton.BackgroundColor3 = Color3.new(1, 0, 0)
SpeedButton.Font = Enum.Font.SourceSansBold
SpeedButton.TextSize = 16
SpeedButton.Text = "Sprint: OFFF"
SpeedButton.Parent = SpeedControlsFrame
SpeedButton.MouseButton1Click:Connect(function() setRunSpeed(SpeedButton, SpeedInputBox) end)

-- Tombol Reset Kecepatan (3)
local ResetSpeedButton = Instance.new("TextButton")
ResetSpeedButton.Name = "ResetSpeedButton"
ResetSpeedButton.Size = UDim2.new(1, 0, 0, 25)
ResetSpeedButton.Position = UDim2.new(0, 0, 0, 70)
ResetSpeedButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
ResetSpeedButton.Font = Enum.Font.SourceSansBold
ResetSpeedButton.TextSize = 14
ResetSpeedButton.Text = "RESET SPEED TO NORMAL"
ResetSpeedButton.TextColor3 = Color3.fromRGB(255,255,255)
ResetSpeedButton.Parent = SpeedControlsFrame
ResetSpeedButton.MouseButton1Click:Connect(function() resetRunSpeed(SpeedButton, SpeedInputBox) end)

-- Tombol Infinite Jump (di bawah speed controls)
local JumpButton = Instance.new("TextButton")
JumpButton.Name = "JumpButton"
JumpButton.Size = UDim2.new(0.9, 0, 0, 40)
JumpButton.Position = UDim2.new(0.05, 0, 0, 150)
JumpButton.BackgroundColor3 = Color3.new(1, 0, 0)
JumpButton.Font = Enum.Font.SourceSansBold
JumpButton.TextSize = 16
JumpButton.Text = "INFINITE JUMP: OFF"
JumpButton.Parent = MainFrame
JumpButton.MouseButton1Click:Connect(function() toggleInfiniteJump(JumpButton) end)

-- LOGIKA OPEN/CLOSE
ToggleButton.MouseButton1Click:Connect(function()
	MainFrame.Visible = not MainFrame.Visible
end)

-- DRAG & DROP ToggleButton
local function makeDraggable(guiObject)
	local dragging = false
	local dragStart = nil
	local startPos = nil

	guiObject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = guiObject.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			guiObject.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

makeDraggable(ToggleButton)

print("Developer Testing GUI 'DikDik26' Berhasil Dimuat.")
