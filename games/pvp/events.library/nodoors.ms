proc _bind(@pvp) {
	@pvp['binds'][] = bind('player_interact', array(priority: 'LOWEST'), array(button: 'right'), @event, @pvp) {
		if(!is_cancelled()
		&& @event['block']
		&& array_index_exists(@pvp['players'], player())
		&& string_ends_with(@event['block'], 'DOOR')) {
			action_msg('Doors are disabled');
			cancel();
		}
	}
}