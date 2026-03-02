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
	self.ExList[name] = self.ExList[name] or {}
	self.Threads[name] = self.Threads[name] or {}
	self._RunningFlags = self._RunningFlags or {}

	return function(func)
		table.insert(self.ExList[name], {
			Callback = func,
			Restart = true 
		})
		if self.Config[name] then
			self:RunEx(name)
		end
	end
end

function Module:RunEx(name)
	if not self.ExList[name] then return end
	self.Threads[name] = self.Threads[name] or {}
	if #self.Threads[name] > 0 then return end
	self.Config[name] = true
	for _, data in ipairs(self.ExList[name]) do
		local thread = task.spawn(function()
			local success, err = xpcall(function()
				data.Callback(self)
			end, debug.traceback)
			if not success then
				warn("Ex Error:", name, err)
			end
		end)
		table.insert(self.Threads[name], thread)
	end
end

function Module:StopEx(name)
	self.Config[name] = false
	self._RunningFlags[name] = false

	if self.Threads[name] then
		for _, thread in ipairs(self.Threads[name]) do
			pcall(task.cancel, thread)
		end
		self.Threads[name] = {}
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
				pcall(data.Callback, text)
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