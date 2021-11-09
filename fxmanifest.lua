fx_version 'cerulean'
game 'gta5'

author 'BerkieB'
description 'An optimised interaction system for FiveM'
version '4.1.0'

ui_page 'html/index.html'

client_scripts {
	'@PolyZone/client.lua',
	'@PolyZone/BoxZone.lua',
	'@PolyZone/EntityZone.lua',
	'@PolyZone/CircleZone.lua',
	'@PolyZone/ComboZone.lua',
	'config.lua',
	'client/*.lua',
}

files {
	'html/*.html',
	'html/css/*.css',
	'html/js/*.js'
}

dependency 'PolyZone'