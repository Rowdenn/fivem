fx_version 'cerulean'
game 'gta5'

name "r_banking"
description "Système de banque"
author "Rowden"
version "1.0.0"

dependencies {
	'framework',
	'r_notify'
}

shared_scripts {
	'shaed/*.lua'
}

client_scripts {
	'client/*.lua'
}

server_scripts {
	'server/*.lua'
}
