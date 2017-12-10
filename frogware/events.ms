# Calculate trophies
bind(player_join, null, null, @event) {
	queue_push(closure(){
		try {
			@uuid = puuid(player(), true);
		} catch(PlayerOfflineException @ex) {
			return();
		}
		@frogs = get_value('frogware');
		if(array_contains(@frogs, player())) {
			@session = _psession(player());
			if(!array_index_exists(@session, 'trophies')) {
				@session['trophies'] = array();
			}
			@session['trophies'][] = color('yellow').'Best Frog in the House!';
		}

	}, 'trophies');
}
