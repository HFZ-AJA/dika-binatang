-- Script ini harus diletakkan di StarterPlayer/StarterPlayerScripts
-- GUI Taskbar & Fitur Lari Cepat dengan input angka
-- VERSI TETAP: Tidak hilang saat respawn + Tombol Close

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local DEFAULT_RUN_SPEED = 16
local JUMP_POWER = 100

local isFast = false
local inputSpeed = nil
local ScreenGui = nil
local MainFrame = nil
local ToggleButton = nil
local SpeedButton = nil
local SpeedInputBox = nil
local JumpButton = nil
local isInfiniteJumpActive = false
local jumpConnection = nil


-----------------------------------------------------------
-- UNIVERSAL CHECKPOINT DETECTION SYSTEM
-----------------------------------------------------------

local function isCheckpoint(obj)
	if not obj or not obj:IsA("BasePart") then return false end
	if obj.Transparency == 1 then return false end
	if obj.Size.Magnitude < 2 then return false end

	local name = string.lower(obj.Name)

	if string.find(name, "checkpoint") then return true end
	if string.find(name, "spawn") then return true end
	if string.find(name, "cp") then return true end
	if string.find(name, "stage") then return true end

	if obj:IsA("SpawnLocation") then return true end

	return false
end

local function getNearestCheckpoint(root)
	local nearest = nil
	local nearestDist = 999

	for _, obj in ipairs(workspace:GetDescendants()) do
		if isCheckpoint(obj) then
			local dist = (obj.Position - root.Position).Magnitude
			if dist < nearestDist and dist < 30 then
				nearest = obj
				nearestDist = dist
			end
		end
	end
	return nearest
end


-----------------------------------------------------------
-- SPRINT SYSTEM
-----------------------------------------------------------

local function setRunSpeed(button, speedBox)
	if not LocalPlayer or not LocalPlayer.Character then return end

	local character = LocalPlayer.Character
	local humanoid = character:FindFirstChildOfClass("Humanoid")
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
	if not LocalPlayer or not LocalPlayer.Character then return end

	local character = LocalPlayer.Character
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		isFast = false
		humanoid.WalkSpeed = DEFAULT_RUN_SPEED
		button.Text = "Sprint: OFF"
		button.BackgroundColor3 = Color3.new(1, 0, 0)
		if speedBox then
			speedBox.Text = ""
		end
	end
end


-----------------------------------------------------------
-- INFINITE JUMP
-----------------------------------------------------------

local function toggleInfiniteJump(button)
	isInfiniteJumpActive = not isInfiniteJumpActive

	if jumpConnection then
		jumpConnection:Disconnect()
		jumpConnection = nil
	end

	if isInfiniteJumpActive then
		jumpConnection = UserInputService.JumpRequest:Connect(function()
			if isInfiniteJumpActive and LocalPlayer and LocalPlayer.Character then
				local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end
		end)

		if LocalPlayer and LocalPlayer.Character then
			local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.JumpPower = JUMP_POWER
			end
		end
	else
		if LocalPlayer and LocalPlayer.Character then
			local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.JumpPower = 50
			end
		end
	end

	button.Text = isInfiniteJumpActive and "INFINITE JUMP: ON" or "INFINITE JUMP: OFF"
	button.BackgroundColor3 = isInfiniteJumpActive and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
end



-----------------------------------------------------------
-- AUTO WALK (UPGRADED + AUTO CHECKPOINT)
-----------------------------------------------------------

local autoWalkEnabled = false
local autoWalkConnection = nil

local function StopAutoWalk()
	autoWalkEnabled = false
	if autoWalkConnection then
		autoWalkConnection:Disconnect()
		autoWalkConnection = nil
	end
end

Players.LocalPlayer.CharacterAdded:Connect(function()
	StopAutoWalk()
end)


local function toggleAutoWalk()
	if not LocalPlayer or not LocalPlayer.Character then return end

	autoWalkEnabled = not autoWalkEnabled

	if autoWalkEnabled then
		autoWalkConnection = RunService.Heartbeat:Connect(function(dt)
			local char = LocalPlayer.Character
			if not char then return end

			local humanoid = char:FindFirstChildOfClass("Humanoid")
			local root = char:FindFirstChild("HumanoidRootPart")
			if not humanoid or not root then return end


			-------------------------------------------------------
			-- 1. PRIORITAS: DEKATI CHECKPOINT TERDEKAT
			-------------------------------------------------------
			local cp = getNearestCheckpoint(root)
			if cp then
				local dir = (cp.Position - root.Position).Unit
				humanoid:Move(Vector3.new(dir.X, 0, dir.Z), false)

				if (cp.Position - root.Position).Magnitude < 5 then
					humanoid.Jump = true
				end
				return
			end


			-------------------------------------------------------
			-- 2. AUTO WALK NORMAL + HINDARI RINTANGAN
			-------------------------------------------------------
			local f = root.CFrame.LookVector
			humanoid:Move(Vector3.new(f.X, 0, f.Z), false)

			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Blacklist
			rayParams.FilterDescendantsInstances = {char}

			local hit = workspace:Raycast(
				root.Position + Vector3.new(0, 2, 0),
				root.CFrame.LookVector * 4,
				rayParams
			)

			if hit then
				humanoid.Jump = true
			end
		end)

	else
		StopAutoWalk()
	end
end




-----------------------------------------------------------
-- GUI SYSTEM (TIDAK DIUBAH)
-----------------------------------------------------------

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


local function createGUI()
	if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
		local oldGui = LocalPlayer.PlayerGui:FindFirstChild("DikDik26_Tools")
		if oldGui then
			oldGui:Destroy()
		end
	end

	ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "DikDik26_Tools"
	ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	ScreenGui.ResetOnSpawn = false

	----------------------------------------------------
	-- BUTTON PEMBUKA MENU
	----------------------------------------------------
	ToggleButton = Instance.new("TextButton")
	ToggleButton.Name = "ToggleButton"
	ToggleButton.Size = UDim2.new(0, 120, 0, 40)
	ToggleButton.Position = UDim2.new(0, 20, 0, 20)
	ToggleButton.BackgroundColor3 = Color3.fromRGB(25, 5, 33)
	ToggleButton.Text = "⚜️DikDik26⚜️"
	ToggleButton.TextColor3 = Color3.new(1,1,1)
	ToggleButton.Font = Enum.Font.GothamBold
	ToggleButton.TextSize = 18
	ToggleButton.Parent = ScreenGui

	----------------------------------------------------
	-- MAIN MENU FRAME
	----------------------------------------------------
	MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0, 320, 0, 210)
	MainFrame.Position = UDim2.new(0.5, -160, 0.5, -105)
	MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	MainFrame.BorderSizePixel = 2
	MainFrame.BorderColor3 = Color3.fromRGB(255,255,255)
	MainFrame.Visible = false
	MainFrame.Parent = ScreenGui

	local TaskBarScroll = Instance.new("ScrollingFrame")
	TaskBarScroll.Name = "TaskBarScroll"
	TaskBarScroll.Size = UDim2.new(1, -20, 1, -60)
	TaskBarScroll.Position = UDim2.new(0, 10, 0, 50)
	TaskBarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	TaskBarScroll.ScrollBarThickness = 6
	TaskBarScroll.BackgroundTransparency = 1
	TaskBarScroll.Parent = MainFrame

	local Title = Instance.new("TextLabel")
	Title.Name = "Title"
	Title.Size = UDim2.new(1, 0, 0, 40)
	Title.Position = UDim2.new(0,0,0,0)
	Title.BackgroundTransparency = 1
	Title.Text = "⚜️ DikDik26 ⚜️"
	Title.TextColor3 = Color3.fromRGB(255, 215, 0)
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 22
	Title.Parent = MainFrame

	local CloseButton = Instance.new("TextButton")
	CloseButton.Name = "CloseButton"
	CloseButton.Size = UDim2.new(0, 30, 0, 30)
	CloseButton.Position = UDim2.new(1, -35, 0, 5)
	CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	CloseButton.Text = "X"
	CloseButton.TextColor3 = Color3.new(1,1,1)
	CloseButton.Font = Enum.Font.GothamBold
	CloseButton.TextSize = 18
	CloseButton.Parent = MainFrame
	CloseButton.MouseButton1Click:Connect(function()
		MainFrame.Visible = false
	end)

	----------------------------------------------------
	-- SPEED CONTROLS
	----------------------------------------------------
	local SpeedControlsFrame = Instance.new("Frame")
	SpeedControlsFrame.Name = "SpeedControlsFrame"
	SpeedControlsFrame.Size = UDim2.new(0.9, 0, 0, 95)
	SpeedControlsFrame.Position = UDim2.new(0.05, 0, 0, 45)
	SpeedControlsFrame.BackgroundTransparency = 1
	SpeedControlsFrame.Parent = TaskBarScroll

	SpeedInputBox = Instance.new("TextBox")
	SpeedInputBox.Name = "SpeedInputBox"
	SpeedInputBox.Size = UDim2.new(1, 0, 0, 30)
	SpeedInputBox.Position = UDim2.new(0, 0, 0, 0)
	SpeedInputBox.BackgroundColor3 = Color3.fromRGB(60,60,80)
	SpeedInputBox.TextColor3 = Color3.new(1,1,1)
	SpeedInputBox.Font = Enum.Font.Gotham
	SpeedInputBox.TextSize = 16
	SpeedInputBox.PlaceholderText = "Enter speed (ex: 40)"
	SpeedInputBox.Text = ""
	SpeedInputBox.Parent = SpeedControlsFrame

	SpeedButton = Instance.new("TextButton")
	SpeedButton.Name = "SpeedButton"
	SpeedButton.Size = UDim2.new(1, 0, 0, 30)
	SpeedButton.Position = UDim2.new(0, 0, 0, 35)
	SpeedButton.BackgroundColor3 = Color3.new(1,0,0)
	SpeedButton.Font = Enum.Font.SourceSansBold
	SpeedButton.TextSize = 16
	SpeedButton.Text = "Sprint: OFF"
	SpeedButton.Parent = SpeedControlsFrame
	SpeedButton.MouseButton1Click:Connect(function()
		setRunSpeed(SpeedButton, SpeedInputBox)
	end)

	local ResetSpeedButton = Instance.new("TextButton")
	ResetSpeedButton.Name = "ResetSpeedButton"
	ResetSpeedButton.Size = UDim2.new(1, 0, 0, 25)
	ResetSpeedButton.Position = UDim2.new(0, 0, 0, 70)
	ResetSpeedButton.BackgroundColor3 = Color3.fromRGB(120,120,120)
	ResetSpeedButton.Font = Enum.Font.SourceSansBold
	ResetSpeedButton.TextSize = 14
	ResetSpeedButton.Text = "RESET SPEED TO NORMAL"
	ResetSpeedButton.TextColor3 = Color3.new(1,1,1)
	ResetSpeedButton.Parent = SpeedControlsFrame
	ResetSpeedButton.MouseButton1Click:Connect(function()
		resetRunSpeed(SpeedButton, SpeedInputBox)
	end)

	----------------------------------------------------
	-- INFINITE JUMP
	----------------------------------------------------
	JumpButton = Instance.new("TextButton")
	JumpButton.Name = "JumpButton"
	JumpButton.Size = UDim2.new(0.9, 0, 0, 40)
	JumpButton.Position = UDim2.new(0.05, 0, 0, 150)
	JumpButton.BackgroundColor3 = Color3.new(1,0,0)
	JumpButton.Font = Enum.Font.SourceSansBold
	JumpButton.TextSize = 16
	JumpButton.Text = "INFINITE JUMP: OFF"
	JumpButton.Parent = TaskBarScroll
	JumpButton.MouseButton1Click:Connect(function()
		toggleInfiniteJump(JumpButton)
	end)

	----------------------------------------------------
	-- AUTO WALK BUTTON
	----------------------------------------------------
	local TaskBarAutoWalk = Instance.new("TextButton")
	TaskBarAutoWalk.Name = "TaskBarAutoWalk"
	TaskBarAutoWalk.Size = UDim2.new(0.9, 0, 0, 40)
	TaskBarAutoWalk.Position = UDim2.new(0.05, 0, 0, 200)
	TaskBarAutoWalk.BackgroundColor3 = Color3.new(0, 0.5, 1)
	TaskBarAutoWalk.Font = Enum.Font.SourceSansBold
	TaskBarAutoWalk.TextSize = 16
	TaskBarAutoWalk.Text = "Auto Walk: OFF"
	TaskBarAutoWalk.Parent = TaskBarScroll
	TaskBarAutoWalk.MouseButton1Click:Connect(function()
		toggleAutoWalk()
		if autoWalkEnabled then
			TaskBarAutoWalk.Text = "Auto Walk: ON"
			TaskBarAutoWalk.BackgroundColor3 = Color3.new(0,1,0)
		else
			TaskBarAutoWalk.Text = "Auto Walk: OFF"
			TaskBarAutoWalk.BackgroundColor3 = Color3.new(0,0.5,1)
		end
	end)

	local function updateCanvas()
		local maxY = 0
		for _, child in ipairs(TaskBarScroll:GetChildren()) do
			if child:IsA("GuiObject") then
				local bottom = child.Position.Y.Offset + child.Size.Y.Offset
				if bottom > maxY then
					maxY = bottom
				end
			end
		end
		TaskBarScroll.CanvasSize = UDim2.new(0, 0, 0, maxY + 10)
	end
	updateCanvas()

	ToggleButton.MouseButton1Click:Connect(function()
		MainFrame.Visible = not MainFrame.Visible
	end)

	makeDraggable(ToggleButton)
end



-----------------------------------------------------------
-- INIT
-----------------------------------------------------------

local function initialize()
	if not LocalPlayer then
		Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
		LocalPlayer = Players.LocalPlayer
	end

	createGUI()

	LocalPlayer.CharacterAdded:Connect(function(character)
		task.wait(0.1)
		if not ScreenGui or not ScreenGui.Parent then
			createGUI()
		end

		if isInfiniteJumpActive then
			local humanoid = character:WaitForChild("Humanoid")
			if humanoid then
				humanoid.JumpPower = JUMP_POWER
			end
		end
	end)

	print("Developer Testing GUI 'DikDik26' Loaded Successfully.")
end

initialize()
