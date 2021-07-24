Config = {}

Config.ESX = false
Config.QBCore = true
Config.DropPlayer = false -- Drop player if they attempt to trigger an invalid event
Config.UseGrades = false -- Add grades to the job parameter
Config.LindenInventory = false

-- The following tables in the configs are examples, the only thing you have to replace is the event for it to work
-- DON'T delete these tables, they WILL cause errors after deletion, comment/delete everything inside the table instead of the 'Config.' table and the end '}'
-- Also, put the job parameter INSIDE the options table when adding a target
-- If you're not using ESX or QBCore or haven't converted it to your own framework, you can set the job to false to disable the 'framework stuff', same goes for the item

-- The config tables are empty until I've made a wiki on how to fill them out and made a few example files of these.

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

Config.VehicleBones = {
    'chassis',  
    'windscreen',  
    'seat_pside_r',  
    'seat_dside_r',  
    'bodyshell',  
    'suspension_lm',  
    'suspension_lr',  
    'platelight',  
    'attach_female',  
    'attach_male',  
    'bonnet',  
    'boot',  
    'chassis_dummy',	
    'chassis_Control',	
    'door_dside_f',	
    'door_dside_r',	
    'door_pside_f',	
    'door_pside_r',	
    'Gun_GripR',  
    'windscreen_f',  
    'platelight',	
    'VFX_Emitter',  
    'window_lf',	
    'window_lr',	
    'window_rf',	
    'window_rr',	
    'engine',	
    'gun_ammo',  
    'ROPE_ATTATCH',	
    'wheel_lf',
    'wheel_lr',	
    'wheel_rf',	
    'wheel_rr',	
    'exhaust',	
    'overheat',	
    'misc_e',	
    'seat_dside_f',
    'seat_pside_f',
    'Gun_Nuzzle',  
    'seat_r',  
}
