local Config, Entities, Models, Zones, Bones, Players, Types, Intervals, ConfigFunctions, PlayerData = {}, {}, {}, {}, {}, {}, {}, {}, {}, {}
Types[1], Types[2], Types[3] = {}, {}, {}

--- Framework

-- Use es_extended aka ESX-Legacy
Config.ESX = false

-- Use QBCore
Config.QBCore = true

-- Don't use a framework for the job checks
Config.Standalone = false

-- Settings
Config.UseGrades = false

-- Use linden's inventory system
Config.LindenInventory = false

-- Fallback for if you left the distance in the wrong place or forgot it
Config.MaxDistance = 2

-- Enable debug mode
Config.Debug = false



Config.VehicleBones = {'chassis', 'windscreen', 'seat_pside_r', 'seat_dside_r', 'bodyshell', 'suspension_lm', 'suspension_lr', 'platelight', 'attach_female', 'attach_male', 'bonnet', 'boot', 'chassis_dummy', 'chassis_Control', 'door_dside_f', 'door_dside_r', 'door_pside_f', 'door_pside_r', 'Gun_GripR', 'windscreen_f', 'VFX_Emitter', 'window_lf', 'window_lr', 'window_rf', 'window_rr', 'engine', 'gun_ammo', 'ROPE_ATTATCH', 'wheel_lf', 'wheel_lr', 'wheel_rf', 'wheel_rr', 'exhaust', 'overheat', 'misc_e', 'seat_dside_f', 'seat_pside_f', 'Gun_Nuzzle'}


Config.BoxZones = {

}

Config.CircleZones = {

}

Config.TargetModels = {

}

Config.TargetEntities = {

}

Config.TargetBones = {

}

Config.EntityZones = {
    
}

Config.PedOptions = {

}

Config.VehicleOptions = {
	
}

Config.ObjectOptions = {

}

Config.PlayerOptions = {

}

-- Functions from the config
if not Config.Standalone then
	ConfigFunctions.ItemCount = function(item)
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

		return false
	end

	ConfigFunctions.CheckOptions = function(data, entity, distance)
		if (data.distance == nil or distance <= data.distance)
		and (data.job == nil or data.job == PlayerData.job.name or (Config.UseGrades and (Config.ESX and (data.job[PlayerData.job.name] and data.job[PlayerData.job.name] <= PlayerData.job.grade)) or (Config.QBCore and (data.job[PlayerData.job.name] and data.job[PlayerData.job.name] <= PlayerData.job.grade.level))))
		and (data.item == nil or data.item and ConfigFunctions.ItemCount(data.item))
		and (data.shouldShow == nil or not data.shouldShow or data.shouldShow(entity)) then return true end
		return false
	end
else
	ConfigFunctions.CheckOptions = function(data, entity, distance)
		if (data.distance == nil or distance <= data.distance)
		and (data.shouldShow == nil or not data.shouldShow or data.shouldShow(entity)) then return true end
		return false
	end
end

ConfigFunctions.CloneTable = function(t)
	local copy = {}
	for k,v in pairs(t) do
		if type(v) == 'table' then
			copy[k] = ConfigFunctions.CloneTable(v)
		else
			if type(v) == 'function' then v = nil end
			copy[k] = v
		end
	end
	return copy
end

-- When loading this file, return these tables
return Config, Entities, Models, Zones, Bones, Players, Types, Intervals, ConfigFunctions, PlayerData
