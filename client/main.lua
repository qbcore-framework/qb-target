local Config, Entities, Models, Zones, Bones, Players, Types, Intervals, ConfigFunctions, PlayerData = load(LoadResourceFile(GetCurrentResourceName(), 'config.lua'))()
local hasFocus, success, targetActive, sendData = false, false, false

-- Functions

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
    local entityType
    if entityHit then entityType = GetEntityType(entityHit) end
    return flag, endCoords, entityHit, entityType or 0
end

local CheckOptions = function(data, entity, distance)
    if (data.distance == nil or distance <= data.distance)
    and (data.owner == nil or data.owner == NetworkGetNetworkIdFromEntity(PlayerPedId()))
    and (data.job == nil or data.job == PlayerData.job.name or (Config.UseGrades and (Config.ESX and (data.job[PlayerData.job.name] and data.job[PlayerData.job.name] <= PlayerData.job.grade)) or (Config.QBCore and (data.job[PlayerData.job.name] and data.job[PlayerData.job.name] <= PlayerData.job.grade.level))))
    and (data.item == nil or data.item and ConfigFunctions.ItemCount(data.item))
    and (data.shouldShow == nil or not data.shouldShow or data.shouldShow(entity)) then return true end
    return false
end

local CheckRange = function(range, distance)
	for k, v in pairs(range) do
		if v == false and distance < k then return true
		elseif v == true and distance > k then return true end
	end
	return false
end

local curFlag = 30
local switch = function()
	if curFlag == 30 then curFlag = -1 else curFlag = 30 end
	return curFlag
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
		
	return true, send_options, send_distance
    end

    return false
end

local CheckEntity = function(hit, entity, data, distance)
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
            local _, coords, entity2 = RaycastCamera(hit)
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
		CheckEntity(hit, entity, data, distance)
                break
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

local closeTarget = function()
    SendNUIMessage({response = "closeTarget"})
    SetNuiFocus(false, false)
    success, hasFocus, targetActive = false, false, false
    ClearInterval(1)
end

local leftTarget = function()
    SendNUIMessage({response = "leftTarget"})
    SetNuiFocus(false, false)
    success, hasFocus = false, false
end

local validTarget = function(options)
    SetNuiFocus(true, true)
    SetCursorLocation(0.5, 0.5)
    hasFocus = true
    SendNUIMessage({response = "validTarget", data = options})
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

local playerTargetEnable = function()
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
			
	if Config.Debug then
	    DrawSphere(GetEntityCoords(PlayerPedId()), 7.0, 255, 255, 0, 0.15)
	end
    end)
    
    while targetActive do
        local sleep = 10
        local plyCoords = GetEntityCoords(PlayerPedId())
        local hit, coords, entity, entityType = RaycastCamera(switch())

        if entityType ~= 0 then
            if NetworkGetEntityIsNetworked(entity) then
                local data = Entities[NetworkGetNetworkIdFromEntity(entity)]
                if data and not success then
                    CheckEntity(entity, data, #(plyCoords - coords))
                end
            end

            if entityType == 1 and IsPedAPlayer(entity) then
                if not success then
                    CheckEntity(hit, entity, Players, #(plyCoords - coords))
                end
            elseif entityType == 2 and #(plyCoords - coords) <= 1.1 then
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
                    CheckEntity(hit, entity, data, #(plyCoords - coords))
                end
            else
                local data = Models[GetEntityModel(entity)]
                if data and not success then
                    CheckEntity(hit, entity, data, #(plyCoords - coords))
                end
            end
        end

        if not success then
            for _, zone in pairs(Zones) do
                if zone:isPointInside(coords) then
                    local check, sendoptions, senddistance = CheckZone(entity, zone, #(plyCoords - zone.center))
                    if check then
                        while success and targetActive do
                            local playerCoords = GetEntityCoords(PlayerPedId())
                            local _, coords, entity2 = RaycastCamera(hit)
                            local distance = #(playerCoords - zone.center)
            
                            if not zone:isPointInside(coords) then
                                leftTarget()
                                SetEntityDrawOutline(entity, false)
                            end
            
                            if (IsControlJustPressed(0, 25) or IsDisabledControlJustPressed(0, 25)) then
                                validTarget(sendoptions)
                                SetEntityDrawOutline(entity, false)
                            elseif IsControlJustReleased(0, 19) and not hasFocus then
                                closeTarget()
                                SetEntityDrawOutline(entity, false)
                            elseif CheckRange(senddistance, distance) then
                                CheckZone(entity, zone, distance)
                            end
            
                            Citizen.Wait(5)
                        end
                        leftTarget()
                        SetEntityDrawOutline(entity, false)
                    end
                end
            end
        else 
            success = false
            leftTarget()
        end
        Citizen.Wait(sleep)
    end
    closeTarget()
end

--Exports
Exports = {
    AddCircleZone = function(self, name, center, radius, options, targetoptions)
        Zones[name] = CircleZone:Create(center, radius, options)
        Zones[name].targetoptions = targetoptions
    end,

    AddBoxZone = function(self, name, center, length, width, options, targetoptions)
        Zones[name] = BoxZone:Create(center, length, width, options)
        Zones[name].targetoptions = targetoptions
    end,

    AddPolyzone = function(self, name, points, options, targetoptions)
        Zones[name] = PolyZone:Create(points, options)
        Zones[name].targetoptions = targetoptions
    end,

    AddTargetModel = function(self, models, parameters)
        local distance, options = parameters.distance or Config.MaxDistance, parameters.options
        for _, model in pairs(models) do
            if type(model) == 'string' then model = GetHashKey(model) end
            if not Models[model] then Models[model] = {} end
            for k, v in pairs(options) do
                if not v.distance or v.distance > distance then v.distance = distance end
                Models[model][v.event] = v
            end
        end
    end,

    AddTargetEntity = function(self, netid, parameters)
        local distance, options = parameters.distance or Config.MaxDistance, parameters.options
        if not Entities[netid] then Entities[netid] = {} end
        for k, v in pairs(options) do
            if not v.distance or v.distance > distance then v.distance = distance end
            Entities[netid][v.event] = v
        end
    end,

    AddTargetBone = function(self, bones, parameteres)
        for _, bone in pairs(bones) do
            Bones[bone] = parameteres
        end
    end,

    AddEntityZone = function(self, name, entity, options, targetoptions)
        Zones[name] = EntityZone:Create(entity, options)
        Zones[name].targetoptions = targetoptions
    end,

    RemoveZone = function(self, name)
        if not Zones[name] then return end
        if Zones[name].destroy then
            Zones[name]:destroy()
        end
        Zones[name] = nil
    end,

    AddType = function(self, type, parameters)
        local distance, options = parameters.distance or Config.MaxDistance, parameters.options
        for k, v in pairs(options) do
            if not v.distance or v.distance > distance then v.distance = distance end
            Types[type][v.event] = v
        end
    end,

    RemoveType = function(self, type, events)
        for k, v in pairs(events) do
            Types[type][v] = nil
        end
    end,

    RemovePlayer = function(self, type, events)
        for k, v in pairs(events) do
            Players[v.event] = nil
        end
    end,

    AddPlayer = function(self, parameters)
        local distance, options = parameters.distance or Config.MaxDistance, parameters.options
        for k, v in pairs(options) do
            if not v.distance or v.distance > distance then v.distance = distance end
            Players[v.event] = v
        end
    end,

    RemoveZone = function(self, name)
        if not Zones[name] then return end
        if Zones[name].destroy then
            Zones[name]:destroy()
        end
        Zones[name] = nil
    end,

    RemoveTargetModel = function(self, models, events)
        for _, model in pairs(models) do
            if type(model) == 'string' then model = GetHashKey(model) end
            for k, v in pairs(events) do
                if Models[model] then
                    Models[model][v] = nil
                end
            end
        end
    end,

    AddPed = function(self, parameters) AddType(1, parameters) end,

    AddVehicle = function(self, parameters) AddType(2, parameters) end,

    AddObject = function(self, parameters) AddType(3, parameters) end,

    AddPlayer = function(self, parameters) AddPlayer(parameters) end,

    RemovePed = function(self, events) RemoveType(1, events) end,

    RemoveVehicle = function(self, events) RemoveType(2, events) end,

    RemoveObject = function(self, events) RemoveType(3, events) end,

    RemovePlayer = function(self, events) RemoveType(1, events) end,
}

exports("FetchExports", function()
    return Exports
end)

exports("Raycast", RaycastCamera)

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
end

Citizen.CreateThread(function()
    RegisterKeyMapping("+playerTarget", "Player Targeting", "keyboard", "LMENU")
    RegisterCommand('+playerTarget', playerTargetEnable, false)
    RegisterCommand('-playerTarget', closeTarget, false)
    TriggerEvent("chat:removeSuggestion", "/+playerTarget")
    TriggerEvent("chat:removeSuggestion", "/-playerTarget")

    if next(Config.BoxZones) then
        for k, v in pairs(Config.BoxZones) do
            Exports:AddBoxZone(v.name, v.coords, v.length, v.width, {
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
            Exports:AddCircleZone(v.name, v.coords, v.radius, {
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
            Exports:AddTargetModel(v.models, {
                options = v.options,
                distance = v.distance
            })
        end
    end

    if next(Config.TargetEntities) then
        for k, v in pairs(Config.TargetEntities) do
            Exports:AddTargetEntity(v.entity, {
                options = v.options,
                distance = v.distance
            })
        end
    end

    if next(Config.TargetBones) then
        for k, v in pairs(Config.TargetBones) do
            Exports:AddTargetBone(v.bones, {
                options = v.options,
                distance = v.distance
            })
        end
    end

    if next(Config.EntityZones) then
        for k, v in pairs(Config.EntityZones) do
            Exports:AddEntityZone(v.name, v.entity, {
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
        Exports:AddPed({options = Config.PedOptions.options, distance = Config.PedOptions.distance})
    end

    if next(Config.VehicleOptions) then
        Exports:AddVehicle({options = Config.VehicleOptions.options, distance = Config.VehicleOptions.distance})
    end

    if next(Config.ObjectOptions) then
        Exports:AddObject({options = Config.ObjectOptions.options, distance = Config.ObjectOptions.distance})
    end

    if next(Config.PlayerOptions) then
        Exports:AddPlayer({options = Config.PlayerOptions.options, distance = Config.PlayerOptions.distance})
    end
end)

if Config.Debug then
	RegisterNetEvent('bt-target:debug')
	AddEventHandler('bt-target:debug', function(data)
		print( 'Flag: '..curFlag..'', 'Entity: '..data.entity..'', 'Type: '..GetEntityType(data.entity)..'' )

		local objId = NetworkGetNetworkIdFromEntity(data.entity)

        Exports:AddTargetEntity(NetworkGetNetworkIdFromEntity(data.entity), {
			options = {
				{
					event = "dummy-event",
					icon = "fas fa-box-circle-check",
					label = "HelloWorld",
					job = "unemployed"
				},
			},
			distance = 3.0
		})


	end)

    Exports:AddPed({
		options = {
			{
				event = "bt-target:debug",
				icon = "fas fa-male",
				label = "(Debug) Ped",
			},
		},
		distance = Config.MaxDistance
	})

    Exports:AddVehicle({
		options = {
			{
				event = "bt-target:debug",
				icon = "fas fa-car",
				label = "(Debug) Vehicle",
			},
		},
		distance = Config.MaxDistance
	})

    Exports:AddObject({
		options = {
			{
				event = "bt-target:debug",
				icon = "fas fa-cube",
				label = "(Debug) Object",
				job = 'police',
				shouldShow = function(entity)
					return IsEntityAnObject(entity)
				end
			},
		},
		distance = Config.MaxDistance
	})
end
