local Module = {}

repeat task.wait() until game:IsLoaded()
	and game.Players.LocalPlayer
	and game.Players.LocalPlayer.Character
	and game.Players.LocalPlayer:FindFirstChild("PlayerGui")

local Service = setmetatable({}, {
	__index = function(_, k)
		return cloneref(game:GetService(k))
	end
})

local Players = Service.Players
local LocalPlayer = Players.LocalPlayer
local HttpService = Service.HttpService

Module.Config = {}
Module.ExList = {}
Module.Threads = {}
Module.SaveFolder = "SmoothX"
Module.SaveFile = nil

local LastSave = ""
local Saving = false

function Module:GetConfig(key)
	return self.Config[key]
end

function Module:SetConfig(key, value)
	self.Config[key] = value
	self:Save()
end

function Module:SetSaveFolder(folderName)
	self.SaveFolder = folderName
	self.SaveFile = self.SaveFolder .. ".json"
end

function Module:EnsureFolder()
	if not isfolder(self.SaveFolder) then
		pcall(makefolder, self.SaveFolder)
	end
end

function Module:Save()
	if Saving then return end
	if not (readfile and writefile and isfile and isfolder and makefolder) then return end
	if not self.SaveFile then
		self:SetSaveFolder(self.SaveFolder)
	end
	Saving = true
	self:EnsureFolder()
	local success, encoded = pcall(function()
		return HttpService:JSONEncode(self.Config)
	end)
	if success and encoded and encoded ~= LastSave then
		pcall(writefile, self.SaveFile, encoded)
		LastSave = encoded
	end
	Saving = false
end

function Module:Load()
	if not (readfile and isfile) then return end
	if not self.SaveFile then
		self:SetSaveFolder(self.SaveFolder)
	end
	self:EnsureFolder()
	if not isfile(self.SaveFile) then
		self:Save()
		return
	end
	local success, data = pcall(function()
		return HttpService:JSONDecode(readfile(self.SaveFile))
	end)
	if success and type(data) == "table" then
		for k, v in next, data do
			self.Config[k] = v
		end
	end
end

function Module:Ex(name)
	return function(func)
		self.ExList[name] = func

		if self.Config[name] and not self.Threads[name] then
			task.defer(function()
				self:RunEx(name)
			end)
		end
	end
end

function Module:Noclip(name)
	while task.wait(0.1) do
        pcall(function()
            if not anticlip and name then
                for _, v in pairs(LocalPlayer.Character:GetChildren()) do
                    if v:IsA("BasePart") then
                        if v.CanCollide then
                            v.CanCollide = false
                        end
                    end
                end
                if not LocalPlayer.Character:FindFirstChild("HumanoidRootPart"):FindFirstChild("Velocity") then
                    local bv = Instance.new("BodyVelocity")
                    bv.Name = "Velocity"
                    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bv.Velocity = Vector3.new(0, 0, 0)
                    bv.Parent = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                end
            else
                local vel = LocalPlayer.Character:FindFirstChild("HumanoidRootPart"):FindFirstChild("Velocity")
                if vel then
                    vel:Destroy()
                end
                for _, v in pairs(LocalPlayer.Character:GetChildren()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = true
                    end
                end
            end
        end)
    end
end 

function Module:RunEx(name)
	if not self.ExList[name] then return end
	if self.Threads[name] then return end

	self.Config[name] = true

	self.Threads[name] = task.spawn(function()
		xpcall(function()
			self.ExList[name](self)
		end,function(err)
			warn("Ex Error:", name, err)
		end)

		self.Threads[name] = nil
	end)
end

function Module:StopEx(name)
	self.Config[name] = false

	if self.Threads[name] then
		task.cancel(self.Threads[name])
		self.Threads[name] = nil
	end
end

function Module:StopAll()
	for name,_ in pairs(self.Threads) do
		self:StopEx(name)
	end
end

function Module:Method()
	local method = self:GetConfig("Select Method") or "Behind"
	local dist = self:GetConfig("Distance Farm") or 0

	if method == "Behind" then
		return CFrame.new(0, 0, dist)

	elseif method == "Below" then
		return CFrame.new(0, -dist, 0)
			* CFrame.Angles(math.rad(90), 0, 0)

	elseif method == "Upper" then
		return CFrame.new(0, dist, 0)
			* CFrame.Angles(math.rad(-90), 0, 0)
	end

	return CFrame.new()
end


function Module:AddToggle(where,data)

	if self.Config[data.Title] == nil then
		self.Config[data.Title] = data.Default or false
	end
	local toggle = where:Toggle({
		Title = data.Title,
		Desc = data.Desc,
		Value = self.Config[data.Title],
		Callback = function(state)
			self:SetConfig(data.Title, state)
			if state then
				self:RunEx(data.Title)
			else
				self:StopEx(data.Title)
			end
			if data.Callback then
				pcall(data.Callback, state)
			end
		end
	})
	if self.Config[data.Title] and self.ExList[data.Title] then
		task.defer(function()
			self:RunEx(data.Title)
		end)
	end
	return toggle
end

function Module:AddButton(where,data)
	return where:Button({
		Title = data.Title,
		Desc = data.Desc,
		Locked = data.Locked or false,
		Callback = function()
			if data.Callback then
				pcall(data.Callback)
			end
		end
	})
end

function Module:AddInput(where,data)
	if self.Config[data.Title] == nil then
		self.Config[data.Title] = data.Value or ""
	end
	return where:Input({
		Title = data.Title,
		Desc = data.Desc,
		Value = self.Config[data.Title],
		InputIcon = data.InputIcon,
		Type = data.Type or "Input",
		Placeholder = data.Placeholder,
		Callback = function(text)
			self.Config[data.Title] = text
			self:Save()
			if data.Callback then
				pcall(function()
					data.Callback(text)
				end)
			end
		end
	})
end

function Module:AddDropdown(where,data)
	if self.Config[data.Title] == nil then
		self.Config[data.Title] = data.Value
	end
	return where:Dropdown({
		Title = data.Title,
		Desc = data.Desc,
		Multi = data.Multi or false,
		Values = data.Values,
		Value = self.Config[data.Title],
		Callback = function(option)
			self:SetConfig(data.Title, option)
			if data.Callback then
				pcall(data.Callback, option)
			end
		end
	})
end

function Module:AddSlider(where,data)
	if self.Config[data.Title] == nil then
		self.Config[data.Title] = data.Value.Default
	end
	return where:Slider({
		Title = data.Title,
		Desc = data.Desc,
		Step = data.Step or 1,
		Value = {
			Min = data.Value.Min,
			Max = data.Value.Max,
			Default = self.Config[data.Title],
		},

		Callback = function(value)
			self:SetConfig(data.Title, value)

			if data.Callback then
				pcall(data.Callback, value)
			end
		end
	})
end

return Module