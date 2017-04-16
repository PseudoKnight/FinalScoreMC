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

bind(entity_damage, array('priority': 'MONITOR'), array('type': 'PLAYER'), @event) {
	if(@event['finalamount'] == 0 && @event['amount'] > 0) {
		@equipment = get_mob_equipment(@event['id']);
		if(@equipment['off_hand'] && @equipment['off_hand']['name'] == 'SHIELD'
		|| @equipment['weapon'] && @equipment['weapon']['name'] == 'SHIELD') {
			play_named_sound(@event['location'], array('sound': 'item.shield.block', 'category': 'PLAYERS'));
		}
	}
}
