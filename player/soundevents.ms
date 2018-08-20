bind('entity_toggle_glide', array('priority': 'MONITOR'), null, @event) {
	if(@event['gliding'] && !is_cancelled()) {
		play_sound(entity_loc(@event['id']),
				array('sound': 'ENTITY_ENDER_DRAGON_FLAP', 'category': 'PLAYERS', 'pitch': 1.3, 'volume': 0.4));
	}
}

bind('item_swap', array('priority': 'MONITOR'), null, @event) {
	if(!is_cancelled()) {
		play_sound(ploc(), array('sound': 'ITEM_ARMOR_EQUIP_GENERIC', 'category': 'PLAYERS'), player());
	}
}

bind('entity_damage', array('priority': 'MONITOR'), array('type': 'PLAYER'), @event) {
	if(@event['finalamount'] == 0 && @event['amount'] > 0) {
		@equipment = get_mob_equipment(@event['id']);
		if(@equipment['off_hand'] && @equipment['off_hand']['name'] == 'SHIELD'
		|| @equipment['weapon'] && @equipment['weapon']['name'] == 'SHIELD') {
			play_sound(@event['location'], array('sound': 'ITEM_SHIELD_BLOCK', 'category': 'PLAYERS'));
		}
	}
}
