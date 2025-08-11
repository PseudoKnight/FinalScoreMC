bind('entity_toggle_glide', array('priority': 'MONITOR'), null, @event) {
	if(@event['gliding'] && !is_cancelled()) {
		play_sound(entity_loc(@event['id']),
				array('sound': 'ENTITY_ENDER_DRAGON_FLAP', 'category': 'PLAYERS', 'pitch': 1.3, 'volume': 0.4));
	}
}

bind('item_swap', array('priority': 'MONITOR'), null, @event) {
	if(!is_cancelled() && (pinv(player(), null) || pinv(player(), -106))) {
		play_sound(ploc(), array('sound': 'ITEM_ARMOR_EQUIP_GENERIC', 'category': 'PLAYERS'), player());
	}
}
