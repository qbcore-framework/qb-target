local Config, Entities, Models, Zones, Bones, Players, Types, Intervals, ConfigFunctions, PlayerData = load(LoadResourceFile(GetCurrentResourceName(), 'config.lua'))()
local hasFocus, success, targetActive, sendData = false, false, false

-- TODO: optimize, fix required item for qbcore

if Config.ESX then
    Citizen.CreateThread(function()
        while ESX == nil do
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
            Citizen.Wait(0)
        end
			
        PlayerData = ESX.GetPlayerData()

        RegisterNetEvent('esx:playerLoaded')
        AddEventHandler('esx:playerLoaded', function()
            PlayerData = ESX.GetPlayerData()
        end)
                
        RegisterNetEvent('esx:setJob')
        AddEventHandler('esx:setJob', function(job)
            PlayerData.job = job
        end)
    end)
elseif Config.QBCore then
    Citizen.CreateThread(function()
        while QBCore == nil do
            TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
            Citizen.Wait(200)
        end
                
        PlayerData = QBCore.Functions.GetPlayerData()
        
        RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
        AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
            PlayerData = QBCore.Functions.GetPlayerData()
        end)			

        RegisterNetEvent('QBCore:Client:OnJobUpdate')
        AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
            PlayerData.job = JobInfo
        end)
    end)
else
    PlayerData = Config.NonFrameworkData()
end

-- Functions

function closeTarget()
    SendNUIMessage({response = "closeTarget"})
    SetNuiFocus(false, false)
    success, hasFocus, targetActive = false, false, false
    ClearInterval(1)
end

function leftTarget()
    SendNUIMessage({response = "leftTarget"})
    SetNuiFocus(false, false)
    success, hasFocus = false, false
end

function validTarget(options)
    SetNuiFocus(true, true)
    SetCursorLocation(0.5, 0.5)
    hasFocus = true
    SendNUIMessage({response = "validTarget", data = options})
end

local CheckOptions = function(data, entity, distance)
    if (data.distance == nil or distance <= data.distance)
	and (data.owner == nil or not data.owner or data.owner == NetworkGetNetworkIdFromEntity(PlayerPedId()))
	and (data.job == nil or not data.job or data.job == PlayerData.job.name or (Config.UseGrades and (Config.ESX and (data.job[PlayerData.job.name] and data.job[PlayerData.job.name] <= PlayerData.job.grade)) or (Config.QBCore and (data.job[PlayerData.job.name] and data.job[PlayerData.job.name] <= PlayerData.job.grade.level))))
	and (data.item == nil or not data.item or data.item and ConfigFunctions.ItemCount(data.item))
    and (data.shouldShow == nil or not data.shouldShow or data.shouldShow(entity)) then return true
	else return false end
end

local CheckRange = function(range, distance)
	for k, v in pairs(range) do
		if v == false and distance < k then return true
		elseif v == true and distance > k then return true end
	end
	return false
end

local CheckZone = function(entity, zone, distance)
    local send_options, send_distance = {}, {}
    for o, data in pairs(zone.targetoptions.options) do
        if CheckOptions(data, entity, distance) then
            local slot = #send_options + 1 
            send_options[slot] = data
            send_options[slot].entity = entity
            send_distance[data.distance] = true
        else 
            send_distance[data.distance] = false
        end
    end
    sendData = send_options
    if next(send_options) then
        local send_options = CloneTable(sendData)
        for k,v in pairs(send_options) do v.action = nil end
        success = true
        SendNUIMessage({response = "foundTarget"})

        SetEntityDrawOutline(entity, true)
        while success and targetActive do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local hit, coords, entity2 = RaycastCamera(-1)
            local distance = #(playerCoords - zone.center)

            if not zone:isPointInside(coords) then
                leftTarget()
                SetEntityDrawOutline(entity, false)
            end

            if (IsControlJustPressed(0, 25) or IsDisabledControlJustPressed(0, 25)) then
                validTarget(send_options)
                SetEntityDrawOutline(entity, false)
            elseif IsControlJustReleased(0, 19) and not hasFocus then
                closeTarget()
                SetEntityDrawOutline(entity, false)
            elseif CheckRange(send_distance, distance) then
                CheckZone(entity, zone, distance)
            end

            Citizen.Wait(5)
        end
        leftTarget()
        SetEntityDrawOutline(entity, false)
    end
end

local CheckEntity = function(entity, data, distance)
    local send_options, send_distance = {}, {}
    for o, data in pairs(data.options) do
        if CheckOptions(data, entity, distance) then 
            local slot = #send_options + 1 
            send_options[slot] = data
            send_options[slot].entity = entity
            send_distance[data.distance] = true
		else 
            send_distance[data.distance] = false
        end
    end
    sendData = send_options
    if next(send_options) then
        local send_options = CloneTable(sendData)
		for k,v in pairs(send_options) do v.action = nil end
        success = true
        SendNUIMessage({response = "foundTarget"})

        SetEntityDrawOutline(entity, true)
        while success and targetActive do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local hit, coords, entity2 = RaycastCamera()
			local distance = #(playerCoords - coords)

			if entity ~= entity2 then
                leftTarget()
                SetEntityDrawOutline(entity, false)
            end

            if (IsControlJustPressed(0, 25) or IsDisabledControlJustPressed(0, 25)) then
                validTarget(send_options)
                SetEntityDrawOutline(entity, false)
            elseif IsControlJustReleased(0, 19) and not hasFocus then
                closeTarget()
                SetEntityDrawOutline(entity, false)
            elseif CheckRange(send_distance, distance) then
				CheckEntity(entity, data, distance)
            end

            Citizen.Wait(5)
        end
        leftTarget()
        SetEntityDrawOutline(entity, false)
    end
end

local CheckBones = function(coords, entity, min, max, bonelist, checkData)
	local closestBone, closestDistance, closestPos, closestBoneName = -1, 20
	for k, v in pairs(bonelist) do
		local coords = coords
		if Bones[v] then
			local boneId = GetEntityBoneIndexByName(entity, v)
			local bonePos = GetWorldPositionOfEntityBone(entity, boneId)
			local distance = #(coords - bonePos)

			if closestBone == -1 or distance < closestDistance then
				closestBone, closestDistance, closestPos, closestBoneName = boneId, distance, bonePos, v
			end
		end
	end

    if closestBone == -1 then return false end

    if checkData and #(coords - closestPos) <= Bones[closestBoneName].distance then
        local data = Bones[closestBoneName]
        local send_options = {}
        for o, data in pairs(data.options) do
            if CheckOptions(data, entity) then 
                local slot = #send_options + 1 
                send_options[slot] = data
                send_options[slot].entity = entity
            end
        end
        sendData = send_options
        if next(send_options) then
            local send_options = CloneTable(sendData)
            for k,v in pairs(send_options) do v.action = nil end
            success = true
            SendNUIMessage({response = "foundTarget"})
            return true, send_options, closestBone, closestPos, closestBoneName
        end
    else
        return closestBone, closestPos, closestBoneName, Bones[closestBoneName].distance
    end

    return false
end

local RaycastCamera = function(flag)
    local cam = GetGameplayCamCoord()
    local direction = GetGameplayCamRot()
    direction = vector2(direction.x * math.pi / 180.0, direction.z * math.pi / 180.0)
	local num = math.abs(math.cos(direction.x))
	direction = vector3((-math.sin(direction.y) * num), (math.cos(direction.y) * num), math.sin(direction.x))
    local destination = vector3(cam.x + direction.x * 30, cam.y + direction.y * 30, cam.z + direction.z * 30)
    local rayHandle, result, hit, endCoords, surfaceNormal, entityHit = StartShapeTestLosProbe(cam, destination, flag or 30, PlayerPedId(), 0)
	repeat
		result, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)
		Citizen.Wait(0)
	until result ~= 1
	local entityType = GetEntityType(entityHit)
	if hit == 0 or entityType == 0 then
		rayHandle = StartShapeTestLosProbe(cam, destination, 30, PlayerPedId(), 0)
		repeat
			result, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)
			Citizen.Wait(0)
		until result ~= 1
		if hit == 0 then Citizen.Wait(20) else entityType = GetEntityType(entityHit) end
		return hit, endCoords, entityHit, entityType
	else
		return hit, endCoords, entityHit, entityType
	end
end

local CloneTable = function(t)
	if type(t) ~= 'table' then return t end

	local meta = getmetatable(t)
	local target = {}

	for k,v in pairs(t) do
		if type(v) == 'table' then
			target[k] = CloneTable(v)
		else
			target[k] = v
		end
	end

	setmetatable(target, meta)

	return target
end

local CreateInterval = function(name, interval, action, clear)
	local self = {interval = interval}
	CreateThread(function()
		local name, action, clear = name, action, clear
		repeat
			action()
			Citizen.Wait(self.interval)
		until self.interval == -1
		if clear then clear() end
		Intervals[name] = nil
	end)
	return self
end

local SetInterval = function(name, interval, action, clear)
	if Intervals[name] and interval then 
        Intervals[name].interval = interval
	else
		Intervals[name] = CreateInterval(name, interval, action, clear)
	end
end

local ClearInterval = function(name)
	Intervals[name].interval = -1
end

--NUI CALL BACKS

RegisterNUICallback('selectTarget', function(option, cb)
    if not targetActive then return end

    SetNuiFocus(false, false)

    success, hasFocus, targetActive = false, false, false
	
    local data = sendData[option]
    
    Citizen.CreateThread(function()
        Citizen.Wait(50)
        if data.type ~= nil then
            if data.type == "client" then
                TriggerEvent(data.event, data)
            elseif data.type == "server" then
                TriggerServerEvent(data.event, data)
            elseif data.type == "function" then
                _G[data.event](data)
            elseif data.type == "action" then
                data.action(data.entity)
            end
        else
            TriggerEvent(data.event, data)
        end
    end)
end)

RegisterNUICallback('closeTarget', function(data, cb)
    SetNuiFocus(false, false)
    success = false
    hasFocus = false
    targetActive = false

    if data == 'nonMessage' then
        ClearInterval(1)
    end
end)

RegisterNUICallback('leftTarget', function(data, cb)
    SetNuiFocus(false, false)
    success = false
    hasFocus = false
end)

-- Main function to open the target

function playerTargetEnable()
    if success then return end

    targetActive = true

    SendNUIMessage({response = "openTarget"})

    SetInterval(1, 5, function()
        if hasFocus then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
        end
        DisablePlayerFiring(PlayerId(), true)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 47, true)
        DisableControlAction(0, 58, true)
        DisableControlAction(0, 140, true)
        DisableControlAction(0, 141, true)
        DisableControlAction(0, 142, true)
        DisableControlAction(0, 143, true)
        DisableControlAction(0, 263, true)
        DisableControlAction(0, 264, true)
        DisableControlAction(0, 257, true)
    end)
    
    while targetActive do
        local sleep = 10
        local plyCoords = GetEntityCoords(PlayerPedId())
        local hit, coords, entity, entityType = RaycastCamera()

        if hit then
            if entityType ~= 0 then
                if NetworkGetEntityIsNetworked(entity) then
                    local data = Entities[NetworkGetNetworkIdFromEntity(entity)]
                    if data and not success then
                        CheckEntity(entity, data, #(plyCoords - coords))
                    end
                end

                if entityType == 1 then
                    if IsPedAPlayer(entity) and not success then
                        CheckEntity(entity, Players, #(plyCoords - coords))
                    else
                        local data = Models[GetEntityModel(entity)]
                        if not success and data then
                            CheckEntity(entity, data, #(plyCoords - coords))
                        end
                    end
                elseif entityType == 2 then
                    if not success then
                        local min, max = GetModelDimensions(GetEntityModel(entity))
                        local check, sendoptions, closestBone, closestPos, closestBoneName = CheckBones(coords, entity, min, max, Config.VehicleBones, true)
                        if check then
                            SetEntityDrawOutline(entity, true)
                            while success and targetActive do
                                local playerCoords = GetEntityCoords(PlayerPedId())
                                local hit, coords, entity2 = RaycastCamera()
                                local closestBone2, closestPos2, closestBoneName2, distance = CheckBones(coords, entity, min, max, Config.VehicleBones, false)
                                
                                if closestBone ~= closestBone2 or #(coords - closestPos2) > distance or #(playerCoords - coords) > 1.1 then
                                    leftTarget()
                                    SetEntityDrawOutline(entity, false)
                                end

                                if (IsControlJustPressed(0, 25) or IsDisabledControlJustPressed(0, 25)) then
                                    validTarget(sendoptions)
                                    SetEntityDrawOutline(entity, false)
                                elseif IsControlJustReleased(0, 19) and not hasFocus then
                                    closeTarget()
                                    SetEntityDrawOutline(entity, false)
                                end

                                Citizen.Wait(5)
                            end
                            leftTarget()
                            SetEntityDrawOutline(entity, false)
                        end
                    end

                    local data = Models[GetEntityModel(entity)]
                    if data and not success then
                        CheckEntity(entity, data, #(plyCoords - coords))
                    end
                else
                    local data = Models[GetEntityModel(entity)]
                    if data and not success then
                        CheckEntity(entity, data, #(plyCoords - coords))
                    end
                end
            end

            if not success then
                local data = Types[entityType]
                if data then 
                    CheckEntity(data, entity, #(plyCoords - coords))
                end

                local hit, coords, entity = RaycastCamera(-1)
                if hit then
                    for _, zone in pairs(Zones) do
                        if zone:isPointInside(coords) then
                            CheckZone(entity, zone, #(plyCoords - zone.center))
                        end
                    end
                end
            else sleep = sleep + 10 end
        end
        Citizen.Wait(sleep)
    end
    closeTarget()
end

--Exports

local AddCircleZone = function(name, center, radius, options, targetoptions)
    Zones[name] = CircleZone:Create(center, radius, options)
    Zones[name].targetoptions = targetoptions
end

local AddBoxZone = function(name, center, length, width, options, targetoptions)
    Zones[name] = BoxZone:Create(center, length, width, options)
    Zones[name].targetoptions = targetoptions
end

local AddPolyzone = function(name, points, options, targetoptions)
    Zones[name] = PolyZone:Create(points, options)
    Zones[name].targetoptions = targetoptions
end

local AddTargetModel = function(models, parameters)
	local distance, options = parameters.distance or 2, parameters.options
	for _, model in pairs(models) do
		if type(model) == 'string' then model = GetHashKey(model) end
		if not Models[model] then Models[model] = {} end
		for k, v in pairs(options) do
			if not v.distance then v.distance = distance end
			Models[model][v.event] = v
		end
	end
end

local AddTargetEntity = function(entity, parameters)
	Entities[entity] = parameters
end

local AddTargetBone = function(bones, parameteres)
    for _, bone in pairs(bones) do
        Bones[bone] = parameteres
    end
end

local AddEntityZone = function(name, entity, options, targetoptions)
	Zones[name] = EntityZone:Create(entity, options)
	Zones[name].targetoptions = targetoptions
end

local RemoveZone = function(name)
    if not Zones[name] then return end
    if Zones[name].destroy then
        Zones[name]:destroy()
    end
    Zones[name] = nil
end

local AddType = function(type, parameters)
	local distance, options = parameters.distance or 2, parameters.options
	for k, v in pairs(options) do
		if not v.distance then v.distance = distance end
		Types[type][v.event] = v
	end
end

local RemoveType = function(type, events)
	for k, v in pairs(events) do
		Types[type][v] = nil
	end
end

local RemovePlayer = function(type, events)
	for k, v in pairs(events) do
		Players[v.event] = nil
	end
end

local AddPlayer = function(parameters)
	local distance, options = parameters.distance or 2, parameters.options
	for k, v in pairs(options) do
		if not v.distance then v.distance = distance end
		Players[v.event] = v
	end
end

local RemoveZone = function(name)
	if not Zones[name] then return end
	if Zones[name].destroy then
		Zones[name]:destroy()
	end
	Zones[name] = nil
end

local RemoveTargetModel = function(models, events)
	for _, model in pairs(models) do
		if type(model) == 'string' then model = GetHashKey(model) end
		for k, v in pairs(events) do
			if Models[model] then
				Models[model][v] = nil
			end
		end
	end
end

local AddPed = function(parameters) AddType(1, parameters) end

local AddVehicle = function(parameters) AddType(2, parameters) end

local AddObject = function(parameters) AddType(3, parameters) end

local AddPlayer = function(parameters) AddPlayer(parameters) end

local RemovePed = function(events) RemoveType(1, events) end

local RemoveVehicle = function(events) RemoveType(2, events) end

local RemoveObject = function(events) RemoveType(3, events) end

local RemovePlayer = function(events) RemoveType(1, events) end

exports("AddCircleZone", AddCircleZone)

exports("AddBoxZone", AddBoxZone)

exports("AddPolyzone", AddPolyzone)

exports("AddTargetModel", AddTargetModel)

exports("AddTargetEntity", AddTargetEntity)

exports("AddTargetBone", AddTargetBone)

exports("AddEntityZone", AddEntityZone)

exports("AddPed", AddPed)

exports("AddVehicle", AddVehicle)

exports("AddObject", AddObject)

exports("AddPlayer", AddPlayer)

exports("RemovePed", RemovePed)

exports("RemoveZone", RemoveZone)

exports("RemoveTargetModel", RemoveTargetModel)

exports("RemoveVehicle", RemoveVehicle)

exports("RemoveObject", RemoveObject)

exports("RemovePlayer", RemovePlayer)

exports("Raycast", RaycastCamera)

Citizen.CreateThread(function()
    RegisterKeyMapping("+playerTarget", "Player Targeting", "keyboard", "LMENU")
    RegisterCommand('+playerTarget', playerTargetEnable, false)
    RegisterCommand('-playerTarget', closeTarget, false)
    TriggerEvent("chat:removeSuggestion", "/+playerTarget")
    TriggerEvent("chat:removeSuggestion", "/-playerTarget")

    if next(Config.BoxZones) then
        for k, v in pairs(Config.BoxZones) do
            AddBoxZone(v.name, v.coords, v.length, v.width, {
                name = v.name,
                heading = v.heading,
                debugPoly = v.debugPoly,
                minZ = v.minZ,
                maxZ = v.maxZ
            }, {
                options = v.options,
                distance = v.distance
            })
        end
    end

    if next(Config.CircleZones) then
        for k, v in pairs(Config.CircleZones) do
            AddCircleZone(v.name, v.coords, v.radius, {
                name = v.name,
                debugPoly = v.debugPoly,
            }, {
                options = v.options,
                distance = v.distance
            })
        end
    end

    if next(Config.TargetModels) then
        for k, v in pairs(Config.TargetModels) do
            AddTargetModel(v.models, {
                options = v.options,
                distance = v.distance
            })
        end
    end

    if next(Config.TargetEntities) then
        for k, v in pairs(Config.TargetEntities) do
            AddTargetEntity(v.entity, {
                options = v.options,
                distance = v.distance
            })
        end
    end

    if next(Config.TargetBones) then
        for k, v in pairs(Config.TargetBones) do
            AddTargetBone(v.bones, {
                options = v.options,
                distance = v.distance
            })
        end
    end

    if next(Config.EntityZones) then
        for k, v in pairs(Config.EntityZones) do
            AddEntityZone(v.name, v.entity, {
                name = v.name,
                heading = v.heading,
                debugPoly = v.debugPoly,
            }, {
                options = v.options,
                distance = v.distance,
            })
        end
    end

    if next(Config.PedOptions) then
        AddPed({options = Config.PedOptions.options, distance = Config.PedOptions.distance})
    end

    if next(Config.VehicleOptions) then
        AddVehicle({options = Config.VehicleOptions.options, distance = Config.VehicleOptions.distance})
    end

    if next(Config.ObjectOptions) then
        AddObject({options = Config.ObjectOptions.options, distance = Config.ObjectOptions.distance})
    end

    if next(Config.PlayerOptions) then
        AddPlayer({options = Config.PlayerOptions.options, distance = Config.PlayerOptions.distance})
    end
end)
