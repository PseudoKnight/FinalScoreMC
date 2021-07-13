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
	if(@event['location']['world'] == 'outworld') {
		clear_value('enderdragon');
	}
}