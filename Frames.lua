local addonName, addonPrivate = ...

setfenv(1, addonPrivate)

local function pairwise(table)
	local index = 0
	return function()
		index = index + 1
		if not table[index+1] then
			return
		else
			return table[index], table[index+1]
		end
	end
end


local function GetPoints(frame)
	local function GetPointFunc(frame, index)
	   index = index + 1
	   if index > frame:GetNumPoints() then
	      return
	   else
	      return index, frame:GetPoint(index)
	   end
	end
   return GetPointFunc, frame, 0
end


function Grimoire.SequentialLayout(frames, markerFrame)
	for prev, next in pairwise(frames) do
		local points = {}
		for _, point, relativeTo, relativePoint, xOffset, yOffset in GetPoints(next) do
			if relativeTo == markerFrame then
				points[#points+1] = {point, prev, relativePoint, xOffset, yOffset}
			else
				points[#points+1] = {point, relativeTo, relativePoint, xOffset, yOffset}
			end
		end
		next:ClearAllPoints()
		for _, point in ipairs(points) do
			next:SetPoint(unpack(point))
		end
	end
end

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

--[[
---  Options
]]--

local L = Locales.L()

Grimoire.Options = {}
local Options = Grimoire.Options

Options.controls = {}
Options.controlsList = {}

function Options:addControl(control)
	local controls = self.controlsList
	controls[#controls+1] = control
end

local optionsEvents = Events:new()

optionsEvents:Register("ADDON_LOADED", function(event, name)
	if name ~= addonName then return end
	Options.current = _G.Grimoire_Config or {}
	_G.Grimoire_Config = nil
	Options:setDefaults()
end)

optionsEvents:Register("PLAYER_LOGOUT", function(...)
	_G.Grimoire_Config = Options.current
end)

function Options:OnInterfaceOptionsRefresh()
	self.editing = deepcopy(self.current)
	for _, control in ipairs(self.controlsList) do
		control:updateControl(self.editing)
	end
end

function Options:OnInterfaceOptionsOkay()
	self.current = self.editing
	self.editing = nil
end

function Options:OnInterfaceOptionsDefault()
	self.current = {}
	self:setDefaults()
end

function Options:OnInterfaceOptionsCancel()
	self.editing = nil
end

function Options:setDefaults()
	for _, control in ipairs(self.controlsList) do
		control:setDefault(self.current)
	end
end

local CheckOption = {}

function CheckOption:new(object)
	object = object or {}
	setmetatable(object, self)
	self.__index = self
	return object
end

local function OptionCheckboxSound(checkbox)
	if (checkbox:GetChecked()) then
		PlaySound("igMainMenuOptionCheckBoxOn");
	else
		PlaySound("igMainMenuOptionCheckBoxOff");
	end
end

function CheckOption:attach(checkbox)
	checkbox.text:SetText(self.text)
	checkbox.tooltipText = self.tooltip
	self.checkbox = checkbox
	checkbox:SetScript("OnClick", function (checkbox, button, down)
		OptionCheckboxSound(checkbox, button, down)
		self:setValue(Options.editing, checkbox:GetChecked())
		self:onControlUpdate()
	end)
end

function CheckOption:updateControl(table)
	self.checkbox:SetChecked(self:getValue(table))
	self:onControlUpdate()
end

function CheckOption:onControlUpdate()
end

do
	local control = CheckOption:new{
		text=L"CHECK_THE_WORLD",
		tooltip=L"CHECK_THE_WORLD_TOOLTIP",
	}

	function control:setValue(table, value)
		table.world = value
	end

	function control:getValue(table)
		return table.world
	end
	
	function control:setDefault(table)
		if self:getValue(table) == nil then
			self:setValue(table, true)
		end
	end

	Options:addControl(control)
	Options.controls.world = control
	
end

local instanceTypeControls

do
	local control = CheckOption:new{
		text=L"CHECK_INSTANCES",
		tooltip=L"CHECK_INSTANCES_TOOLTIP",
	}

	function control:setValue(table, value)
		table.instances = value
	end
	
	function control:getValue(table)
		return table.instances
	end
	
	function control:setDefault(table)
		if self:getValue(table) == nil then
			self:setValue(table, false)
		end
	end
	
	function control:onControlUpdate()
		instanceTypeControls:SetEnable(self.checkbox:GetChecked())
	end
	
	Options:addControl(control)
	Options.controls.instances = control
	
end

local InstanceTypeCheckOption = CheckOption:new()

function InstanceTypeCheckOption:new(object)
	object = object or {}
	setmetatable(object, self)
	self.__index = self
	return object
end

function InstanceTypeCheckOption:setValue(table, value)
	table.instanceTypes[self.instanceTypeId] = value
end

function InstanceTypeCheckOption:getValue(table)
	return table.instanceTypes[self.instanceTypeId]
end

function InstanceTypeCheckOption:setDefault(table)
	if self:getValue(table) == nil then
		self:setValue(table, false)
	end
end

local instanceTypes = {
	[1] = L"Normal Dungeon",
	[2] = L"Heroic Dungeon",
	[3] = L"Legacy Raid, 10 Player Normal",
	[4] = L"Legacy Raid, 25 Player Normal",
	[5] = L"Legacy Raid, 10 Player Heroic",
	[6] = L"Legacy Raid, 25 Player Heroic",
	[7] = L"Looking For Raid",
	[8] = L"Challenge Mode",
	[9] = L"40 Player",
	[11] = L"Heroic Scenario",
	[12] = L"Normal Scenario",
	[14] = L"Normal Raid",
	[15] = L"Heroic Raid",
	[16] = L"Mythic Raid",
	[17] = L"Looking For Raid",
	[18] = L"Event, Raid",
	[19] = L"Event, Party",
	[20] = L"Event, Scenario"
}

local MAX_INSTANCE_TYPE = 20

function Options:populateInstances(frame)
	instanceTypeControls = frame
	Options:addControl{
		setDefault = function(_, table)
			if table.instanceTypes == nil then
				table.instanceTypes = {}
			end
		end,
		updateControl = function()
		end
	}
	local previousCheckbox = nil
	local frameHeight, frameWidth = 0, 0
	for difficultyId = 1, MAX_INSTANCE_TYPE do
		local difficultyName = instanceTypes[difficultyId]
		if difficultyName then
			local checkbox = CreateFrame("CheckButton", nil, instanceTypeControls, "GrimoireOptionsCheckButtonTemplateSmall")
			if not previousCheckbox then
				checkbox:SetPoint("TOPLEFT", instanceTypeControls, "TOPLEFT")
			else
				checkbox:SetPoint("TOPLEFT", previousCheckbox, "BOTTOMLEFT", 0, 4)
				frameHeight = frameHeight + 4
			end
			frameHeight = frameHeight + checkbox:GetHeight()
			frameWidth = math.max(frameWidth, checkbox:GetWidth())
			local control = InstanceTypeCheckOption:new{
				text = difficultyName,
				instanceTypeId = difficultyId
			}
			control:attach(checkbox)
			Options:addControl(control)
			previousCheckbox = checkbox
		end
	end
	instanceTypeControls:SetHeight(frameHeight)
	instanceTypeControls:SetWidth(frameWidth)

	function instanceTypeControls:SetEnable(value)
		for _, button in ipairs(self.children) do
			if value then 
				button:Enable()
			else
				button:Disable()
			end
		end
	end

end
