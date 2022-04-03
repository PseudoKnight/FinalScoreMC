proc _bind(@pvp) {
	@pvp['binds'][] = bind('item_pickup', array(priority: 'HIGH'), array(itemname: @pvp['arena']['powerup']), @e, @pvp) {
		if(!array_index_exists(@pvp['players'], player())) {
			die();
		}

		modify_event('item', null);
		consume();
		_classes_powerup(player(), @pvp['players'][player()]['class'], @pvp);
		if(array_index_exists(@pvp, 'stats')) {
			@pvp['stats'][player()]['pickups']++;
		}
	}
}