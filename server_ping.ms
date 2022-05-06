/*
	This is the output for the multiplayer server list.
 */
bind('server_ping', null, null, @event) {
	@currently = _get_activities_string();
	@motd = colorize('&6&l\u1260&d&l\u1260&b&l\u1260&4&l\u1260 &6&lFINALSCORE&e&lMC \u00AB &f\u25AA \u25AA \u25AA');
	modify_event('motd', @motd.if(@currently, colorize('\n&aActivities&f: ').@currently));
}
