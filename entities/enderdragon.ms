bind('creature_spawn', null, array('type': 'ENDER_DRAGON'), @event) {
	if(@event['location']['world'] == 'outworld') {
		store_value('enderdragon', true);
	}
}

bind('player_join', null, null, @event) {
	set_timeout(2000, closure() {
		if(get_value('enderdragon')) {
			play_sound(ploc(), array('sound': 'ENTITY_ENDER_DRAGON_GROWL', 'volume': 0.3), player());
		}
	});
}

bind('entity_death', null, array('type': 'ENDER_DRAGON'), @event) {
	if(@event['xp'] < 12000) {
		modify_event('xp', 12000);
		@loc = get_highest_block_at(0, 0, @event['location']['world']);
		@loc['y'] += 1;
		set_block(@loc, 'DRAGON_EGG');
	}
	if(@event['location']['world'] == 'outworld') {
		clear_value('enderdragon');
	}
}