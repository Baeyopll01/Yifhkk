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

function Module:LoadSettings()
	if not (readfile and writefile and isfile and isfolder and makefolder) then
		return warn("Executor Not Support Save System")
	end
	if not isfolder(Module.SaveFolder) then
		makefolder(Module.SaveFolder)
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
			if k == "Save Position" then
				self.Config[k] = DecodeCFrame(v) or v
			else
				self.Config[k] = v
			end
		end
	else
		warn("Failed to load config file")
	end

end

function Module:SaveSettings()
	if not (readfile and writefile and isfile and isfolder and makefolder) then
		return warn("Executor Not Support Save System")
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
	if success and encoded then
		if not isfile(SaveFile) or readfile(SaveFile) ~= encoded then
			writefile(SaveFile,encoded)
		end
	end
end

function Module:AddToggle(where,data)
	if self.Config[data.Title] == nil then
		self.Config[data.Title] = data.Default or false
	end
	local threadRunning
	local toggle = where:Toggle({
		Title = data.Title,
		Desc = data.Desc,
		Value = self.Config[data.Title],
		Callback = function(state)
			self.Config[data.Title] = state
            local fn = self.Ex_Function[data.Title]
            if fn then
                if state then
                    threadRunning = task.spawn(function()
                        fn(self)
                    end)
                elseif threadRunning then
                    task.cancel(threadRunning)
                    threadRunning = nil
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
		Multi = data.Multi or false,
		Values = data.Values,
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
            Default = self.Config[data.Title],
        },
	    Callback = function(value)
			self.Config[data.Title] = value
            if data.Callback then
                data.Callback(value)
            end
            self:SaveSettings()
		end})
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

Module:LoadSettings()
Module:SetSaveFolder(Module.SaveFolder)
Module:GetConfig(Module.Config)
Module:Ex_Function(Module.Ex_Function)

return Module
