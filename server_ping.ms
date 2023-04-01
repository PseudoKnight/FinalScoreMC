/*
	This is the output for the multiplayer server list.
 */
bind('server_ping', null, null, @event) {
	@motd = colorize('&6&l\u1260&d&l\u1260&b&l\u1260&4&l\u1260 &6&lFINALSCORE&e&lMC \u00AB &f\u25AA \u25AA \u25AA');
	@activities = import('activities', array());
	@seasonalEvent = import('event');
	if(@activities || @seasonalEvent) {
		@motd .= '\n';
		if(@seasonalEvent) {
			@motd .= color('gray').'['.@seasonalEvent.color('gray').']';
		}
		foreach(@activity in @activities) {
			@motd .= color('gray').' ['.color('white').@activity['title'].color('gray').']';
		}
	}
	modify_event('motd', @motd);
}
