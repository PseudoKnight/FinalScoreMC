// Block enderchests when not in survival worlds
bind('player_interact', null, array(block: 'ENDER_CHEST', button: 'right'), @event) {
	if(!has_metadata(@event['location']['world'], 'survival')) {
		cancel();
	}
}