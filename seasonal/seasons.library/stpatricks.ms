bind(creature_spawn, null, array('type': 'ZOMBIE', 'reason': 'NATURAL'), @event) {
	if(!rand(3)) {
		@id = @event['id'];
		set_entity_spec(@id, array('baby': true));
		set_mob_equipment(@id, array(
			'HELMET': array('name': 'LEATHER_HELMET', 'meta': array('color': array(0, 255, 0))),
			'CHESTPLATE': array('name': 'LEATHER_CHESTPLATE', 'meta': array('color': array(0, 255, 0))),
			'LEGGINGS': array('name': 'LEATHER_LEGGINGS', 'meta': array('color': array(0, 255, 0))),
			'BOOTS': array('name': 'LEATHER_BOOTS', 'meta': array('color': array(0, 255, 0))),
			'WEAPON': array('name': 'STICK'),
			'OFF_HAND': array('name': 'GOLD_INGOT'),
		));
		set_equipment_droprates(@id, array(
			'HELMET': 0.1,
			'CHESTPLATE': 0.1,
			'LEGGINGS': 0.1,
			'BOOTS': 0.1,
			'WEAPON': 0.1,
			'OFF_HAND': 1,
		));
		set_mob_effect(@id, 1, 0, 99999);
		set_entity_silent(@id, true);
	}
}

bind(target_player, null, array('mobtype': 'ZOMBIE'), @event) {
	if(get_entity_silent(@event['id'])) {
		play_sound(entity_loc(@event['id']), array('sound': 'ENTITY_WITCH_AMBIENT', 'pitch': 2, 'volume': 3));
	}
}
