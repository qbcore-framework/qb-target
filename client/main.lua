local Config, Entities, Models, Zones, Bones, Players, Types, Intervals, ConfigFunctions, PlayerData = load(LoadResourceFile(GetCurrentResourceName(), 'config.lua'))()
local playerPed, hasFocus, success, targetActive, sendData = PlayerPedId(), false, false, false

--Exports
local Exports = {
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
                Models[model][v.label] = v
            end
        end
    end,

    AddTargetEntity = function(self, entity, parameters)
	local entity = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity) or false
	if entity then
		local distance, options = parameters.distance or Config.MaxDistance, parameters.options
		if not Entities[entity] then Entities[entity] = {} end
		for k, v in pairs(options) do
		    if not v.distance or v.distance > distance then v.distance = distance end
		    Entities[entity][v.label] = v
		end
	end
    end,

    AddTargetBone = function(self, bones, parameters)
        for _, bone in pairs(bones) do
            Bones[bone] = parameters
        end
    end,

    AddEntityZone = function(self, name, entity, options, targetoptions)
        Zones[name] = EntityZone:Create(entity, options)
        Zones[name].targetoptions = targetoptions
    end,

    AddType = function(self, type, parameters)
        local distance, options = parameters.distance or Config.MaxDistance, parameters.options
        for k, v in pairs(options) do
            if not v.distance or v.distance > distance then v.distance = distance end
            Types[type][v.label] = v
        end
    end,

    RemoveType = function(self, type, labels)
        if type(labels) == 'string' then
            Types[type][labels] = nil
        elseif type(labels) == 'table' then
            for k, v in pairs(labels) do
                Types[type][v] = nil
            end
        end
    end,

    RemovePlayer = function(self, labels)
        if type(labels) == 'string' then
            Players[labels] = nil
        elseif type(labels) == 'table' then
            for k, v in pairs(labels) do
                Players[v] = nil
            end
        end
    end,

    AddPlayer = function(self, parameters)
        local distance, options = parameters.distance or Config.MaxDistance, parameters.options
        for k, v in pairs(options) do
            if not v.distance or v.distance > distance then v.distance = distance end
            Players[v.label] = v
        end
    end,

    RemoveZone = function(self, name)
        if not Zones[name] then return end
        if Zones[name].destroy then
            Zones[name]:destroy()
        end
        Zones[name] = nil
    end,

    RemoveTargetModel = function(self, models, labels)
        for _, model in pairs(models) do
            if type(model) == 'string' then model = GetHashKey(model) end
            if type(labels) == 'string' then
                if Models[model] then
                    Models[model][labels] = nil
                end
            elseif type(labels) == 'table' then
                for k, v in pairs(labels) do
                    if Models[model] then
                        Models[model][v] = nil
                    end
                end
            end
        end
    end,

    RemoveTargetEntity = function(self, entity, labels)
        local entity = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity) or false
        if entity then
            if type(labels) == 'string' then
                if Entities[entity] then
                    Entities[entity][labels] = nil
                end
            elseif type(labels) == 'table' then
                for k, v in pairs(labels) do
                    if Entities[entity] then
                        Entities[entity][v] = nil
                    end
                end
            end
        end
    end,

    AddPed = function(self, parameters) self:AddType(1, parameters) end,

    AddVehicle = function(self, parameters) self:AddType(2, parameters) end,

    AddObject = function(self, parameters) self:AddType(3, parameters) end,

    RemovePed = function(self, labels) self:RemoveType(1, labels) end,

    RemoveVehicle = function(self, labels) self:RemoveType(2, labels) end,

    RemoveObject = function(self, labels) self:RemoveType(3, labels) end,
	
    RaycastCamera = function(self, flag)
        local cam = GetGameplayCamCoord()
        local direction = GetGameplayCamRot()
        direction = vec2(math.rad(direction.x), math.rad(direction.z))
        local num = math.abs(math.cos(direction.x))
        direction = vec3((-math.sin(direction.y) * num), (math.cos(direction.y) * num), math.sin(direction.x))
        local destination = vec3(cam.x + direction.x * 30, cam.y + direction.y * 30, cam.z + direction.z * 30)
        local rayHandle = StartShapeTestLosProbe(cam, destination, flag or -1, playerPed or PlayerPedId(), 0)
        while true do
            Wait(0)
            local result, _, endCoords, _, materialHash, entityHit = GetShapeTestResultIncludingMaterial(rayHandle)
            if result ~= 1 then
                local entityType
                if entityHit then entityType = GetEntityType(entityHit) end
                return flag, endCoords, entityHit, entityType or 0
            end
        end
    end,
}

-- Functions

local closeTarget = function()
    SendNUIMessage({response = "closeTarget"})
    SetNuiFocus(false, false)
    success, hasFocus, targetActive = false, false, false
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

local curFlag = 30
local switch = function()
	if curFlag == 30 then curFlag = -1 else curFlag = 30 end
	return curFlag
end

local CheckRange = function(range, distance)
	for k, v in pairs(range) do
		if v == false and distance < k then return true
		elseif v == true and distance > k then return true end
	end
	return false
end

local CheckEntity = function(hit, entity, data, distance)
    local send_options, send_distance = {}, {}
    for o, data in pairs(data) do
        if ConfigFunctions.CheckOptions(data, entity, distance) then 
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
        success = true
        SendNUIMessage({response = "foundTarget"})

        SetEntityDrawOutline(entity, true)
        while success and targetActive do
            local playerCoords = GetEntityCoords(playerPed)
            local _, coords, entity2 = Exports:RaycastCamera(hit)
	    local distance = #(playerCoords - coords)

	    if entity ~= entity2 then
                leftTarget()
                SetEntityDrawOutline(entity, false)
            end

            if (IsControlJustPressed(0, 25) or IsDisabledControlJustPressed(0, 25)) then
                validTarget(ConfigFunctions.CloneTable(sendData))
                SetEntityDrawOutline(entity, false)
            elseif IsControlJustReleased(0, 19) and not hasFocus then
                closeTarget()
                SetEntityDrawOutline(entity, false)
            --[[elseif CheckRange(send_distance, distance) then
                CheckEntity(hit, entity, data, distance)]]
            end

            Wait(5)
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
            if ConfigFunctions.CheckOptions(data, entity) then 
                local slot = #send_options + 1 
                send_options[slot] = data
                send_options[slot].entity = entity
            end
        end
        sendData = send_options
        if next(send_options) then
            success = true
            SendNUIMessage({response = "foundTarget"})
            return true, ConfigFunctions.CloneTable(sendData), closestBone, closestPos, closestBoneName
        end
    else
        return closestBone, closestPos, closestBoneName, Bones[closestBoneName].distance
    end

    return false
end

--NUI CALL BACKS

RegisterNUICallback('selectTarget', function(option, cb)
    if not targetActive then return end

    SetNuiFocus(false, false)

    success, hasFocus, targetActive = false, false, false
	
    local data = sendData[option]
    
    CreateThread(function()
        Wait(50)
        if data.type ~= nil then
            if data.type == "client" then
                TriggerEvent(data.event, data)
            elseif data.type == "server" then
                TriggerServerEvent(data.event, data)
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

    	Citizen.CreateThread(function()
		repeat
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
                        DisableControlAction(0, 257, true)
                        DisableControlAction(0, 263, true)
                        DisableControlAction(0, 264, true)
				
			Wait(5)
		until targetActive == false
	end)

    playerPed = PlayerPedId()
    
    while targetActive do
        local sleep = 10
        local plyCoords = GetEntityCoords(playerPed)
        local hit, coords, entity, entityType = Exports:RaycastCamera(switch())

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
                            local playerCoords = GetEntityCoords(playerPed)
                            local hit, coords, entity2 = Exports:RaycastCamera()
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

                            Wait(5)
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

            if not success then
                local data = Types[entityType]
                if data then 
                    CheckEntity(hit, entity, data, #(plyCoords - coords))
                end
            end
        else
            sleep = sleep + 10
        end

        for _, zone in pairs(Zones) do
            local distance = #(plyCoords - zone.center)
            if zone:isPointInside(plyCoords) and distance <= zone.targetoptions.distance and not success then
                local send_options = {}
                for o, data in pairs(zone.targetoptions.options) do
                    if ConfigFunctions.CheckOptions(data, entity, distance) then
                        local slot = #send_options + 1 
                        send_options[slot] = data
                        send_options[slot].entity = entity
                    end
                end
                sendData = send_options
                if next(send_options) then
                    success = true
                    SendNUIMessage({response = "foundTarget"})
                SetEntityDrawOutline(entity, true)
                    while success and targetActive do
                        local playerCoords = GetEntityCoords(playerPed)
                        local _, coords, entity2 = Exports:RaycastCamera(hit)
        
                        if not zone:isPointInside(playerCoords) or #(playerCoords - zone.center) > zone.targetoptions.distance then
                            leftTarget()
                            SetEntityDrawOutline(entity, false)
                        end
        
                        if (IsControlJustPressed(0, 25) or IsDisabledControlJustPressed(0, 25)) then
                            validTarget(ConfigFunctions.CloneTable(sendData))
                            SetEntityDrawOutline(entity, false)
                        elseif IsControlJustReleased(0, 19) and not hasFocus then
                            closeTarget()
                            SetEntityDrawOutline(entity, false)
                        end
        
                        Wait(5)
                    end
                    leftTarget()
                    SetEntityDrawOutline(entity, false)
                end
            end
        end
        Wait(sleep)
    end
    closeTarget()
end

-- Defining the exports

exports("AddCircleZone", function(name, center, radius, options, targetoptions)
    Exports:AddCircleZone(name, center, radius, options, targetoptions)
end)

exports("AddBoxZone", function(name, center, length, width, options, targetoptions)
    Exports:AddBoxZone(name, center, length, width, options, targetoptions)
end)

exports("AddPolyzone", function(name, points, options, targetoptions)
    Exports:AddPolyzone(name, points, options, targetoptions)
end)

exports("AddTargetModel", function(models, parameters)
    Exports:AddTargetModel(models, parameters)
end)

exports("AddTargetEntity", function(entity, parameters)
    Exports:AddTargetEntity(entity, parameters)
end)

exports("AddTargetBone", function(bones, parameters)
    Exports:AddTargetBone(bones, parameters)
end)

exports("AddEntityZone", function(name, entity, options, targetoptions)
    Exports:AddEntityZone(name, entity, options, targetoptions)
end)

exports("AddPed", function(parameters)
    Exports:AddPed(parameters)
end)

exports("AddVehicle", function(parameters)
    Exports:AddVehicle(parameters)
end)

exports("AddObject", function(parameters)
    Exports:AddObject(parameters)
end)

exports("AddPlayer", function(parameters)
    Exports:AddPlayer(parameters)
end)

exports("RemovePed", function(labels)
    Exports:RemovePed(labels)
end)

exports("RemoveVehicle", function(labels)
    Exports:RemoveVehicle(labels)
end)

exports("RemoveObject", function(labels)
    Exports:RemoveObject(labels)
end)

exports("RemovePlayer", function(labels)
    Exports:RemovePlayer(labels)
end)

exports("RemoveZone", function(name)
    Exports:RemoveZone(name)
end)

exports("RemoveTargetModel", function(models, labels)
    Exports:RemoveTargetModel(models, labels)
end)

exports("RemoveTargetEntity", function(entity, labels)
    Exports:RemoveTargetEntity(entity, labels)
end)

exports("Raycast", function(flag)
    Exports:RaycastCamera(flag)
end)

exports("FetchExports", function()
    return Exports
end)

if Config.ESX then
    CreateThread(function()
        while ESX == nil do
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
            Wait(0)
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
    CreateThread(function()
        while QBCore == nil do
            TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
            Wait(200)
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

CreateThread(function()
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
	AddEventHandler('bt-target:debug', function(data)
		print('Flag: '..curFlag..'', 'Entity: '..data.entity..'', 'Type: '..GetEntityType(data.entity)..'')

		if data.remove then
		    Exports:RemoveTargetEntity(data.entity, 'HelloWorld')
		else
		    Exports:AddTargetEntity(data.entity, {
			options = {
			    {
				event = "dummy-event",
				icon = "fas fa-box-circle-check",
				label = "HelloWorld",
			    },
			},
			distance = 3.0
		    })
		end
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
			},
		},
		distance = Config.MaxDistance
	})

    	Exports:AddPlayer({
		options = {
			{
				event = "bt-target:debug",
				icon = "fas fa-cube",
				label = "(Debug) Player",
			},
		},
		distance = Config.MaxDistance
	})
end
