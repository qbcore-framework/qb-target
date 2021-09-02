local Config, Players, Types, Entities, Models, Zones, Bones, PlayerData = {}, {}, {}, {}, {}, {}, {}, {}
Types[1], Types[2], Types[3] = {}, {}, {}
Config.VehicleBones = {'chassis', 'windscreen', 'seat_pside_r', 'seat_dside_r', 'bodyshell', 'suspension_lm', 'suspension_lr', 'platelight', 'attach_female', 'attach_male', 'bonnet', 'boot', 'chassis_dummy', 'chassis_Control', 'door_dside_f', 'door_dside_r', 'door_pside_f', 'door_pside_r', 'Gun_GripR', 'windscreen_f', 'VFX_Emitter', 'window_lf', 'window_lr', 'window_rf', 'window_rr', 'engine', 'gun_ammo', 'ROPE_ATTATCH', 'wheel_lf', 'wheel_lr', 'wheel_rf', 'wheel_rr', 'exhaust', 'overheat', 'misc_e', 'seat_dside_f', 'seat_pside_f', 'Gun_Nuzzle'}

-------------------------------------------------------------------------------
-- Settings
-------------------------------------------------------------------------------
-- It's possible to interact with entities through walls so this should be low
Config.MaxDistance = 3.0

-- Enable debug options and distance preview
Config.Debug = false

-- Enable outlines around the entity you're looking at
Config.EnableOutline = false

-- Enable default options (Toggling vehicle doors)
Config.EnableDefaultOptions = false

-------------------------------------------------------------------------------
-- Target Configs
-------------------------------------------------------------------------------

-- These are all empty for you to fill in, refer to the wiki and .md files for help in filling these in

Config.CircleZones = {

}

Config.BoxZones = {

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

if Config.EnableDefaultOptions then
	Config.ToggleDoor = function(vehicle, door)
		if GetVehicleDoorLockStatus(vehicle) ~= 2 then
			if GetVehicleDoorAngleRatio(vehicle, door) > 0.0 then
				SetVehicleDoorShut(vehicle, door, false)
			else
				SetVehicleDoorOpen(vehicle, door, false)
			end
		end
	end
end

-------------------------------------------------------------------------------
-- Default options
-------------------------------------------------------------------------------

if Config.EnableDefaultOptions then
	Bones['seat_dside_f'] = {
		options = {
			{
				icon = "fas fa-door-open",
				label = "Toggle front Door",
				canInteract = function(entity)
					return GetEntityBoneIndexByName(entity, 'door_dside_f') ~= -1
				end,
				action = function(entity)
					Config.ToggleDoor(entity, 0)
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
					Config.ToggleDoor(entity, 1)
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
					Config.ToggleDoor(entity, 2)
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
					Config.ToggleDoor(entity, 3)
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
					Config.ToggleDoor(entity, 4)
				end
			},
		},
		distance = 0.9
	}
end

-------------------------------------------------------------------------------
return Config, Players, Types, Entities, Models, Zones, Bones, PlayerData
-------------------------------------------------------------------------------
