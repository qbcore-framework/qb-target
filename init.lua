function Load(name)
	local resourceName = GetCurrentResourceName()
	local chunk = LoadResourceFile(resourceName, ('data/%s.lua'):format(name))
	if chunk then
		local err
		chunk, err = load(chunk, ('@@%s/data/%s.lua'):format(resourceName, name), 't')
		if err then
			error(('\n^1 %s'):format(err), 0)
		end
		return chunk()
	end
end

-------------------------------------------------------------------------------
-- Settings
-------------------------------------------------------------------------------

Config = {}

-- It's possible to interact with entities through walls so this should be low
Config.MaxDistance = 7.0

-- Enable debug options
Config.Debug = false

-- Supported values: true, false
Config.Standalone = false

-- Enable outlines around the entity you're looking at
Config.EnableOutline = false

-- Whether to have the target as a toggle or not
Config.Toggle = false

-- Draw a Sprite on the center of a PolyZone to hint where it's located
Config.DrawSprite = false

-- The default distance to draw the Sprite
Config.DrawDistance = 10.0

-- The color of the sprite in rgb, the first value is red, the second value is green, the third value is blue and the last value is alpha (opacity). Here is a link to a color picker to get these values: https://htmlcolorcodes.com/color-picker/
Config.DrawColor = {255, 255, 255, 255}

-- The color of the sprite in rgb when the PolyZone is targeted, the first value is red, the second value is green, the third value is blue and the last value is alpha (opacity). Here is a link to a color picker to get these values: https://htmlcolorcodes.com/color-picker/
Config.SuccessDrawColor = {30, 144, 255, 255}

-- The color of the outline in rgb, the first value is red, the second value is green, the third value is blue and the last value is alpha (opacity). Here is a link to a color picker to get these values: https://htmlcolorcodes.com/color-picker/
Config.OutlineColor = {255, 255, 255, 255}

-- Enable default options (Toggling vehicle doors)
Config.EnableDefaultOptions = true

-- Disable the target eye whilst being in a vehicle
Config.DisableInVehicle = false

-- Key to open the target eye, here you can find all the names: https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
Config.OpenKey = 'LMENU' -- Left Alt

-- Control for key press detection on the context menu, it's the Right Mouse Button by default, controls are found here https://docs.fivem.net/docs/game-references/controls/
Config.MenuControlKey = 238

-------------------------------------------------------------------------------
-- Target Configs
-------------------------------------------------------------------------------

-- These are all empty for you to fill in, refer to the .md files for help in filling these in

Config.CircleZones = {

}

Config.BoxZones = {

}

Config.PolyZones = {

}

Config.TargetBones = {

}

Config.TargetModels = {

}

Config.GlobalPedOptions = {

}

Config.GlobalVehicleOptions = {

}

Config.GlobalObjectOptions = {

}

Config.GlobalPlayerOptions = {

}

Config.Peds = {

}

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------
local function JobCheck() return true end
local function GangCheck() return true end
local function JobTypeCheck() return true end
local function ItemCheck() return true end
local function CitizenCheck() return true end

CreateThread(function()
	local state = GetResourceState('qb-core')
	if state ~= 'missing' then
		local timeout = 0
		while state ~= 'started' and timeout <= 100 do
			timeout += 1
			state = GetResourceState('qb-core')
			Wait(0)
		end
		Config.Standalone = false
	end
	if Config.Standalone then
		local firstSpawn = false
		local event = AddEventHandler('playerSpawned', function()
			SpawnPeds()
			firstSpawn = true
		end)
		-- Remove event after it has been triggered
		while true do
			if firstSpawn then
				RemoveEventHandler(event)
				break
			end
			Wait(1000)
		end
	else
		local QBCore = exports['qb-core']:GetCoreObject()
		local PlayerData = QBCore.Functions.GetPlayerData()

		ItemCheck = QBCore.Functions.HasItem

		JobCheck = function(job)
			if type(job) == 'table' then
				job = job[PlayerData.job.name]
				if job and PlayerData.job.grade.level >= job then
					return true
				end
			elseif job == 'all' or job == PlayerData.job.name then
				return true
			end
			return false
		end

		JobTypeCheck = function(jobType)
			if type(jobType) == 'table' then
				jobType = jobType[PlayerData.job.type]
				if jobType then
					return true
				end
			elseif jobType == 'all' or jobType == PlayerData.job.type then
				return true
			end
			return false
		end

		GangCheck = function(gang)
			if type(gang) == 'table' then
				gang = gang[PlayerData.gang.name]
				if gang and PlayerData.gang.grade.level >= gang then
					return true
				end
			elseif gang == 'all' or gang == PlayerData.gang.name then
				return true
			end
			return false
		end

		CitizenCheck = function(citizenid)
			return citizenid == PlayerData.citizenid or citizenid[PlayerData.citizenid]
		end

		RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
			PlayerData = QBCore.Functions.GetPlayerData()
			SpawnPeds()
		end)

		RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
			PlayerData = {}
			DeletePeds()
		end)

		RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
			PlayerData.job = JobInfo
		end)

		RegisterNetEvent('QBCore:Client:OnGangUpdate', function(GangInfo)
			PlayerData.gang = GangInfo
		end)

		RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
			PlayerData = val
		end)
	end
end)

function CheckOptions(data, entity, distance)
	if distance and data.distance and distance > data.distance then return false end
	if data.job and not JobCheck(data.job) then return false end
	if data.excludejob and JobCheck(data.excludejob) then return false end
	if data.jobType and not JobTypeCheck(data.jobType) then return false end
	if data.excludejobType and JobTypeCheck(data.excludejobType) then return false end
	if data.gang and not GangCheck(data.gang) then return false end
	if data.excludegang and GangCheck(data.excludegang) then return false end
	if data.item and not ItemCheck(data.item) then return false end
	if data.citizenid and not CitizenCheck(data.citizenid) then return false end
	if data.canInteract and not data.canInteract(entity, distance, data) then return false end
	return true
end
