local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")

_G.Name = nil
_G.AutoShoot = false

local ScreenGui = Instance.new("ScreenGui", game.CoreGui)

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0,260,0,330)
Main.Position = UDim2.new(0.3,0,0.3,0)
Main.BackgroundColor3 = Color3.fromRGB(25,25,25)
Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,10)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1,0,0,30)
Title.BackgroundColor3 = Color3.fromRGB(35,35,35)
Title.Text = "Select Player"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18
Instance.new("UICorner", Title).CornerRadius = UDim.new(0,10)

local Toggle = Instance.new("TextButton", Main)
Toggle.Size = UDim2.new(1,-10,0,30)
Toggle.Position = UDim2.new(0,5,0,35)
Toggle.BackgroundColor3 = Color3.fromRGB(45,45,45)
Toggle.TextColor3 = Color3.new(1,1,1)
Toggle.Text = "Auto Shoot : OFF"
Toggle.Font = Enum.Font.SourceSans
Toggle.TextSize = 16
Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0,8)

local Scroll = Instance.new("ScrollingFrame", Main)
Scroll.Size = UDim2.new(1,-10,1,-80)
Scroll.Position = UDim2.new(0,5,0,70)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 4

local UIList = Instance.new("UIListLayout", Scroll)
UIList.Padding = UDim.new(0,5)

local dragging, dragInput, mousePos, framePos
Main.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		mousePos = input.Position
		framePos = Main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

Main.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - mousePos
		Main.Position = UDim2.new(
			framePos.X.Scale,
			framePos.X.Offset + delta.X,
			framePos.Y.Scale,
			framePos.Y.Offset + delta.Y
		)
	end
end)

Toggle.MouseButton1Click:Connect(function()
	_G.AutoShoot = not _G.AutoShoot
	Toggle.Text = "Auto Shoot : "..(_G.AutoShoot and "ON" or "OFF")
end)

local function AddPlayer(v)
	if v == LocalPlayer then return end

	local Btn = Instance.new("TextButton")
	Btn.Size = UDim2.new(1,0,0,30)
	Btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
	Btn.TextColor3 = Color3.new(1,1,1)
	Btn.Text = v.Name
	Btn.Font = Enum.Font.SourceSans
	Btn.TextSize = 16
	Btn.Parent = Scroll

	Instance.new("UICorner", Btn).CornerRadius = UDim.new(0,8)

	Btn.MouseButton1Click:Connect(function()
		_G.Name = v.Name
		Title.Text = "Selected : "..v.Name
	end)
end

for _,v in ipairs(Players:GetPlayers()) do
	AddPlayer(v)
end

Players.PlayerAdded:Connect(AddPlayer)

Players.PlayerRemoving:Connect(function(plr)
	for _,v in ipairs(Scroll:GetChildren()) do
		if v:IsA("TextButton") and v.Text == plr.Name then
			v:Destroy()
		end
	end
end)

task.spawn(function()
	while task.wait() do
		pcall(function()
			if _G.AutoShoot and _G.Name then
				local target = Players:FindFirstChild(_G.Name)
				if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                    for i,v in next, LocalPlayer.Character:GetChildren() do 
                        if v:IsA("Tool") then
					        LocalPlayer.Character:FindFirstChild(v.Name).ShootEvent:FireServer(target.Character.HumanoidRootPart.Position)
                        end 
                    end 
				end
			end
		end)
	end
end)

task.spawn(function()
	while task.wait() do
		pcall(function()
			if _G.AutoShoot then
				local Gui = LocalPlayer.PlayerGui:FindFirstChild("WeaponGui")
				if Gui then
					local text = Gui.WeaponFrame.WeaponInfo.TextLabel.Text
					local Gun = tonumber(text:match("^(%d+)"))
					if Gun and Gun <= 0 then
                        for i,v in next, LocalPlayer.Character:GetChildren() do 
                            if v:IsA("Tool") then
                                LocalPlayer.Character:FindFirstChild(v.Name).ReloadEvent:FireServer()
                            end 
                        end 
						task.wait(1)
					end
				end
			end
		end)
	end
end)
