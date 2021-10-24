fx_version 'cerulean'
game 'gta5'

author 'BerkieB & Contributors'
description 'A better interaction for FiveM, a third eye for you to interact with and keep your server optimised!'
version '3.1.2'

ui_page 'html/index.html'

client_scripts {
	'@PolyZone/client.lua',
	'@PolyZone/BoxZone.lua',
	'@PolyZone/EntityZone.lua',
	'@PolyZone/CircleZone.lua',
	'@PolyZone/ComboZone.lua',
	'client/*.lua',
}

files {
	'config.lua',
	'html/*.html',
	'html/css/*.css',
	'html/js/*.js'
}

dependencies {
	'PolyZone',
	'qb-core'
}
