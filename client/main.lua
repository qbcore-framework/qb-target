local Entities, Models, Zones, Bones, Events, Players = {}, {}, {}, {}, {}, {}
local hasFocus, success, targetActive = false, false, false

-- TODO: optimize, fix required item

Citizen.CreateThread(function()
    RegisterKeyMapping("+playerTarget", "Player Targeting", "keyboard", "LMENU")
    RegisterCommand('+playerTarget', playerTargetEnable, false)
    RegisterCommand('-playerTarget', closeTarget, false)
    TriggerEvent("chat:removeSuggestion", "/+playerTarget")
    TriggerEvent("chat:removeSuggestion", "/-playerTarget")
end)

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

Citizen.CreateThread(function()
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
end)

local Intervals = {}
function CreateInterval(name, interval, action, clear)
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

function SetInterval(name, interval, action, clear)
	if Intervals[name] and interval then Intervals[name].interval = interval
	else
		Intervals[name] = CreateInterval(name, interval, action, clear)
	end
end

 function ClearInterval(name)
	Intervals[name].interval = -1
end

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
        local plyCoords = GetEntityCoords(PlayerPedId())
        local hit, coords, entity = RayCastCamera(30)

        if hit then
            local entityType = GetEntityType(entity)
            if entityType ~= 0 then
                if NetworkGetEntityIsNetworked(entity) then
                    local data = Entities[NetworkGetNetworkIdFromEntity(entity)]
                    if data and #(plyCoords - coords) <= data.distance and not success then
                        local check, sendoptions = CheckEntity(entity, data)
                        if check then
                            SetEntityDrawOutline(entity, true)
                            while success and targetActive do
                                local playerCoords = GetEntityCoords(PlayerPedId())
                                local hit, coords, entity2 = RayCastCamera(30)

                                if (IsControlJustPressed(0, 25) or IsDisabledControlJustPressed(0, 25)) then
                                    validTarget(sendoptions)
                                    SetEntityDrawOutline(entity, false)
                                elseif IsControlJustReleased(0, 19) and not hasFocus then
                                    closeTarget()
                                    SetEntityDrawOutline(entity, false)
                                end

                                if entity ~= entity2 or #(playerCoords - coords) > data.distance then
                                    leftTarget()
                                    SetEntityDrawOutline(entity, false)
                                end

                                Citizen.Wait(0)
                            end
                            leftTarget()
                            SetEntityDrawOutline(entity, false)
                        end
                    end
                end

                if entityType == 1 then
                    if IsPedAPlayer(entity) and next(Players) then
                        local data = Players[entity]
                        if data and #(plyCoords - coords) <= data.distance and not success then
                            local check, sendoptions = CheckEntity(entity, data)
                            if check then
                                SetEntityDrawOutline(entity, true)
                                while success and targetActive do
                                    local playerCoords = GetEntityCoords(PlayerPedId())
                                    local hit, coords, entity2 = RayCastCamera(30)
    
                                    if (IsControlJustPressed(0, 25) or IsDisabledControlJustPressed(0, 25)) then
                                        validTarget(sendoptions)
                                        SetEntityDrawOutline(entity, false)
                                    elseif IsControlJustReleased(0, 19) and not hasFocus then
                                        closeTarget()
                                        SetEntityDrawOutline(entity, false)
                                    end

                                    if entity ~= entity2 or #(playerCoords - coords) > data.distance then 
                                        leftTarget()
                                        SetEntityDrawOutline(entity, false)
                                    end
    
                                    Citizen.Wait(0)
                                end
                                leftTarget()
                                SetEntityDrawOutline(entity, false)
                            end
                        end
                    else
                        local data = Models[GetEntityModel(entity)]
                        if data and #(plyCoords - coords) <= data.distance and not success then
                            local check, sendoptions = CheckEntity(entity, data)
                            if check then
                                while success and targetActive do
                                    local playerCoords = GetEntityCoords(PlayerPedId())
                                    local hit, coords, entity2 = RayCastCamera(30)
    
                                    if (IsControlJustPressed(0, 25) or IsDisabledControlJustPressed(0, 25)) then
                                        validTarget(sendoptions)
                                        SetEntityDrawOutline(entity, false)
                                    elseif IsControlJustReleased(0, 19) and not hasFocus then
                                        closeTarget()
                                        SetEntityDrawOutline(entity, false)
                                    end

                                    if entity ~= entity2 or #(playerCoords - coords) > data.distance then 
                                        leftTarget()
                                        SetEntityDrawOutline(entity, false)
                                    end
    
                                    Citizen.Wait(0)
                                end
                                leftTarget()
                                SetEntityDrawOutline(entity, false)
                            end
                        end
                    end
                elseif entityType == 2 then
                    if #(plyCoords - coords) <= 1.8 and not success then
                        local min, max = GetModelDimensions(GetEntityModel(entity))
                        local check, sendoptions, closestBone, closestPos, closestBoneName = CheckBones(coords, entity, min, max, Config.VehicleBones, true)
                        if check then
                            SetEntityDrawOutline(entity, true)
                            while success and targetActive do
                                local playerCoords = GetEntityCoords(PlayerPedId())
                                local hit, coords, entity2 = RayCastCamera(30)
                                local noneed, nope, closestBone2, closestPos2, closestBoneName2 = CheckBones(coords, entity, min, max, Config.VehicleBones, false)

                                if (IsControlJustPressed(0, 25) or IsDisabledControlJustPressed(0, 25)) then
                                    validTarget(sendoptions)
                                    SetEntityDrawOutline(entity, false)
                                elseif IsControlJustReleased(0, 19) and not hasFocus then
                                    closeTarget()
                                    SetEntityDrawOutline(entity, false)
                                end

                                if closestBone ~= closestBone2 or #(coords - closestPos2) > 1.8 or #(playerCoords - closestPos2) > 1.8 then
                                    leftTarget()
                                    SetEntityDrawOutline(entity, false)
                                end

                                Citizen.Wait(0)
                            end
                            leftTarget()
                            SetEntityDrawOutline(entity, false)
                        end
                    end

                    local data = Models[GetEntityModel(entity)]
                    if data and #(plyCoords - coords) <= data.distance and not success then
                        local check, sendoptions = CheckEntity(entity, data)
                        if check then
                            SetEntityDrawOutline(entity, true)
                            while success and targetActive do
                                local playerCoords = GetEntityCoords(PlayerPedId())
                                local hit, coords, entity2 = RayCastCamera(30)

                                if (IsControlJustPressed(0, 25) or IsDisabledControlJustPressed(0, 25)) then
                                    validTarget(sendoptions)
                                    SetEntityDrawOutline(entity, false)
                                elseif IsControlJustReleased(0, 19) and not hasFocus then
                                    closeTarget()
                                    SetEntityDrawOutline(entity, false)
                                end

                                if entity ~= entity2 or #(playerCoords - coords) > data.distance then 
                                    leftTarget()
                                    SetEntityDrawOutline(entity, false)
                                end

                                Citizen.Wait(0)
                            end
                            leftTarget()
                            SetEntityDrawOutline(entity, false)
                        end
                    end
                else
                    local data = Models[GetEntityModel(entity)]
                    if data and #(plyCoords - coords) <= data.distance and not success then
                        local check, sendoptions = CheckEntity(entity, data)
                        if check then
                            SetEntityDrawOutline(entity, true)
                            while success and targetActive do
                                local playerCoords = GetEntityCoords(PlayerPedId())
                                local hit, coords, entity2 = RayCastCamera(30)
                                
                                if (IsControlJustPressed(0, 25) or IsDisabledControlJustPressed(0, 25)) then
                                    validTarget(sendoptions)
                                    SetEntityDrawOutline(entity, false)
                                elseif IsControlJustReleased(0, 19) and not hasFocus then
                                    closeTarget()
                                    SetEntityDrawOutline(entity, false)
                                end

                                if entity ~= entity2 or #(playerCoords - coords) > data.distance then 
                                    leftTarget()
                                    SetEntityDrawOutline(entity, false)
                                end

                                Citizen.Wait(0)
                            end
                            leftTarget()
                            SetEntityDrawOutline(entity, false)
                        end
                    end
                end
            end

            if not success then
                local hit, coords, entity = RayCastCamera(-1)
                if hit then
                    for _, zone in pairs(Zones) do
                        if zone:isPointInside(coords) and #(plyCoords - zone.center) <= zone.targetoptions.distance and not success then
                            local check, sendoptions = CheckZone(entity, zone)
                            if check then
                                SetEntityDrawOutline(entity, true)
                                while success and targetActive do
                                    local playerCoords = GetEntityCoords(PlayerPedId())
                                    local hit, coords, entity2 = RayCastCamera(-1)

                                    if (IsControlJustPressed(0, 25) or IsDisabledControlJustPressed(0, 25)) then
                                        validTarget(sendoptions)
                                        SetEntityDrawOutline(entity, false)
                                    elseif IsControlJustReleased(0, 19) and not hasFocus then
                                        closeTarget()
                                        SetEntityDrawOutline(entity, false)
                                    end

                                    if not zone:isPointInside(coords) or #(playerCoords - zone.center) > zone.targetoptions.distance then
                                        leftTarget()
                                        SetEntityDrawOutline(entity, false)
                                    end

                                    Citizen.Wait(0)
                                end
                                leftTarget()
                                SetEntityDrawOutline(entity, false)
                            end
                        end
                    end
                end
            end
        end
        Citizen.Wait(0)
    end
    closeTarget()
end

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

--NUI CALL BACKS

RegisterNUICallback('selectTarget', function(data, cb)
    -- If the event isn't whitelisted or they're not using bt-target, return
    if Events[data.event] == nil or Events[data.event] == false then
        TriggerServerEvent("bt-target:loginvalidcall", data.event)
        return
    end
    if not targetActive then return end

    SetNuiFocus(false, false)

    success, hasFocus, targetActive = false, false, false
		
    if data.type ~= nil then
    	if data.type == "client" then
	        TriggerEvent(data.event, data)
    	elseif data.type == "server" then
	        TriggerServerEvent(data.event, data)
    	elseif data.type == "function" then
	        _G[data.event](data)
    	end
    else
	    TriggerEvent(data.event, data)
    end
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

function CheckOptions(data)
	if (not data.owner or data.owner == NetworkGetNetworkIdFromEntity(PlayerPedId()))
	and (not data.job or data.job == PlayerData.job.name or (Config.UseGrades and (Config.ESX and (data.job[PlayerData.job.name] and data.job[PlayerData.job.name] <= PlayerData.job.grade)) or (Config.QBCore and (data.job[PlayerData.job.name] and data.job[PlayerData.job.name] <= PlayerData.job.grade.level))))
	and (not data.item or data.item and ItemCount(data.item))
    and (data.shouldShow == nil or data.shouldShow()) then return true
	else return false end
end

function CheckZone(entity, zone, action)
    local send_options = {}
    for o, data in pairs(zone.targetoptions.options) do
        if CheckOptions(data) then
            local slot = #send_options + 1 
            send_options[slot] = data
            send_options[slot].entity = entity
        end
    end
    if #send_options > 0 then
        success = true
        SendNUIMessage({response = "foundTarget"})
        return true, send_options
    end

    return false
end

function CheckEntity(entity, data)
	local send_options = {}
	for o, data in pairs(data.options) do
		if CheckOptions(data) then 
			local slot = #send_options + 1 
			send_options[slot] = data
			send_options[slot].entity = entity
		end
	end
	if #send_options > 0 then
		success = true
        SendNUIMessage({response = "foundTarget"})
		return true, send_options
	end

    return false
end

function CheckBones(coords, entity, min, max, bonelist, action)
	local closestBone, closestDistance, closestPos, closestBoneName = -1, 20
	for k, v in pairs(bonelist) do
		local coords = coords
		if Bones[v] then
			local boneId = GetEntityBoneIndexByName(entity, v)
			local bonePos = GetWorldPositionOfEntityBone(entity, boneId)
			if v:find('bonnet') then
				local offset = GetOffsetFromEntityInWorldCoords(entity, 0, (max.y-min.y), 0)
				local y = coords.y + (coords.y - offset.y) / 3
				coords = vector3(coords.x, y, coords.z+0.1)
			else
				local offset = GetOffsetFromEntityInWorldCoords(entity, 0, (max.y-min.y), 0)
				local y = coords.y - (coords.y - offset.y) / 10
				coords = vector3(coords.x, y, coords.z)
			end

			local distance = #(coords - bonePos)
			if closestBone == -1 or distance < closestDistance then
				closestBone, closestDistance, closestPos, closestBoneName = boneId, distance, bonePos, v
			end
		end
	end

    if closestBone == -1 then return false end

    if checkData then
        local data = Bones[closestBoneName]
        local send_options = {}
        for o, data in pairs(data.options) do
            if CheckOptions(data) then 
                local slot = #send_options + 1 
                send_options[slot] = data
                send_options[slot].entity = entity
            end
        end
        if #send_options > 0 then
            success = true
            SendNUIMessage({response = "foundTarget"})
            return true, send_options
        end
    else
        return false, false, closestBone, closestPos, closestBoneName
    end

    return false
end

function RayCastCamera(flag)
    local cam = GetGameplayCamCoord()
    local direction = GetGameplayCamRot()
    direction = vector2(direction.x * math.pi / 180.0, direction.z * math.pi / 180.0)
	local num = math.abs(math.cos(direction.x))
	direction = vector3((-math.sin(direction.y) * num), (math.cos(direction.y) * num), math.sin(direction.x))
    local destination = vector3(cam.x + direction.x * 30, cam.y + direction.y * 30, cam.z + direction.z * 30)
    local rayHandle, result, hit, endCoords, surfaceNormal, entityHit = StartShapeTestLosProbe(cam, destination, flag or -1, PlayerPedId(), 0)
	repeat
		result, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)
		Citizen.Wait(0)
	until result ~= 1
	if hit == 0 then Citizen.Wait(20) end
	return hit, endCoords, entityHit
end

function GetNearestVehicle()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    if not (playerCoords and playerPed) then
        return
    end

    local pointB = GetEntityForwardVector(playerPed) * 0.001 + playerCoords

    local shapeTest = StartShapeTestCapsule(playerCoords.x, playerCoords.y, playerCoords.z, pointB.x, pointB.y, pointB.z, 1.0, 10, playerPed, 7)
    local _, hit, _, _, entity = GetShapeTestResult(shapeTest)

    return (hit == 1 and IsEntityAVehicle(entity)) and entity or false
end

function ItemCount(item)
	if Config.LindenInventory then return exports['linden_inventory']:CountItems(item)[item] > 0
    elseif Config.ESX then
		for k, v in pairs(PlayerData.inventory) do
			if v.name == item then
				return v.count > 0
			end
		end
    elseif Config.QBCore then
        for k, v in pairs(PlayerData.items) do
			if v.name == item then
				return v.amount > 0
			end
		end
	end
    Wait(300)

	return false
end

--Exports

function AddCircleZone(name, center, radius, options, targetoptions)
    Zones[name] = CircleZone:Create(center, radius, options)
    Zones[name].targetoptions = targetoptions

    for _, option in pairs(targetoptions.options) do
        Events[option.event] = true
    end
end

function AddBoxZone(name, center, length, width, options, targetoptions)
    Zones[name] = BoxZone:Create(center, length, width, options)
    Zones[name].targetoptions = targetoptions

    for _, option in pairs(targetoptions.options) do
        Events[option.event] = true
    end
end

function AddPolyzone(name, points, options, targetoptions)
    Zones[name] = PolyZone:Create(points, options)
    Zones[name].targetoptions = targetoptions

    for _, option in pairs(targetoptions.options) do
        Events[option.event] = true
    end
end

function AddTargetModel(models, parameteres)
    for _, model in pairs(models) do
        Models[model] = parameteres
    end

    for _, option in pairs(parameteres.options) do
        Events[option.event] = true
    end
end

function AddTargetEntity(entity, parameters)
	Entities[entity] = parameters

    for _, option in pairs(parameters.options) do
        Events[option.event] = true
    end
end

function AddTargetBone(bones, parameteres)
    for _, bone in pairs(bones) do
        Bones[bone] = parameteres
    end

    for _, option in pairs(parameteres.options) do
        Events[option.event] = true
    end
end

function AddEntityZone(name, entity, options, targetoptions)
	Zones[name] = EntityZone:Create(entity, options)
	Zones[name].targetoptions = targetoptions

    for _, option in pairs(targetoptions.options) do
        Events[option.event] = true
    end
end

function RemoveZone(name)
    if not Zones[name] then return end
    if Zones[name].destroy then
        Zones[name]:destroy()
    end

    for _, option in pairs(Zones[name].targetoptions.options) do
        Events[option.event] = false
    end
    Zones[name] = nil
end

exports("AddCircleZone", AddCircleZone)

exports("AddBoxZone", AddBoxZone)

exports("AddPolyzone", AddPolyzone)

exports("AddTargetModel", AddTargetModel)

exports("AddTargetEntity", AddTargetEntity)

exports("AddTargetBone", AddTargetBone)

exports("AddEntityZone", AddEntityZone)

exports("RemoveZone", RemoveZone)

exports("Raycast", RayCastCamera)
