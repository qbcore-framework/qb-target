fx_version 'cerulean'
game 'gta5'

version '2.0.0'

dependency "PolyZone"

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

server_script 'server/main.lua'

files {
	'html/*.html',
	'html/css/*.css',
	'html/js/*.js'
}
