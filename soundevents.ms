bind(entity_toggle_glide, array('priority': 'MONITOR'), null, @event) {
	if(@event['gliding'] && !is_cancelled()) {
		play_sound(entity_loc(@event['id']),
				array('sound': 'ENDERDRAGON_WINGS', 'category': 'PLAYERS', 'pitch': 1.3, 'volume': 0.4));
	}
}

bind(item_swap, array('priority': 'MONITOR'), null, @event) {
	if(!is_cancelled()) {
		play_named_sound(ploc(), array('sound': 'item.armor.equip_generic', 'category': 'PLAYERS'), player());
	}
}
