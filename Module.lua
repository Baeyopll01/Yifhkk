local Module = {}

repeat task.wait() until game:IsLoaded()
and game.Players.LocalPlayer
and game.Players.LocalPlayer.Character
and game.Players.LocalPlayer:FindFirstChild("PlayerGui")

local Service = setmetatable({},{
	__index = function(_,k)
		return cloneref(game:GetService(k))
	end
})

local Players = Service.Players
local LocalPlayer = Players.LocalPlayer
local HttpService = Service.HttpService

Module.Config = Module.Config or {}
Module.Ex_Function = Module.Ex_Function or {}

Module.SaveFolder = "SmoothX"
local SaveFile = Module.SaveFolder.."/Config.json"

local function EncodeCFrame(cf)
	local x,y,z = cf.Position.X,cf.Position.Y,cf.Position.Z
	local rx,ry,rz = cf:ToOrientation()
	return {X=x,Y=y,Z=z,RX=rx,RY=ry,RZ=rz}
end

local function DecodeCFrame(t)
	if typeof(t) == "table"
	and t.X and t.Y and t.Z
	and t.RX and t.RY and t.RZ then
		return CFrame.new(t.X,t.Y,t.Z) * CFrame.Angles(t.RX,t.RY,t.RZ)
	end
end

function Module:SetSaveFolder(folder)
	self.SaveFolder = folder
	SaveFile = folder.."/Config.json"
end

function Module:GetConfig(tbl)
	self.Config = tbl or self.Config
end

function Module:SetFun(tbl)
	self.Ex_Function = tbl or self.Ex_Function
end

function Module:Get(key)
	return self.Config[key]
end

function Module:Set(key,value)
	self.Config[key] = value
	self:SaveSettings()
end

function Module:LoadSettings()
	if not (readfile and writefile and isfile and isfolder and makefolder) then
		return warn("Executor Not Support Save System")
	end
	if not isfolder(self.SaveFolder) then
		makefolder(self.SaveFolder)
	end
	if not isfile(SaveFile) then
		self:SaveSettings()
		return
	end
	local success,data = pcall(function()
		return HttpService:JSONDecode(readfile(SaveFile))
	end)
	if success and type(data) == "table" then
		for k,v in next,data do
			if typeof(v) == "table" and v.X then
				self.Config[k] = DecodeCFrame(v) or v
			else
				self.Config[k] = v
			end
		end
	else
		warn("Failed to load config")
	end
end

function Module:SaveSettings()
	if not (readfile and writefile and isfile and isfolder and makefolder) then
		return
	end
	local saveData = {}
	for k,v in next,self.Config do
		if typeof(v) == "CFrame" then
			saveData[k] = EncodeCFrame(v)
		else
			saveData[k] = v
		end
	end
	local success,encoded = pcall(function()
		return HttpService:JSONEncode(saveData)
	end)
	if success then
		writefile(SaveFile,encoded)
	end
end

function Module:AddToggle(where,data)
	if self.Config[data.Title] == nil then
		self.Config[data.Title] = data.Default or false
	end
	local thread
	local toggle = where:Toggle({
		Title = data.Title,
		Desc = data.Desc,
		Value = self.Config[data.Title],
		Callback = function(state)
			self.Config[data.Title] = state
			local fn = self.Ex_Function[data.Title]
			if fn then
				if state then
					thread = task.spawn(function()
						pcall(fn,self)
					end)
				else
					if thread then
						task.cancel(thread)
						thread = nil
					end
				end
			end
			if data.Callback then
				data.Callback(state)
			end
			self:SaveSettings()
		end
	})
	return toggle
end

function Module:AddDropdown(where,data)
	if self.Config[data.Title] == nil then
		self.Config[data.Title] = data.Value
	end
	local dropdown = where:Dropdown({
		Title = data.Title,
		Desc = data.Desc,
		Values = data.Values,
		Multi = data.Multi or false,
		Value = self.Config[data.Title],
		Callback = function(option)
			self.Config[data.Title] = option
			if data.Callback then
				data.Callback(option)
			end
			self:SaveSettings()
		end
	})
	return dropdown
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

function Module:AddSlider(where,data)
	if self.Config[data.Title] == nil then
		self.Config[data.Title] = data.Value.Default
	end
	local slider = where:Slider({
		Title = data.Title,
		Desc = data.Desc,
		Step = data.Step or 1,
		Value = {
			Min = data.Value.Min,
			Max = data.Value.Max,
			Default = self.Config[data.Title]
		},
		Callback = function(value)
			self.Config[data.Title] = value
			if data.Callback then
				data.Callback(value)
			end
			self:SaveSettings()
		end
	})
	return slider
end

function Module:AddInput(where,data)
	if self.Config[data.Title] == nil then
		self.Config[data.Title] = data.Value or ""
	end
	local textbox = where:Input({
		Title = data.Title,
		Desc = data.Desc,
		Value = self.Config[data.Title],
		InputIcon = data.InputIcon,
		Type = data.Type or "Input",
		Placeholder = data.Placeholder,
		Callback = function(text)
			self.Config[data.Title] = text
			if data.Callback then
				data.Callback(text)
			end
			self:SaveSettings()

		end
	})
	return textbox
end

Module:SetSaveFolder(Module.SaveFolder)
Module:LoadSettings()
Module:GetConfig(Module.Config)
Module:SetFun(Module.Ex_Function)

return Module
