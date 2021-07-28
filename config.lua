local Config, Entities, Models, Zones, Bones, Players, Types, Intervals, ConfigFunctions, PlayerData = {}, {}, {}, {}, {}, {}, {}, {}, {}, {}
Types[1], Types[2], Types[3] = {}, {}, {}

Config.ESX = false
Config.QBCore = true
Config.UseGrades = false
Config.LindenInventory = false
Config.MaxDistance = 2 -- Fallback for if you left the distance in the wrong place or forgot it
Config.Debug = false -- Debug mode

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

return Config, Entities, Models, Zones, Bones, Players, Types, Intervals, ConfigFunctions, PlayerData
