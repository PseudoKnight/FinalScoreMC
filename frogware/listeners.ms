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
            @pstate = _pstate(player());
            if(!array_index_exists(@pstate, 'trophies')) {
                @pstate['trophies'] = array();
            }
            @pstate['trophies'][] = color('yellow').'Best Frog in the House!';
        }

	}, 'trophies');
}
