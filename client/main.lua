local Config, Players, Types, Entities, Models, Zones, Bones, PlayerData = load(LoadResourceFile(GetCurrentResourceName(), 'config.lua'))()
local playerPed, isLoggedIn, targetActive, hasFocus, success, sendData = PlayerPedId(), false, false, false, false
	
RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
	PlayerData = QBCore.Functions.GetPlayerData()
	isLoggedIn = true
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload')
AddEventHandler('QBCore:Client:OnPlayerUnload', function()
	isLoggedIn = false
	PlayerData = {}
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate')
AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
	PlayerData.job = JobInfo
end)

RegisterNetEvent('QBCore:Client:SetPlayerData')
AddEventHandler('QBCore:Client:SetPlayerData', function(val)
	PlayerData = val
end)

local ItemCount = function(item)
	for k, v in pairs(PlayerData.items) do
		if v.name == item then
			return v.amount
		end
	end
	return 0
end

local CheckOptions = function(data, entity, distance)
	if (data.distance == nil or distance <= data.distance)
	and (data.job == nil or data.job == PlayerData.job.name or (data.job[PlayerData.job.name] and data.job[PlayerData.job.name] <= PlayerData.job.grade.level))
	and (data.item == nil or data.item and ItemCount(data.item) > 0)
	and (data.canInteract == nil or data.canInteract(entity)) then return true
	end
	return false
end

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

	AddTargetBone = function(self, bones, parameters)
		if type(bones) == 'table' then
			for _, bone in pairs(bones) do
				Bones[bone] = parameters
			end
		elseif type(bones) == 'string' then
			Bones[bones] = parameters
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

	AddEntityZone = function(self, name, entity, options, targetoptions)
		Zones[name] = EntityZone:Create(entity, options)
		Zones[name].targetoptions = targetoptions
	end,

	AddTargetModel = function(self, models, parameters)
		local distance, options = parameters.distance or Config.MaxDistance, parameters.options
		if type(models) == 'table' then
			for _, model in pairs(models) do
				if type(model) == 'string' then model = GetHashKey(model) end
				if not Models[model] then Models[model] = {} end
				for k, v in pairs(options) do
					if not v.distance or v.distance > distance then v.distance = distance end
					Models[model][v.label] = v
				end
			end
		elseif type(models) == 'string' then
			local model = GetHashKey(models)
			if not Models[model] then Models[model] = {} end
			for k, v in pairs(options) do
				if not v.distance or v.distance > distance then v.distance = distance end
				Models[model][v.label] = v
			end
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
		if type(models) == 'table' then
			for _, model in pairs(models) do
				if type(model) == 'string' then model = GetHashKey(model) end
				if type(labels) == 'table' then
					for k, v in pairs(labels) do
						if Models[model] then
							Models[model][v] = nil
						end
					end
				elseif type(labels) == 'string' then
					if Models[model] then
						Models[model][labels] = nil
					end
				end
			end
		elseif type(models) == 'string' then
			local model = GetHashKey(model)
			if type(labels) == 'table' then
				for k, v in pairs(labels) do
					if Models[model] then
						Models[model][v] = nil
					end
				end
			elseif type(labels) == 'string' then
				if Models[model] then
					Models[model][labels] = nil
				end
			end
		end
	end,

	RemoveTargetEntity = function(self, entity, labels)
		local entity = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity) or false
		if entity then
			if type(labels) == 'table' then
				for k, v in pairs(labels) do
					if Entities[entity] then
						Entities[entity][v] = nil
					end
				end
			elseif type(labels) == 'string' then
				if Entities[entity] then
					Entities[entity][labels] = nil
				end
			end
		end
	end,

	AddType = function(self, type, parameters)
		local distance, options = parameters.distance or Config.MaxDistance, parameters.options
		for k, v in pairs(options) do
			if not v.distance or v.distance > distance then v.distance = distance end
			Types[type][v.label] = v
		end
	end,

	AddPed = function(self, parameters) self:AddType(1, parameters) end,

	AddVehicle = function(self, parameters) self:AddType(2, parameters) end,

	AddObject = function(self, parameters) self:AddType(3, parameters) end,

	AddPlayer = function(self, parameters)
		local distance, options = parameters.distance or Config.MaxDistance, parameters.options
		for k, v in pairs(options) do
			if not v.distance or v.distance > distance then v.distance = distance end
			Players[v.label] = v
		end
	end,

	RemoveType = function(self, type, labels)
		for k, v in pairs(labels) do
			Types[type][v] = nil
		end
	end,

	RemovePed = function(self, labels) self:RemoveType(1, labels) end,

	RemoveVehicle = function(self, labels) self:RemoveType(2, labels) end,

	RemoveObject = function(self, labels) self:RemoveType(3, labels) end,

	RemovePlayer = function(self, labels)
		if type(labels) == 'table' then
			for k, v in pairs(labels) do
				Players[v.label] = nil
			end
		elseif type(labels) == 'string' then
			Players[labels] = nil
		end
	end,

	RaycastCamera = function(self, flag)
		local cam = GetGameplayCamCoord()
		local direction = GetGameplayCamRot()
		direction = vec2(math.rad(direction.x), math.rad(direction.z))
		local num = math.abs(math.cos(direction.x))
		direction = vec3((-math.sin(direction.y) * num), (math.cos(direction.y) * num), math.sin(direction.x))
		local destination = vec3(cam.x + direction.x * 30, cam.y + direction.y * 30, cam.z + direction.z * 30)
		if Config.Debug then
			local entCoords = GetEntityCoords(PlayerPedId())
			DrawLine(entCoords.x, entCoords.y, entCoords.z, destination.x, destination.y, destination.z, 255, 0, 255, 255)
		end
		local rayHandle = StartShapeTestLosProbe(cam, destination, flag or -1, playerPed or PlayerPedId(), 0)
		while true do
			Wait(5)
			local result, _, endCoords, _, materialHash, entityHit = GetShapeTestResultIncludingMaterial(rayHandle)
			if Config.Debug then
				DrawLine(destination.x, destination.y, destination.z, endCoords.x, endCoords.y, endCoords.z, 255, 0, 255, 255)
			end
			if result ~= 1 then
				local entityType
				if entityHit then entityType = GetEntityType(entityHit) end
				return flag, endCoords, entityHit, entityType or 0
			end
		end
	end,
	IsTargetActive = function(self)
		return targetActive
	end,
	IsTargetSuccess = function(self)
		return success
	end,
	GetTargetTypeData = function(self, type, label)
		return Types[type][label]
	end,
	GetTargetZoneData = function(self, name)
		return Zones[name]
	end,
	GetTargetBoneData = function(self, bone)
		return Bones[bone]
	end,
	GetTargetEntityData = function(self, entity, label)
		return Entities[entity][label]
	end,
	GetTargetModelData = function(self, model, label)
		return Models[model][label]
	end,
	GetTargetPedData = function(self, label)
		return Types[1][label]
	end,
	GetTargetVehicleData = function(self, label)
		return Types[2][label]
	end,
	GetTargetObjectData = function(self, label)
		return Types[3][label]
	end,
	GetTargetPlayerData = function(self, label)
		return Players[label]
	end,
	CloneTable = function(self, table)
		local copy = {}
		for k,v in pairs(table) do
			if type(v) == 'table' then
				copy[k] = self:CloneTable(v)
			else
				if type(v) == 'function' then v = nil end
				copy[k] = v
			end
		end
		return copy
	end,
}

exports("AddCircleZone", function(name, center, radius, options, targetoptions)
    Exports:AddCircleZone(name, center, radius, options, targetoptions)
end)

exports("AddBoxZone", function(name, center, length, width, options, targetoptions)
    Exports:AddBoxZone(name, center, length, width, options, targetoptions)
end)

exports("AddPolyzone", function(name, points, options, targetoptions)
    Exports:AddPolyzone(name, points, options, targetoptions)
end)

exports("AddTargetBone", function(bones, parameters)
    Exports:AddTargetBone(bones, parameters)
end)

exports("AddTargetEntity", function(entity, parameters)
    Exports:AddTargetEntity(entity, parameters)
end)

exports("AddEntityZone", function(name, entity, options, targetoptions)
    Exports:AddEntityZone(name, entity, options, targetoptions)
end)

exports("AddTargetModel", function(models, parameters)
    Exports:AddTargetModel(models, parameters)
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

exports("AddType", function(type, parameters)
	Exports:AddType(type, parameters)
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

exports("RemoveType", function(type, labels)
	Exports:RemoveType(type, labels)
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

exports("Raycast", function(flag)
    Exports:RaycastCamera(flag)
end)

exports("IsTargetActive", function()
	return Exports:IsTargetActive()
end)

exports("IsTargetSuccess", function()
	return Exports:IsTargetSuccess()
end)

exports("GetTargetTypeData", function(type, label)
	return Exports:GetTargetTypeData(type, label)
end)

exports("GetTargetZoneData", function(name)
	return Exports:GetTargetZoneData(name)
end)

exports("GetTargetBoneData", function(bone)
	return Exports:GetTargetBoneData(bone)
end)

exports("GetTargetEntityData", function(entity, label)
	Exports:GetTargetEntityData(entity, label)
end)

exports("GetTargetModelData", function(model, label)
	return Exports:GetTargetModelData(model, label)
end)

exports("GetTargetPedData", function(label)
	return Exports:GetTargetPedData(label)
end)

exports("GetTargetVehicleData", function(label)
	return Exports:GetTargetVehicleData(label)
end)

exports("GetTargetObjectData", function(label)
	return Exports:GetTargetObjectData(label)
end)

exports("GetTargetPlayerData", function(label)
	return Exports:GetTargetPlayerData(label)
end)

exports("CloneTable", function(table)
	return Exports:CloneTable(table)
end)

exports("FetchExports", function()
    return Exports
end)

local DisableNUI = function()
	SetNuiFocus(false, false)
	SetNuiFocusKeepInput(false)
	hasFocus = false
end

local DisableTarget = function()
	if targetActive and not hasFocus then
		SetNuiFocus(false, false)
		SetNuiFocusKeepInput(false)
		targetActive, hasFocus, success = false, false, false
		SendNUIMessage({response = "closeTarget"})
	end
end

local LeftTarget = function()
	SetNuiFocus(false, false)
	SetNuiFocusKeepInput(false)
	success, hasFocus = false, false
	SendNUIMessage({response = "leftTarget"})
end

local EnableNUI = function(options)
	if targetActive and not hasFocus then 
		SetCursorLocation(0.5, 0.5)
		SetNuiFocus(true, true)
		SetNuiFocusKeepInput(true)
		hasFocus = true
		SendNUIMessage({response = "validTarget", data = options})
	end
end

local DrawOutlineEntity = function(entity, bool)
	if Config.EnableOutline then
		if not IsEntityAPed(entity) then
			SetEntityDrawOutline(entity, bool)
		end
	end
end

CheckEntity = function(hit, data, entity, distance)
	local send_options, send_distance = {}, {}
	for o, data in pairs(data) do
		if CheckOptions(data, entity, distance) then
			local slot = #send_options + 1
			send_options[slot] = data
			send_options[slot].entity = entity
			send_distance[data.distance] = true
		else send_distance[data.distance] = false end
	end
	sendData = send_options
	if next(send_options) then
		success = true
		SendNUIMessage({response = "foundTarget"})
		DrawOutlineEntity(entity, true)
		while targetActive and success do
			local playerCoords = GetEntityCoords(playerPed)
			local _, coords, entity2 = Exports:RaycastCamera(hit)
			local distance = #(playerCoords - coords)
			if entity ~= entity2 then 
				if hasFocus then DisableNUI() end
				DrawOutlineEntity(entity, false)
				break
			elseif not hasFocus and IsControlPressed(0, 238) then
				EnableNUI(Exports:CloneTable(sendData))
				DrawOutlineEntity(entity, false)
			elseif not hasFocus and IsControlReleased(0, 19) then
				DisableTarget()
				DrawOutlineEntity(entity, false)
				break
			else
				for k, v in pairs(send_distance) do
					if v and distance > k then
						LeftTarget()
						DrawOutlineEntity(entity, false)
						break
					end
				end
			end
			Wait(5)
		end
		LeftTarget()
		DrawOutlineEntity(entity, false)
	end
end

local CheckBones = function(coords, entity, min, max, bonelist)
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
	if closestBone ~= -1 then return closestBone, closestPos, closestBoneName
	else return false end
end

local curFlag = 30
local switch = function()
	if curFlag == 30 then curFlag = -1 else curFlag = 30 end
	return curFlag
end

local EnableTarget = function()
	if success or not isLoggedIn then return end
	if not targetActive then
		targetActive = true
		SendNUIMessage({response = "openTarget"})
		
		CreateThread(function()
			repeat
				SetPauseMenuActive(false)
				if hasFocus then
					DisableControlAction(0, 1, true)
					DisableControlAction(0, 2, true)
				end
				DisablePlayerFiring(PlayerId(), true)
				DisableControlAction(0, 25, true)
				DisableControlAction(0, 37, true)
				Wait(1)
			until not targetActive
		end)
		playerPed = PlayerPedId()
		
		if not Config.Standalone then
			PlayerData = QBCore.Functions.GetPlayerData()
		end

		while targetActive do
			local sleep = 1
			local plyCoords = GetEntityCoords(playerPed)
			local hit, coords, entity, entityType = Exports:RaycastCamera(switch())
			if entityType > 0 then

				-- Owned entity targets
				if NetworkGetEntityIsNetworked(entity) then
					local data = Entities[NetworkGetNetworkIdFromEntity(entity)]
					if data ~= nil then
						CheckEntity(hit, data, entity, #(plyCoords - coords))
					end
				end

				-- Player and Ped targets
				if entityType == 1 then
					local data = Models[GetEntityModel(entity)]
					if IsPedAPlayer(entity) then data = Players end
					if data ~= nil then
						CheckEntity(hit, data, entity, #(plyCoords - coords))
					end

				-- Vehicle bones
				elseif entityType == 2 then
					local min, max = GetModelDimensions(GetEntityModel(entity))
					local closestBone, closestPos, closestBoneName = CheckBones(coords, entity, min, max, Config.VehicleBones)
					local data = Bones[closestBoneName]
					if closestBone and #(coords - closestPos) <= data.distance then
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
							success = true
							SendNUIMessage({response = "foundTarget"})
							DrawOutlineEntity(entity, true)
							while targetActive and success do
								local playerCoords = GetEntityCoords(playerPed)
								local _, coords, entity2 = Exports:RaycastCamera(hit)
								if hit and entity == entity2 then
									local closestBone2, closestPos2, closestBoneName2 = CheckBones(coords, entity, min, max, Config.VehicleBones)
								
									if closestBone ~= closestBone2 then
										if hasFocus then DisableNUI() end
										DrawOutlineEntity(entity, false)
										break
									elseif not hasFocus and IsControlPressed(0, 238) then 
										EnableNUI(Exports:CloneTable(sendData)) 
										DrawOutlineEntity(entity, false)
									elseif not hasFocus and IsControlReleased(0, 19) then
										DisableTarget()
										DrawOutlineEntity(entity, false)
										break
									elseif #(playerCoords - coords) > data.distance then
										LeftTarget()
										DrawOutlineEntity(entity, false)
									end
								else
									if hasFocus then DisableNUI() end
									DrawOutlineEntity(entity, false)
									break
								end
								Wait(5)
							end
							LeftTarget()
							DrawOutlineEntity(entity, false)
						end
					end

					-- Specific Vehicle targets
					local data = Models[GetEntityModel(entity)]
					if data ~= nil then
						CheckEntity(hit, data, entity, #(plyCoords - coords))
					end

				-- Entity targets
				elseif entityType > 2 then
					local data = Models[GetEntityModel(entity)]
					if data ~= nil then 
						CheckEntity(hit, data, entity, #(plyCoords - coords)) 
					end
				end

				-- Generic targets
				if not success then
					local data = Types[entityType]
					if data ~= nil then 
						CheckEntity(hit, data, entity, #(plyCoords - coords)) 
					end
				end
			end
			if not success then
				-- Zone targets
				for _,zone in pairs(Zones) do
					local distance = #(plyCoords - zone.center)
					if zone:isPointInside(coords) and distance <= zone.targetoptions.distance then
						local send_options = {}
						for o, data in pairs(zone.targetoptions.options) do
							if CheckOptions(data, entity, distance) then
								local slot = #send_options + 1
								send_options[slot] = data
								send_options[slot].entity = entity
							end
						end
						sendData = send_options
						if next(send_options) then
							success = true
							SendNUIMessage({response = "foundTarget"})
							DrawOutlineEntity(entity, true)
							while targetActive and success do
								local playerCoords = GetEntityCoords(playerPed)
								local _, coords, entity2 = Exports:RaycastCamera(hit)
								if not zone:isPointInside(coords) then
									if hasFocus then DisableNUI() end
									DrawOutlineEntity(entity, false)
									break
								elseif not hasFocus and IsControlPressed(0, 238) then
									EnableNUI(Exports:CloneTable(sendData))
									DrawOutlineEntity(entity, false)
								elseif not hasFocus and IsControlReleased(0, 19) then
									DisableTarget()
									DrawOutlineEntity(entity, false)
									break
								elseif #(playerCoords - zone.center) > zone.targetoptions.distance then
									LeftTarget()
									DrawOutlineEntity(entity, false)
								end
								Wait(5)
							end
							LeftTarget()
							DrawOutlineEntity(entity, false)
						end
					end
				end
			else LeftTarget() DrawOutlineEntity(entity, false) end
			Wait(sleep)
		end
		DisableTarget()
	end
end

RegisterNUICallback('selectTarget', function(option, cb)
    targetActive, success, hasFocus = false, false, false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    local data = sendData[option]
    CreateThread(function()
        Wait(50)
        if data.action ~= nil then
            data.action(data.entity)
        elseif data.event ~= nil then
            if data.type == "client" then
                TriggerEvent(data.event, data)
            elseif data.type == "server" then
                TriggerServerEvent(data.event, data)
            elseif data.type == "command" then
                ExecuteCommand(data.event)
            elseif data.type == "qbcommand" then
                TriggerServerEvent('QBCore:CallCommand', data.event, data)
            else
                TriggerEvent(data.event, data)
            end
        else
            print("[bt-target]: ERROR NO EVENT SETUP")
        end
    end)

    sendData = nil
end)

RegisterNUICallback('closeTarget', function(data, cb)
	Wait(100)
	SetNuiFocus(false, false)
	SetNuiFocusKeepInput(false)
	targetActive, hasFocus, success = false, false, false
end)

CreateThread(function()
    RegisterCommand('+playerTarget', EnableTarget, false)
    RegisterCommand('-playerTarget', DisableTarget, false)
    RegisterKeyMapping("+playerTarget", "Enable targeting~", "keyboard", "LMENU")
    TriggerEvent("chat:removeSuggestion", "/+playerTarget")
    TriggerEvent("chat:removeSuggestion", "/-playerTarget")

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

    if next(Config.PolyZones) then
        for k, v in pairs(Config.PolyZones) do
            Exports:AddPolyZone(v.name, v.points, {
                name = v.name,
                debugPoly = v.debugPoly,
                minZ = v.minZ,
                maxZ = v.maxZ
            }, {
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

    if next(Config.TargetEntities) then
        for k, v in pairs(Config.TargetEntities) do
            Exports:AddTargetEntity(v.entity, {
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

    if next(Config.TargetModels) then
        for k, v in pairs(Config.TargetModels) do
            Exports:AddTargetModel(v.models, {
                options = v.options,
                distance = v.distance
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

-- This is to make sure you can restart the resource manually without having to log-out.
AddEventHandler('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		Wait(200)
		if not Config.Standalone then
			PlayerData = QBCore.Functions.GetPlayerData()
		end
		isLoggedIn = true
	end
end)

if Config.Debug then
	AddEventHandler('bt-target:debug', function(data)
		print( 'Flag: '..curFlag..'', 'Entity: '..data.entity..'', 'Type: '..GetEntityType(data.entity)..'' )
		if data.remove then
			Exports:RemoveTargetEntity(data.entity, {
				'HelloWorld'
			})
		else
			Exports:AddTargetEntity(data.entity, {
				options = {
					{
						type = "client",
						event = "bt-target:debug",
						icon = "fas fa-box-circle-check",
						label = "HelloWorld",
						remove = true
					},
				},
				distance = 3.0
			})
		end


	end)

	Exports:AddPed({
		options = {
			{
				type = "client",
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
				type = "client",
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
				type = "client",
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
				type = "client",
				event = "bt-target:debug",
				icon = "fas fa-cube",
				label = "(Debug) Player",
			},
		},
		distance = Config.MaxDistance
	})
end
