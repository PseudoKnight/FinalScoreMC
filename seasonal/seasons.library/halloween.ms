bind('creature_spawn', null, array('type': 'CREEPER', 'reason': 'NATURAL'), @e) {
	if(@e['location']['world'] == 'outworld' && !rand(3)) {
		set_entity_spec(@e['id'], array('powered': true));
	}
}

bind('creature_spawn', null, array('type': 'PIG_ZOMBIE', 'reason': 'NATURAL'), @e) {
	if(@e['location']['world'] == 'outworld_nether' && !rand(6)) {
		set_entity_spec(@e['id'], array('baby': true));
	}
}

bind('creature_spawn', null, array('type': 'ZOMBIE', 'reason': 'NATURAL'), @e) {
	@rand = rand(5);
	if(@rand == 4) {
		set_mob_equipment(@e['id'], array('HELMET': array('name': 'JACK_O_LANTERN')));
		if(rand(2)) {
			set_mob_effect(@e['id'], 14, 0, 99999);
		}
		set_entity_persistence(@e['id'], true);
	} else if(@rand == 3) {
		set_mob_equipment(@e['id'], array(
			'WEAPON': array('name': 'SKULL_ITEM', 'data': 2),
			'HELMET': null,
			'CHESTPLATE': array('name': 'LEATHER_CHESTPLATE'),
			'LEGGINGS': array('name': 'LEATHER_LEGGINGS'),
			'BOOTS': array('name': 'LEATHER_BOOTS'),
		));
		set_mob_effect(@e['id'], 14, 0, 99999);
		set_entity_persistence(@e['id'], true);
	} else if(@rand == 2 && @e['location']['world'] == 'outworld'){
		cancel();
		@vindicator = spawn_entity('VINDICATOR', 1, @e['location'])[0];
		set_mob_name(@vindicator, 'Johnny');
	} else if(@e['location']['world'] == 'outworld') {
		cancel();
		@rabbit = spawn_entity('RABBIT', 1, @e['location'])[0];
		set_entity_spec(@rabbit, array('type': 'THE_KILLER_BUNNY'));
	}
}

bind('entity_death', null, array('type': 'ZOMBIE'), @e) {
	@gear = get_mob_equipment(@e['id']);
	if(@e['cause']['cause'] === 'ENTITY_ATTACK'
	&& length(@e['cause']['damager']) < 17
	&& !rand(10)
	&& get_entity_persistence(@e['id'])) {
		modify_event('drops', array(array('name': 'SKULL_ITEM', 'data': 2)));
	}
}

bind('creature_spawn', null, array('type': 'SKELETON', 'reason': 'NATURAL'), @e) {
	if(!rand(10)) {
		set_entity_persistence(@e['id'], true);
		if(rand(3)) {
			set_mob_equipment(@e['id'], array(
				'WEAPON': array('name': 'BOW', 'meta': array('enchants': array(array('etype': 'ARROW_DAMAGE', 'elevel': 2)))),
				'HELMET': array('name': 'JACK_O_LANTERN'),
				'CHESTPLATE': array('name': 'IRON_CHESTPLATE'),
				'LEGGINGS': array('name': 'LEATHER_LEGGINGS'),
				'BOOTS': array('name': 'LEATHER_BOOTS'),
			));
		} else {
			set_mob_equipment(@e['id'], array(
				'WEAPON': array('name': 'BOW', 'meta': array('enchants': array(array('etype': 'ARROW_DAMAGE', 'elevel': 2), array('etype': 'ARROW_FIRE', 'elevel': 1)))),
				'HELMET': array('name': 'JACK_O_LANTERN'),
				'CHESTPLATE': array('name': 'DIAMOND_CHESTPLATE'),
				'LEGGINGS': array('name': 'IRON_LEGGINGS'),
				'BOOTS': array('name': 'IRON_BOOTS'),
			));
		}
	}
}

bind('entity_death', null, array('type': 'SKELETON'), @e) {
	if(@e['cause']['cause'] === 'ENTITY_ATTACK'
	&& length(@e['cause']['damager']) < 17
	&& !rand(10)
	&& get_entity_persistence(@e['id'])) {
		modify_event('drops', array(array('name': 'SKULL_ITEM')));
	}
}

bind('creature_spawn', null, array('type': 'SPIDER', 'reason': 'NATURAL'), @e) {
	if(!rand(2)) {
		set_mob_effect(@e['id'], 14, 0, 99999);
	}
}
