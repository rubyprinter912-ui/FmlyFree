local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local running = false
local loopId = 0
local lockConnection = nil

local JUMP_TIME = 4
local WAIT_TIME = 4

local BLUE = Color3.fromRGB(65, 105, 255)
local DARK_BLUE = Color3.fromRGB(45, 70, 190)

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "FmlyFree"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(300, 190)
main.Position = UDim2.new(0.5, -150, 0.5, -95)
main.BackgroundColor3 = Color3.fromRGB(25, 27, 35)
main.BorderSizePixel = 0
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 15)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(20, 15)
title.Size = UDim2.new(1, -40, 0, 30)
title.Font = Enum.Font.GothamBold
title.Text = "Fmly Free"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromOffset(20, 45)
subtitle.Size = UDim2.new(1, -40, 0, 20)
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "Farm automation"
subtitle.TextColor3 = Color3.fromRGB(150, 155, 170)
subtitle.TextSize = 13
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = main

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Position = UDim2.fromOffset(20, 72)
status.Size = UDim2.new(1, -40, 0, 20)
status.Font = Enum.Font.GothamMedium
status.Text = "? Stopped"
status.TextColor3 = Color3.fromRGB(150, 155, 170)
status.TextSize = 13
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = main

local button = Instance.new("TextButton")
button.Position = UDim2.new(0, 20, 1, -60)
button.Size = UDim2.new(1, -40, 0, 45)
button.BackgroundColor3 = BLUE
button.BorderSizePixel = 0
button.Font = Enum.Font.GothamBold
button.Text = "Launch Farm It"
button.TextColor3 = Color3.new(1, 1, 1)
button.TextSize = 15
button.AutoButtonColor = false
button.Parent = main

Instance.new("UICorner", button).CornerRadius = UDim.new(0, 10)

--==================================================
-- DRAGGING
--==================================================

local dragging = false
local dragStart
local startPosition

main.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPosition = main.Position
	end
end)

main.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart

		main.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end
end)

--==================================================
-- CHARACTER
--==================================================

local function getCharacter()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")

	return character, humanoid, root
end

--==================================================
-- REMOVE LOCK
--==================================================

local function removeLock()
	if lockConnection then
		lockConnection:Disconnect()
		lockConnection = nil
	end
end

--==================================================
-- START LOCK AT CURRENT POSITION
--==================================================

local function lockCurrentPosition(root)

	removeLock()

	local fixedCFrame = root.CFrame

	lockConnection = RunService.Heartbeat:Connect(function()

		if not running then
			return
		end

		if root and root.Parent then
			root.CFrame = fixedCFrame
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end

	end)

end

--==================================================
-- STOP
--==================================================

local function stopFarm()

	running = false
	loopId += 1

	removeLock()

	local character = player.Character

	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			humanoid.Jump = false
		end
	end

	button.Text = "Launch Farm It"
	button.BackgroundColor3 = BLUE
	status.Text = "? Stopped"

end

--==================================================
-- START
--==================================================

local function startFarm()

	local character, humanoid, root = getCharacter()

	running = true
	loopId += 1

	local thisLoop = loopId

	button.Text = "STOP"
	button.BackgroundColor3 = DARK_BLUE

	task.spawn(function()

		while running and thisLoop == loopId do

			--==========================================
			-- JUMPING: LOCK POSITION
			--==========================================

			status.Text = "? Jumping"

			lockCurrentPosition(root)

			local jumpEnd = os.clock() + JUMP_TIME

			while running
				and thisLoop == loopId
				and os.clock() < jumpEnd do

				humanoid.Jump = true
				humanoid:ChangeState(
					Enum.HumanoidStateType.Jumping
				)

				task.wait(0.15)

			end

			if not running or thisLoop ~= loopId then
				break
			end

			--==========================================
			-- WAITING: FREE MOVEMENT
			--==========================================

			removeLock()

			humanoid.Jump = false

			status.Text = "? Waiting"

			local waitEnd = os.clock() + WAIT_TIME

			while running
				and thisLoop == loopId
				and os.clock() < waitEnd do

				-- No position lock here.
				-- You can walk and jump normally.

				task.wait(0.1)

			end

		end

		removeLock()

	end)

end

--==================================================
-- BUTTON
--==================================================

button.MouseButton1Click:Connect(function()

	if running then
		stopFarm()
	else
		startFarm()
	end

end)