local CurrentResourceName = GetCurrentResourceName()
local QBCore, PlayerData
local Config, Types, Bones, Players, Entities, Models, Zones, Functions = Config, Types, Bones, {}, {}, {}, {}, {}
local playerPed, curFlag, targetActive, hasFocus, success, PedsReady, AllowTarget, sendData = PlayerPedId(), 30, false, false, false, false, true, nil

if not Config.Standalone then
	QBCore = exports['qb-core']:GetCoreObject()
	PlayerData = QBCore.Functions.GetPlayerData()

	-- This makes sure that peds only spawn when you are spawned and your PlayerData gets set when you have access to the target
	RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
		PlayerData = QBCore.Functions.GetPlayerData()
		Functions.SpawnPeds()
	end)

	-- This will make sure everything resets and despawns after you logout/disconnect
	RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
		PlayerData = {}
		Functions.DeletePeds()
	end)

	-- This will update the job when a new job has been assigned to a player
	RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
		PlayerData.job = JobInfo
	end)

	-- This will update the gang when a new gang has been assigned to a player
	RegisterNetEvent('QBCore:Client:OnGangUpdate', function(GangInfo)
		PlayerData.gang = GangInfo
	end)

	-- This will make sure all the PlayerData stays updated
	RegisterNetEvent('QBCore:Client:SetPlayerData', function(val)
		PlayerData = val
	end)

	function Functions.CheckOptions(data, entity, distance)
		if (not data.distance or distance <= data.distance)
		and (not data.job or data.job == PlayerData.job.name or (data.job[PlayerData.job.name] and data.job[PlayerData.job.name] <= PlayerData.job.grade.level))
		and (not data.gang or data.gang == PlayerData.gang.name or (data.gang[PlayerData.gang.name] and data.gang[PlayerData.gang.name] <= PlayerData.gang.grade.level))
		and (not data.citizenid or data.citizenid == PlayerData.citizenid or data.citizenid[PlayerData.citizenid])
		and (not data.item or data.item and Functions.ItemCount(data.item) > 0)
		and (not data.canInteract or data.canInteract(entity, distance, data)) then return true
		end
		return false
	end

	function Functions.ItemCount(item)
		for k, v in pairs(PlayerData.items) do
			if v.name == item then
				return v.amount
			end
		end
		return 0
	end
else
	local firstSpawn = false
	AddEventHandler('playerSpawned', function()
		if not firstSpawn then
			Functions.SpawnPeds()
			firstSpawn = true
		end
	end)

	function Functions.CheckOptions(data, entity, distance)
		if (not data.distance or distance <= data.distance)
		and (not data.canInteract or data.canInteract(entity, distance, data)) then return true
		end
		return false
	end
end

-- Functions
function Functions.AddCircleZone(name, center, radius, options, targetoptions)
	center = type(center) == 'table' and vector3(center.x, center.y, center.z) or center
	Zones[name] = CircleZone:Create(center, radius, options)
	targetoptions.distance = targetoptions.distance or Config.MaxDistance
	Zones[name].targetoptions = targetoptions
end

function Functions.AddBoxZone(name, center, length, width, options, targetoptions)
	center = type(center) == 'table' and vector3(center.x, center.y, center.z) or center
	Zones[name] = BoxZone:Create(center, length, width, options)
	targetoptions.distance = targetoptions.distance or Config.MaxDistance
	Zones[name].targetoptions = targetoptions
end

function Functions.AddPolyZone(name, points, options, targetoptions)
	local _points = {}
	if type(points[1]) == 'table' then
		for i = 1, #points do
			_points[i] = vector3(points[i].x, points[i].y)
		end
	end
	Zones[name] = PolyZone:Create(#_points > 0 and _points or points, options)
	targetoptions.distance = targetoptions.distance or Config.MaxDistance
	Zones[name].targetoptions = targetoptions
end

function Functions.AddComboZone(zones, options, targetoptions)
	Zones[name] = ComboZone:Create(zones, options)
	targetoptions.distance = targetoptions.distance or Config.MaxDistance
	Zones[name].targetoptions = targetoptions
end

function Functions.AddTargetBone(bones, parameters)
	local distance, options = parameters.distance or Config.MaxDistance, parameters.options
	if type(bones) == 'table' then
		for _, bone in pairs(bones) do
			if not Bones[bone] then Bones[bone] = {} end
			for k, v in pairs(options) do
				if v.distance == nil or not v.distance or v.distance > distance then v.distance = distance end
				Bones[bone][v.label] = v
			end
		end
	elseif type(bones) == 'string' then
		if not Bones[bones] then Bones[bones] = {} end
		for k, v in pairs(options) do
			if v.distance == nil or not v.distance or v.distance > distance then v.distance = distance end
			Bones[bones][v.label] = v
		end
	end
end

function Functions.AddTargetEntity(entities, parameters)
	local distance, options = parameters.distance or Config.MaxDistance, parameters.options
	if type(entities) == 'table' then
		for _, entity in pairs(entities) do
			entity = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity) or false
			if entity then
				if not Entities[entity] then Entities[entity] = {} end
				for k, v in pairs(options) do
					if v.distance == nil or not v.distance or v.distance > distance then v.distance = distance end
					Entities[entity][v.label] = v
				end
			end
		end
	elseif type(entities) == 'number' then
		local entity = NetworkGetEntityIsNetworked(entities) and NetworkGetNetworkIdFromEntity(entities) or false
		if entity then
			if not Entities[entity] then Entities[entity] = {} end
			for k, v in pairs(options) do
				if v.distance == nil or not v.distance or v.distance > distance then v.distance = distance end
				Entities[entity][v.label] = v
			end
		end
	end
end

function Functions.AddEntityZone(name, entity, options, targetoptions)
	Zones[name] = EntityZone:Create(entity, options)
	targetoptions.distance = targetoptions.distance or Config.MaxDistance
	Zones[name].targetoptions = targetoptions
end

function Functions.AddTargetModel(models, parameters)
	local distance, options = parameters.distance or Config.MaxDistance, parameters.options
	if type(models) == 'table' then
		for _, model in pairs(models) do
			if type(model) == 'string' then model = GetHashKey(model) end
			if not Models[model] then Models[model] = {} end
			for k, v in pairs(options) do
				if v.distance == nil or not v.distance or v.distance > distance then v.distance = distance end
				Models[model][v.label] = v
			end
		end
	else
		if type(models) == 'string' then models = GetHashKey(models) end
		if not Models[models] then Models[models] = {} end
		for k, v in pairs(options) do
			if v.distance == nil or not v.distance or v.distance > distance then v.distance = distance end
			Models[models][v.label] = v
		end
	end
end

function Functions.RemoveZone(name)
	if not Zones[name] then return end
	if Zones[name].destroy then
		Zones[name]:destroy()
	end
	Zones[name] = nil
end

function Functions.RemoveTargetBone(bones, labels)
	if type(bones) == 'table' then
		for _, bone in pairs(bones) do
			if type(labels) == 'table' then
				for k, v in pairs(labels) do
					if Bones[bone] then
						Bones[bone][v] = nil
					end
				end
			elseif type(labels) == 'string' then
				if Bones[bone] then
					Bones[bone][labels] = nil
				end
			end
		end
	else
		if type(labels) == 'table' then
			for k, v in pairs(labels) do
				if Bones[bones] then
					Bones[bones][v] = nil
				end
			end
		elseif type(labels) == 'string' then
			if Bones[bones] then
				Bones[bones][labels] = nil
			end
		end
	end
end

function Functions.RemoveTargetModel(models, labels)
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
	else
		if type(models) == 'string' then models = GetHashKey(models) end
		if type(labels) == 'table' then
			for k, v in pairs(labels) do
				if Models[models] then
					Models[models][v] = nil
				end
			end
		elseif type(labels) == 'string' then
			if Models[models] then
				Models[models][labels] = nil
			end
		end
	end
end

function Functions.RemoveTargetEntity(entities, labels)
	if type(entities) == 'table' then
		for _, entity in pairs(entities) do
			entity = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity) or false
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
		end
	elseif type(entities) == 'string' then
		local entity = NetworkGetEntityIsNetworked(entities) and NetworkGetNetworkIdFromEntity(entities) or false
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
	end
end

function Functions.AddGlobalType(type, parameters)
	local distance, options = parameters.distance or Config.MaxDistance, parameters.options
	for k, v in pairs(options) do
		if v.distance == nil or not v.distance or v.distance > distance then v.distance = distance end
		Types[type][v.label] = v
	end
end

function Functions.AddGlobalPed(parameters) Functions.AddGlobalType(1, parameters) end

function Functions.AddGlobalVehicle(parameters) Functions.AddGlobalType(2, parameters) end

function Functions.AddGlobalObject(parameters) Functions.AddGlobalType(3, parameters) end

function Functions.AddGlobalPlayer(parameters)
	local distance, options = parameters.distance or Config.MaxDistance, parameters.options
	for k, v in pairs(options) do
		if v.distance == nil or not v.distance or v.distance > distance then v.distance = distance end
		Players[v.label] = v
	end
end

function Functions.RemoveGlobalType(type, labels)
	if type(labels) == 'table' then
		for k, v in pairs(labels) do
			Types[type][v] = nil
		end
	elseif type(labels) == 'string' then
		Types[type][labels] = nil
	end
end

function Functions.RemoveGlobalPed(labels) Functions.RemoveGlobalType(1, labels) end

function Functions.RemoveGlobalVehicle(labels) Functions.RemoveGlobalType(2, labels) end

function Functions.RemoveGlobalObject(labels) Functions.RemoveGlobalType(3, labels) end

function Functions.RemoveGlobalPlayer(labels)
	if type(labels) == 'table' then
		for k, v in pairs(labels) do
			Players[v] = nil
		end
	elseif type(labels) == 'string' then
		Players[labels] = nil
	end
end

function Functions.RaycastCamera(flag)
	local cam = GetGameplayCamCoord()
	local direction = GetGameplayCamRot()
	direction = vec2(math.rad(direction.x), math.rad(direction.z))
	local num = math.abs(math.cos(direction.x))
	direction = vec3((-math.sin(direction.y) * num), (math.cos(direction.y) * num), math.sin(direction.x))
	local destination = vec3(cam.x + direction.x * 30, cam.y + direction.y * 30, cam.z + direction.z * 30)
	local rayHandle = StartShapeTestLosProbe(cam, destination, flag or -1, playerPed or PlayerPedId(), 0)
	while true do
		Wait(0)
		local result, _, endCoords, _, entityHit = GetShapeTestResult(rayHandle)
		if Config.Debug then
			local entCoords = GetEntityCoords(playerPed or PlayerPedId())
			DrawLine(entCoords.x, entCoords.y, entCoords.z, destination.x, destination.y, destination.z, 255, 0, 255, 255)
			DrawLine(destination.x, destination.y, destination.z, endCoords.x, endCoords.y, endCoords.z, 255, 0, 255, 255)
		end
		if result ~= 1 then
			local entityType = 0
			if entityHit ~= 0 then entityType = GetEntityType(entityHit) end
			return flag, endCoords, entityHit, entityType
		end
	end
end

function Functions.IsTargetActive()
	return targetActive
end

function Functions.IsTargetSuccess()
	return success
end

function Functions.GetGlobalTypeData(type, label)
	return Types[type][label]
end

function Functions.GetZoneData(name)
	return Zones[name]
end

function Functions.GetTargetBoneData(bone, label)
	return Bones[bone][label]
end

function Functions.GetTargetEntityData(entity, label)
	return Entities[entity][label]
end

function Functions.GetTargetModelData(model, label)
	return Models[model][label]
end

function Functions.GetGlobalPedData(label)
	return Functions.GetGlobalTypeData(1, label)
end

function Functions.GetGlobalVehicleData(label)
	return Functions.GetGlobalTypeData(2, label)
end

function Functions.GetGlobalObjectData(label)
	return Functions.GetGlobalTypeData(3, label)
end

function Functions.GetGlobalPlayerData(label)
	return Players[label]
end

function Functions.UpdateGlobalTypeData(type, label, data)
	Types[type][label] = data
end

function Functions.UpdateZoneData(name, data)
	Zones[name] = data
end

function Functions.UpdateTargetBoneData(bone, label, data)
	Bones[bone][label] = data
end

function Functions.UpdateTargetEntityData(entity, label, data)
	Entities[entity][label] = data
end

function Functions.UpdateTargetModelData(model, label, data)
	Models[model][label] = data
end

function Functions.UpdateGlobalPedData(label, data)
	Functions.UpdateGlobalTypeData(1, label, data)
end

function Functions.UpdateGlobalVehicleData(label, data)
	Functions.UpdateGlobalTypeData(2, label, data)
end

function Functions.UpdateGlobalObjectData(label, data)
	Functions.UpdateGlobalTypeData(3, label, data)
end

function Functions.UpdateGlobalPlayerData(label, data)
	Players[label] = data
end

function Functions.CloneTable(table)
	local copy = {}
	for k,v in pairs(table) do
		if type(v) == 'table' then
			copy[k] = Functions.CloneTable(v)
		else
			if type(v) == 'function' then v = nil end
			copy[k] = v
		end
	end
	return copy
end

function Functions.switch()
	if curFlag == 30 then curFlag = -1 else curFlag = 30 end
	return curFlag
end

function Functions.EnableTarget()
	if not AllowTarget or success or (not Config.Standalone and not LocalPlayer.state['isLoggedIn']) then return end
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
				DisableControlAction(0, 24, true)
				DisableControlAction(0, 25, true)
				DisableControlAction(0, 37, true)
				DisableControlAction(0, 47, true)
				DisableControlAction(0, 58, true)
				DisableControlAction(0, 140, true)
				DisableControlAction(0, 141, true)
				DisableControlAction(0, 142, true)
				DisableControlAction(0, 143, true)
				DisableControlAction(0, 257, true)
				DisableControlAction(0, 263, true)
				DisableControlAction(0, 264, true)
				Wait(0)
			until not targetActive
		end)
		playerPed = PlayerPedId()
		while targetActive do
			local plyCoords = GetEntityCoords(playerPed)
			local hit, coords, entity, entityType = Functions.RaycastCamera(Functions.switch())

			if entityType > 0 then

				-- Owned entity targets
				if NetworkGetEntityIsNetworked(entity) then
					local data = Entities[NetworkGetNetworkIdFromEntity(entity)]
					if data ~= nil then
						Functions.CheckEntity(hit, data, entity, #(plyCoords - coords))
					end
				end

				-- Player and Ped targets
				if entityType == 1 then
					local data = Models[GetEntityModel(entity)]
					if IsPedAPlayer(entity) then data = Players end
					if data ~= nil then
						Functions.CheckEntity(hit, data, entity, #(plyCoords - coords))
					end

				-- Vehicle bones
				elseif entityType == 2 then
					local closestBone, closestPos, closestBoneName = Functions.CheckBones(coords, entity, Config.VehicleBones)
					local datatable = Bones[closestBoneName]
					if closestBone then
						local send_options, send_distance, slot = {}, {}, 0
						for o, data in pairs(datatable) do
							if Functions.CheckOptions(data, entity, #(plyCoords - coords)) then
								slot = #send_options + 1
								send_options[slot] = data
								send_options[slot].entity = entity
								send_distance[data.distance] = true
							else send_distance[data.distance] = false end
						end
						sendData = send_options
						if next(send_options) then
							success = true
							SendNUIMessage({response = "foundTarget", data = sendData[slot].targeticon})
							Functions.DrawOutlineEntity(entity, true)
							while targetActive and success do
								local _, coords, entity2 = Functions.RaycastCamera(hit)
								if entity == entity2 then
									local playerCoords = GetEntityCoords(playerPed)
									local closestBone2 = Functions.CheckBones(coords, entity, Config.VehicleBones)
									local dist = #(playerCoords - coords)

									if closestBone ~= closestBone2 then
										if IsControlReleased(0, Config.OpenControlKey) or IsDisabledControlReleased(0, Config.OpenControlKey) then
											Functions.DisableTarget(true)
										else
											Functions.LeftTarget()
										end
										Functions.DrawOutlineEntity(entity, false)
										break
									elseif not hasFocus and (IsControlPressed(0, Config.MenuControlKey) or IsDisabledControlPressed(0, Config.MenuControlKey)) then
										Functions.EnableNUI(Functions.CloneTable(sendData))
										Functions.DrawOutlineEntity(entity, false)
									else
										for k, v in pairs(send_distance) do
											if v and dist > k then
												if IsControlReleased(0, Config.OpenControlKey) or IsDisabledControlReleased(0, Config.OpenControlKey) then
													Functions.DisableTarget(true)
												else
													Functions.LeftTarget()
												end
												Functions.DrawOutlineEntity(entity, false)
												break
											end
										end
									end
								else
									if IsControlReleased(0, Config.OpenControlKey) or IsDisabledControlReleased(0, Config.OpenControlKey) then
										Functions.DisableTarget(true)
									else
										Functions.LeftTarget()
									end
									Functions.DrawOutlineEntity(entity, false)
									break
								end
								Wait(0)
							end
							if IsControlReleased(0, Config.OpenControlKey) or IsDisabledControlReleased(0, Config.OpenControlKey) then
								Functions.DisableTarget(true)
							else
								Functions.LeftTarget()
							end
							Functions.DrawOutlineEntity(entity, false)
						end
					end

					-- Specific Vehicle targets
					local data = Models[GetEntityModel(entity)]
					if data ~= nil then
						Functions.CheckEntity(hit, data, entity, #(plyCoords - coords))
					end

				-- Entity targets
				elseif entityType > 2 then
					local data = Models[GetEntityModel(entity)]
					if data ~= nil then
						Functions.CheckEntity(hit, data, entity, #(plyCoords - coords))
					end
				end

				-- Generic targets
				if not success then
					local data = Types[entityType]
					if data ~= nil then
						Functions.CheckEntity(hit, data, entity, #(plyCoords - coords))
					end
				end
			end
			if not success then
				-- Zone targets
				for _, zone in pairs(Zones) do
					local distance = #(plyCoords - zone.center)
					if zone:isPointInside(coords) and distance <= zone.targetoptions.distance then
						local send_options, slot = {}, 0
						for o, data in pairs(zone.targetoptions.options) do
							if Functions.CheckOptions(data, entity, distance) then
								slot = #send_options + 1
								send_options[slot] = data
								send_options[slot].entity = entity
							end
						end
						TriggerEvent(CurrentResourceName..':client:enterPolyZone', send_options[slot])
						TriggerServerEvent(CurrentResourceName..':server:enterPolyZone', send_options[slot])
						sendData = send_options
						if next(send_options) then
							success = true
							SendNUIMessage({response = "foundTarget", data = sendData[slot].targeticon})
							Functions.DrawOutlineEntity(entity, true)
							while targetActive and success do
								local playerCoords = GetEntityCoords(playerPed)
								local _, endcoords, entity2 = Functions.RaycastCamera(hit)
								if not zone:isPointInside(endcoords) then
									if IsControlReleased(0, Config.OpenControlKey) or IsDisabledControlReleased(0, Config.OpenControlKey) then
										Functions.DisableTarget(true)
									else
										Functions.LeftTarget()
									end
									Functions.DrawOutlineEntity(entity, false)
								elseif not hasFocus and (IsControlPressed(0, Config.MenuControlKey) or IsDisabledControlPressed(0, Config.MenuControlKey)) then
									Functions.EnableNUI(Functions.CloneTable(sendData))
									Functions.DrawOutlineEntity(entity, false)
								elseif #(playerCoords - zone.center) > zone.targetoptions.distance then
									if IsControlReleased(0, Config.OpenControlKey) or IsDisabledControlReleased(0, Config.OpenControlKey) then
										Functions.DisableTarget(true)
									else
										Functions.LeftTarget()
									end
									Functions.DrawOutlineEntity(entity, false)
								end
								Wait(0)
							end
							if IsControlReleased(0, Config.OpenControlKey) or IsDisabledControlReleased(0, Config.OpenControlKey) then
								Functions.DisableTarget(true)
							else
								Functions.LeftTarget()
							end
							TriggerEvent(CurrentResourceName..':client:exitPolyZone', send_options[slot])
							TriggerServerEvent(CurrentResourceName..':server:exitPolyZone', send_options[slot])
							Functions.DrawOutlineEntity(entity, false)
						end
					end
				end
			end
			Wait(100)
		end
		Functions.DisableTarget(false)
	end
end

function Functions.EnableNUI(options)
	if targetActive and not hasFocus then
		SetCursorLocation(0.5, 0.5)
		SetNuiFocus(true, true)
		SetNuiFocusKeepInput(true)
		hasFocus = true
		SendNUIMessage({response = "validTarget", data = options})
	end
end

function Functions.DisableNUI()
	SetNuiFocus(false, false)
	SetNuiFocusKeepInput(false)
	hasFocus = false
end

function Functions.LeftTarget()
	SetNuiFocus(false, false)
	SetNuiFocusKeepInput(false)
	success, hasFocus = false, false
	SendNUIMessage({response = "leftTarget"})
end

function Functions.DisableTarget(forcedisable)
	if (targetActive and not hasFocus) or forcedisable then
		SetNuiFocus(false, false)
		SetNuiFocusKeepInput(false)
		Wait(100)
		targetActive, success, hasFocus = false, false, false
		SendNUIMessage({response = "closeTarget"})
	end
end

function Functions.DrawOutlineEntity(entity, bool)
	if Config.EnableOutline then
		if not IsEntityAPed(entity) then
			SetEntityDrawOutline(entity, bool)
		end
	end
end

function Functions.CheckEntity(hit, datatable, entity, distance)
	local send_options, send_distance, slot = {}, {}, 0
	for o, data in pairs(datatable) do
		if Functions.CheckOptions(data, entity, distance) then
			slot = #send_options + 1
			send_options[slot] = data
			send_options[slot].entity = entity
			send_distance[data.distance] = true
		else send_distance[data.distance] = false end
	end
	sendData = send_options
	if next(send_options) then
		success = true
		SendNUIMessage({response = "foundTarget", data = sendData[slot].targeticon})
		Functions.DrawOutlineEntity(entity, true)
		while targetActive and success do
			local playerCoords = GetEntityCoords(playerPed)
			local _, coords, entity2 = Functions.RaycastCamera(hit)
			local dist = #(playerCoords - coords)
			if entity ~= entity2 then
				if IsControlReleased(0, Config.OpenControlKey) or IsDisabledControlReleased(0, Config.OpenControlKey) then
					Functions.DisableTarget(true)
				else
					Functions.LeftTarget()
				end
				Functions.DrawOutlineEntity(entity, false)
				break
			elseif not hasFocus and (IsControlPressed(0, Config.MenuControlKey) or IsDisabledControlPressed(0, Config.MenuControlKey)) then
				Functions.EnableNUI(Functions.CloneTable(sendData))
				Functions.DrawOutlineEntity(entity, false)
			else
				for k, v in pairs(send_distance) do
					if v and dist > k then
						if IsControlReleased(0, Config.OpenControlKey) or IsDisabledControlReleased(0, Config.OpenControlKey) then
							Functions.DisableTarget(true)
						else
							Functions.LeftTarget()
						end
						Functions.DrawOutlineEntity(entity, false)
						break
					end
				end
			end
			Wait(0)
		end
		if IsControlReleased(0, Config.OpenControlKey) or IsDisabledControlReleased(0, Config.OpenControlKey) then
			Functions.DisableTarget(true)
		else
			Functions.LeftTarget()
		end
		Functions.DrawOutlineEntity(entity, false)
	end
end

function Functions.CheckBones(coords, entity, bonelist)
	local closestBone, closestDistance, closestPos, closestBoneName = -1, 20
	for k, v in pairs(bonelist) do
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

function Functions.AllowTargeting(bool)
	AllowTarget = bool
end

function Functions.SpawnPeds()
	if not PedsReady then
		if next(Config.Peds) then
			for k, v in pairs(Config.Peds) do
				local spawnedped = 0
				local networked = v.networked or false
				RequestModel(v.model)
				while not HasModelLoaded(v.model) do
					Wait(5)
				end

				if type(v.model) == 'string' then v.model = GetHashKey(v.model) end

				if v.minusOne then
					spawnedped = CreatePed(0, v.model, v.coords.x, v.coords.y, v.coords.z - 1.0, v.coords.w, networked, true)
				else
					spawnedped = CreatePed(0, v.model, v.coords.x, v.coords.y, v.coords.z, v.coords.w, networked, true)
				end

				if v.freeze then
					FreezeEntityPosition(spawnedped, true)
				end

				if v.invincible then
					SetEntityInvincible(spawnedped, true)
				end

				if v.blockevents then
					SetBlockingOfNonTemporaryEvents(spawnedped, true)
				end

				if v.animDict and v.anim then
					RequestAnimDict(v.animDict)
					while not HasAnimDictLoaded(v.animDict) do
						Wait(5)
					end

					TaskPlayAnim(spawnedped, v.animDict, v.anim, 8.0, 0, -1, v.flag or 1, 0, 0, 0, 0)
				end

				if v.scenario then
					TaskStartScenarioInPlace(spawnedped, v.scenario, 0, true)
				end

				if v.target then
					Functions.AddTargetModel(v.model, {
						options = v.target.options,
						distance = v.target.distance
					})
				end

				Config.Peds[k].currentpednumber = spawnedped
			end
			PedsReady = true
		end
	end
end

function Functions.DeletePeds()
	if PedsReady then
		if next(Config.Peds) then
			for k, v in pairs(Config.Peds) do
				DeletePed(v.currentpednumber)
				Config.Peds[k].currentpednumber = 0
			end
			PedsReady = false
		end
	end
end

function Functions.GetPeds()
	return Config.Peds
end

function Functions.UpdatePedsData(index, data)
	Config.Peds[index] = data
end

function Functions.SpawnPed(data)
	local spawnedped = 0
	local key, value = next(data)
	if key ~= 'target' and key ~= 'coords' and type(value) == 'table' then
		for k, v in pairs(data) do
			local networked = v.networked or false
			RequestModel(v.model)
			while not HasModelLoaded(v.model) do
				Wait(5)
			end

			if type(v.model) == 'string' then v.model = GetHashKey(v.model) end

			if v.minusOne then
				spawnedped = CreatePed(0, v.model, v.coords.x, v.coords.y, v.coords.z - 1.0, v.coords.w, networked, true)
			else
				spawnedped = CreatePed(0, v.model, v.coords.x, v.coords.y, v.coords.z, v.coords.w, networked, true)
			end

			if v.freeze then
				FreezeEntityPosition(spawnedped, true)
			end

			if v.invincible then
				SetEntityInvincible(spawnedped, true)
			end

			if v.blockevents then
				SetBlockingOfNonTemporaryEvents(spawnedped, true)
			end

			if v.animDict and v.anim then
				RequestAnimDict(v.animDict)
				while not HasAnimDictLoaded(v.animDict) do
					Wait(5)
				end

				TaskPlayAnim(spawnedped, v.animDict, v.anim, 8.0, 0, -1, v.flag or 1, 0, 0, 0, 0)
			end

			if v.scenario then
				TaskStartScenarioInPlace(spawnedped, v.scenario, 0, true)
			end

			if v.target then
				Functions.AddTargetModel(v.model, {
					options = v.target.options,
					distance = v.target.distance
				})
			end
			v.currentpednumber = spawnedped

			local nextnumber = #Config.Peds + 1
			if nextnumber <= 0 then
				nextnumber = 1
			end

			Config.Peds[nextnumber] = v
		end
	else
		if key ~= 'target' and key ~= 'coords' and type(value) == 'table' then
			if Config.Debug then
				print('Wrong table format for SpawnPed export')
			end
			return
		end
		local networked = data.networked or false
		RequestModel(data.model)
		while not HasModelLoaded(data.model) do
			Wait(5)
		end

		if type(data.model) == 'string' then data.model = GetHashKey(data.model) end

		if data.minusOne then
			spawnedped = CreatePed(0, data.model, data.coords.x, data.coords.y, data.coords.z - 1.0, data.coords.w, networked, true)
		else
			spawnedped = CreatePed(0, data.model, data.coords.x, data.coords.y, data.coords.z, data.coords.w, networked, true)
		end

		if data.freeze then
			FreezeEntityPosition(spawnedped, true)
		end

		if data.invincible then
			SetEntityInvincible(spawnedped, true)
		end

		if data.blockevents then
			SetBlockingOfNonTemporaryEvents(spawnedped, true)
		end

		if data.animDict and data.anim then
			RequestAnimDict(data.animDict)
			while not HasAnimDictLoaded(data.animDict) do
				Wait(5)
			end

			TaskPlayAnim(spawnedped, data.animDict, data.anim, 8.0, 0, -1, data.flag or 1, 0, 0, 0, 0)
		end

		if data.scenario then
			TaskStartScenarioInPlace(spawnedped, data.scenario, 0, true)
		end

		if data.target then
			Functions.AddTargetModel(data.model, {
				options = data.target.options,
				distance = data.target.distance
			})
		end

		data.currentpednumber = spawnedped

		local nextnumber = #Config.Peds + 1
		if nextnumber <= 0 then
			nextnumber = 1
		end

		Config.Peds[nextnumber] = data
	end
end

-- Exports
exports("AddCircleZone", Functions.AddCircleZone)

exports("AddBoxZone", Functions.AddBoxZone)

exports("AddPolyZone", Functions.AddPolyZone)

exports("AddComboZone", Functions.AddComboZone)

exports("AddTargetBone", Functions.AddTargetBone)

exports("AddTargetEntity", Functions.AddTargetEntity)

exports("AddEntityZone", Functions.AddEntityZone)

exports("AddTargetModel", Functions.AddTargetModel)

exports("RemoveZone", Functions.RemoveZone)

exports("RemoveTargetModel", Functions.RemoveTargetModel)

exports("RemoveTargetEntity", Functions.RemoveTargetEntity)

exports("AddGlobalType", Functions.AddGlobalType)

exports("AddGlobalPed", Functions.AddGlobalPed)

exports("AddGlobalVehicle", Functions.AddGlobalVehicle)

exports("AddGlobalObject", Functions.AddGlobalObject)

exports("AddGlobalPlayer", Functions.AddGlobalPlayer)

exports("RemoveGlobalType", Functions.RemoveGlobalType)

exports("RemoveGlobalPed", Functions.RemoveGlobalPed)

exports("RemoveGlobalVehicle", Functions.RemoveGlobalVehicle)

exports("RemoveGlobalObject", Functions.RemoveGlobalObject)

exports("RemoveGlobalPlayer", Functions.RemoveGlobalPlayer)

exports("IsTargetActive", function()
	return Functions.IsTargetActive()
end)

exports("IsTargetSuccess", function()
	return Functions.IsTargetSuccess()
end)

exports("GetGlobalTypeData", function(type, label)
	return Functions.GetGlobalTypeData(type, label)
end)

exports("GetZoneData", function(name)
	return Functions.GetZoneData(name)
end)

exports("GetTargetBoneData", function(bone)
	return Functions.GetTargetBoneData(bone)
end)

exports("GetTargetEntityData", function(entity, label)
	return Functions.GetTargetEntityData(entity, label)
end)

exports("GetTargetModelData", function(model, label)
	return Functions.GetTargetModelData(model, label)
end)

exports("GetGlobalPedData", function(label)
	return Functions.GetGlobalPedData(label)
end)

exports("GetGlobalVehicleData", function(label)
	return Functions.GetGlobalVehicleData(label)
end)

exports("GetGlobalObjectData", function(label)
	return Functions.GetGlobalObjectData(label)
end)

exports("GetGlobalPlayerData", function(label)
	return Functions.GetGlobalPlayerData(label)
end)

exports("UpdateZoneData", Functions.UpdateZoneData)

exports("UpdateTargetBoneData", Functions.UpdateTargetBoneData)

exports("UpdateTargetEntityData", Functions.UpdateTargetEntityData)

exports("UpdateTargetModelData", Functions.UpdateTargetModelData)

exports("UpdateGlobalPedData", Functions.UpdateGlobalPedData)

exports("UpdateGlobalVehicleData", Functions.UpdateGlobalVehicleData)

exports("UpdateGlobalObjectData", Functions.UpdateGlobalObjectData)

exports("UpdateGlobalPlayerData", Functions.UpdateGlobalPlayerData)

exports("SpawnPed", Functions.SpawnPed)

exports("GetPeds", function()
	return Functions.GetPeds()
end)

exports("UpdatePedsData", Functions.UpdatePedsData)

exports("AllowTargeting", Functions.AllowTargeting)

exports("FetchFunctions", function()
    return Functions
end)

-- NUI Callbacks
RegisterNUICallback('selectTarget', function(option, cb)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
	Wait(100)
	targetActive, success, hasFocus = false, false, false
    local data = sendData[option]
    CreateThread(function()
        Wait(50)
        if data.action then
            data.action(data.entity)
        elseif data.event then
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
            print("No trigger setup")
        end
    end)

    sendData = nil
end)

RegisterNUICallback('closeTarget', function(data, cb)
	SetNuiFocus(false, false)
	SetNuiFocusKeepInput(false)
	Wait(100)
	targetActive, success, hasFocus = false, false, false
end)

-- Startup thread
CreateThread(function()
    RegisterCommand('+playerTarget', Functions.EnableTarget, false)
    RegisterCommand('-playerTarget', Functions.DisableTarget, false)
    RegisterKeyMapping("+playerTarget", "Enable targeting~", "keyboard", Config.OpenKey)
    TriggerEvent("chat:removeSuggestion", "/+playerTarget")
    TriggerEvent("chat:removeSuggestion", "/-playerTarget")

    if next(Config.CircleZones) then
        for k, v in pairs(Config.CircleZones) do
            Functions.AddCircleZone(v.name, v.coords, v.radius, {
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
            Functions.AddBoxZone(v.name, v.coords, v.length, v.width, {
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
            Functions.AddPolyZone(v.name, v.points, {
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
            Functions.AddTargetBone(v.bones, {
                options = v.options,
                distance = v.distance
            })
        end
    end

    if next(Config.TargetEntities) then
        for k, v in pairs(Config.TargetEntities) do
            Functions.AddTargetEntity(v.entity, {
                options = v.options,
                distance = v.distance
            })
        end
    end

    if next(Config.TargetModels) then
        for k, v in pairs(Config.TargetModels) do
            Functions.AddTargetModel(v.models, {
                options = v.options,
                distance = v.distance
            })
        end
    end

    if next(Config.GlobalPedOptions) then
        Functions.AddGlobalPed(Config.GlobalPedOptions)
    end

    if next(Config.GlobalVehicleOptions) then
        Functions.AddGlobalVehicle(Config.GlobalVehicleOptions)
    end

    if next(Config.GlobalObjectOptions) then
        Functions.AddGlobalObject(Config.GlobalObjectOptions)
    end

    if next(Config.GlobalPlayerOptions) then
        Functions.AddGlobalPlayer(Config.GlobalPlayerOptions)
    end
end)

-- Events

-- This is to make sure the peds spawn on restart too instead of only when you load/log-in.
AddEventHandler('onResourceStart', function(resource)
	if resource == CurrentResourceName then
		Functions.SpawnPeds()
	end
end)

-- This will delete the peds when the resource stops to make sure you don't have random peds walking
AddEventHandler('onResourceStop', function(resource)
	if resource == CurrentResourceName then
		Functions.DeletePeds()
	end
end)

-- Debug Options
if Config.Debug then
	AddEventHandler(CurrentResourceName..':debug', function(data)
		print('Flag: '..curFlag, 'Entity: '..data.entity, 'Entity Model: '..GetEntityModel(data.entity), 'Type: '..GetEntityType(data.entity))
		if data.remove then
			Functions.RemoveTargetEntity(data.entity, 'HelloWorld')
		else
			Functions.AddTargetEntity(data.entity, {
				options = {
					{
						type = "client",
						event = CurrentResourceName..':debug',
						icon = "fas fa-box-circle-check",
						label = "HelloWorld",
						remove = true
					},
				},
				distance = 3.0
			})
		end
	end)

	Functions.AddGlobalPed({
		options = {
			{
				type = "client",
				event = CurrentResourceName..':debug',
				icon = "fas fa-male",
				label = "(Debug) Ped",
			},
		},
		distance = Config.MaxDistance
	})

	Functions.AddGlobalVehicle({
		options = {
			{
				type = "client",
				event = CurrentResourceName..':debug',
				icon = "fas fa-car",
				label = "(Debug) Vehicle",
			},
		},
		distance = Config.MaxDistance
	})

	Functions.AddGlobalObject({
		options = {
			{
				type = "client",
				event = CurrentResourceName..':debug',
				icon = "fas fa-cube",
				label = "(Debug) Object",
			},
		},
		distance = Config.MaxDistance
	})

	Functions.AddGlobalPlayer({
		options = {
			{
				type = "client",
				event = CurrentResourceName..':debug',
				icon = "fas fa-cube",
				label = "(Debug) Player",
			},
		},
		distance = Config.MaxDistance
	})
end