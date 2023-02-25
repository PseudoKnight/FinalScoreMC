/*
	This is the output for the multiplayer server list.
 */
bind('server_ping', null, null, @event) {
	@motd = colorize('&6&l\u1260&d&l\u1260&b&l\u1260&4&l\u1260 &6&lFINALSCORE&e&lMC \u00AB &f\u25AA \u25AA \u25AA');
	@activities = import('activities');
	if(@activities) {
		@motd .= color('GREEN').'\nCurrently Playing: '.color('WHITE');
		foreach(@activity in @activities) {
			@motd .= ' ['.@activity['title'].']';
		}
	}
	modify_event('motd', @motd);
}
