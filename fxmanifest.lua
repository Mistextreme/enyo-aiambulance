fx_version "cerulean"
game "gta5"

author 'EnyoScripts'
description 'Enyo\'s Scripts https://discord.gg/qrKzGB9h2W'

version '1.10.5'

shared_script {
    '@qb-core/shared/locale.lua',
    '@es_extended/imports.lua',
    'config.lua'
} 

server_scripts {
	'server/main.lua',
	'server/editable-main.lua',
}

client_scripts {
	'client/main.lua',
	'client/editable-main.lua',
}

escrow_ignore {
  'config.lua',  -- Only ignore one file
  'client/editable-main.lua',  -- Only ignore one file
  'server/editable-main.lua',  -- Only ignore one file
  'videos/*',  -- Only ignore one file
}

files {
    'stream/*',
    'html/*',
    'videos/*',
}

ui_page 'html/cutscene.html'

-- NUI callback handler for when the video ends
nui_page 'html/cutscene.html'

lua54 'yes'
dependency '/assetpacks'