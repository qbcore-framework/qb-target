fx_version 'cerulean'
game 'gta5'

version '2.4.3'

ui_page 'html/index.html'

client_scripts {
	'@qb-core/import.lua',
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
	"PolyZone",
	"qb-core"
}
