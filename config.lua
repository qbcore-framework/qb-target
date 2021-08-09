local Config, Players, Types, Entities, Models, Zones, Bones, PlayerData = {}, {}, {}, {}, {}, {}, {}, {}
Types[1], Types[2], Types[3] = {}, {}, {}
Config.VehicleBones = {'chassis', 'windscreen', 'seat_pside_r', 'seat_dside_r', 'bodyshell', 'suspension_lm', 'suspension_lr', 'platelight', 'attach_female', 'attach_male', 'bonnet', 'boot', 'chassis_dummy', 'chassis_Control', 'door_dside_f', 'door_dside_r', 'door_pside_f', 'door_pside_r', 'Gun_GripR', 'windscreen_f', 'VFX_Emitter', 'window_lf', 'window_lr', 'window_rf', 'window_rr', 'engine', 'gun_ammo', 'ROPE_ATTATCH', 'wheel_lf', 'wheel_lr', 'wheel_rf', 'wheel_rr', 'exhaust', 'overheat', 'misc_e', 'seat_dside_f', 'seat_pside_f', 'Gun_Nuzzle'}

-------------------------------------------------------------------------------
-- Settings
-------------------------------------------------------------------------------
-- It's possible to interact with entities through walls so this should be low
Config.MaxDistance = 3.0

-- Enable debug options and distance preview
Config.Debug = true

-- Support when not using QBCore
Config.Standalone = false

-------------------------------------------------------------------------------
-- Target Configs
-------------------------------------------------------------------------------

-- These are all empty for you to fill in, refer to the wiki and .md files for help in filling these in

Config.CircleZones = {

}

Config.BoxZones = {
	["testt"] = {
		name = "testt",
		coords = vector3(-262.872, -368.548, 30.132),
		length = 1.8,
		width = 1.8,
		heading = 70.0,
		debugPoly = true,
		minZ = 29.1,
		maxZ = 32.9,
		options = {
			{
				trigger = {
					type = "client",
					event = "bt-target:debug",
				},
				icon = "fas fa-car",
				label = "labnels"
			},
		},
		distance = 2.8,
	},
	["testtt"] = {
		name = "testtt",
		coords = vector3(-265.872, -368.548, 30.132),
		length = 1.8,
		width = 1.8,
		heading = 70.0,
		debugPoly = true,
		minZ = 29.1,
		maxZ = 32.9,
		options = {
			{
				trigger = {
					type = "client",
					event = "bt-target:debug",
				},
				icon = "fas fa-car",
				label = "labnels"
			},
		},
		distance = 2.8,
	}
}

Config.PolyZones = {

}

Config.TargetBones = {

}

Config.TargetEntities = {

}

Config.EntityZones = {

}

Config.TargetModels = {

}

Config.PedOptions = {

}

Config.VehicleOptions = {

}

Config.ObjectOptions = {

}

Config.PlayerOptions = {

}

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------
local M = {}
if not Config.Standalone then
	M.ItemCount = function(item)
		for k, v in pairs(PlayerData.items) do
			if v.name == item then
				return v.amount
			end
		end
		return 0
	end

	M.CheckOptions = function(data, entity, distance)
		if (data.distance == nil or distance <= data.distance)
		and (data.job == nil or (data.job == PlayerData.job.name or data.job[PlayerData.job.name] and data.job[PlayerData.job.name] <= PlayerData.job.grade.level))
		and (data.item == nil or data.item and M.ItemCount(data.item) > 0)
		and (data.canInteract == nil or data.canInteract(entity)) then return true
		end
		return false
	end
else
	M.CheckOptions = function(data, entity, distance)
		if (data.distance == nil or distance <= data.distance)
		and (data.canInteract == nil or data.canInteract(entity)) then return true
		end
		return false
	end
end

M.CloneTable = function(table)
	local copy = {}
	for k,v in pairs(table) do
		if type(v) == 'table' then
			copy[k] = M.CloneTable(v)
		else
			if type(v) == 'function' then v = nil end
			copy[k] = v
		end
	end
	return copy
end

M.ToggleDoor = function(vehicle, door)
	if GetVehicleDoorLockStatus(vehicle) ~= 2 then 
		if GetVehicleDoorAngleRatio(vehicle, door) > 0.0 then
			SetVehicleDoorShut(vehicle, door, false)
		else
			SetVehicleDoorOpen(vehicle, door, false)
		end
	end
end

-------------------------------------------------------------------------------
-- Default options
-------------------------------------------------------------------------------
Bones['seat_dside_f'] = {
	options = {
		{
			icon = "fas fa-door-open",
			label = "Toggle front Door",
			canInteract = function(entity)
				return GetEntityBoneIndexByName(entity, 'door_dside_f') ~= -1
			end,
			action = function(entity)
				M.ToggleDoor(entity, 0)
			end
		},
	},
	distance = 1.2
}

Bones['seat_pside_f'] = {
	options = {
		{
			icon = "fas fa-door-open",
			label = "Toggle front Door",
			canInteract = function(entity)
				return GetEntityBoneIndexByName(entity, 'door_pside_f') ~= -1
			end,
			action = function(entity)
				M.ToggleDoor(entity, 1)
			end
		},
	},
	distance = 1.2
}

Bones['seat_dside_r'] = {
	options = {
		{
			icon = "fas fa-door-open",
			label = "Toggle rear Door",
			canInteract = function(entity)
				return GetEntityBoneIndexByName(entity, 'door_dside_r') ~= -1
			end,
			action = function(entity)
				M.ToggleDoor(entity, 2)
			end
		},
	},
	distance = 1.2
}

Bones['seat_pside_r'] = {
	options = {
		{
			icon = "fas fa-door-open",
			label = "Toggle rear Door",
			canInteract = function(entity)
				return GetEntityBoneIndexByName(entity, 'door_pside_r') ~= -1
			end,
			action = function(entity)
				M.ToggleDoor(entity, 3)
			end
		},
	},
	distance = 1.2
}

Bones['bonnet'] = {
	options = {
		{
			icon = "fa-duotone fa-engine",
			label = "Toggle Hood",
			action = function(entity)
				M.ToggleDoor(entity, 4)
			end
		},
	},
	distance = 0.9
}

-------------------------------------------------------------------------------
return Config, Players, Types, Entities, Models, Zones, Bones, M, PlayerData
-------------------------------------------------------------------------------
