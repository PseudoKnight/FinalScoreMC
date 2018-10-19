bind('creature_spawn', null, null, @e) {
	if(array_contains(array('SPIDER', 'PHANTOM', 'WITCH', 'ENDERMAN'), @e['type']) && !rand(3)) {
		set_mob_effect(@e['id'], 'invisibility', 0, 99999);
	}
}

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
		add_scoreboard_tag(@e['id'], 'halloween');
	} else if(@rand == 3) {
		set_mob_equipment(@e['id'], array(
			'WEAPON': array('name': 'ZOMBIE_HEAD'),
			'HELMET': null,
			'CHESTPLATE': array('name': 'LEATHER_CHESTPLATE'),
			'LEGGINGS': array('name': 'LEATHER_LEGGINGS'),
			'BOOTS': array('name': 'LEATHER_BOOTS'),
		));
		set_mob_effect(@e['id'], 14, 0, 99999);
		add_scoreboard_tag(@e['id'], 'halloween');
	} else if(@rand == 2 && @e['location']['world'] == 'outworld'){
		cancel();
		@vindicator = spawn_entity('VINDICATOR', 1, @e['location'])[0];
		set_mob_name(@vindicator, 'Johnny');
	} else if(@e['location']['world'] == 'outworld' && !entities_in_radius(@e['location'], 64, 'RABBIT')) {
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
	&& (get_entity_persistence(@e['id']) || array_contains(get_scoreboard_tags(@e['id']), 'halloween'))) {
		modify_event('drops', array(array('name': 'ZOMBIE_HEAD')));
	}
}

bind('creature_spawn', null, array('type': 'SKELETON', 'reason': 'NATURAL'), @e) {
	if(!rand(10)) {
		add_scoreboard_tag(@e['id'], 'halloween');
		if(rand(3)) {
			set_mob_equipment(@e['id'], array(
				'WEAPON': array('name': 'BOW', 'meta': array('enchants': array('power': 2, 'punch': 1))),
				'HELMET': array('name': 'JACK_O_LANTERN'),
				'CHESTPLATE': array('name': 'IRON_CHESTPLATE'),
				'LEGGINGS': array('name': 'LEATHER_LEGGINGS'),
				'BOOTS': array('name': 'LEATHER_BOOTS'),
			));
		} else {
			set_mob_equipment(@e['id'], array(
				'WEAPON': array('name': 'BOW', 'meta': array('enchants': array('power': 2, 'flame': 1))),
				'HELMET': array('name': 'JACK_O_LANTERN'),
				'CHESTPLATE': array('name': 'DIAMOND_CHESTPLATE'),
				'LEGGINGS': array('name': 'IRON_LEGGINGS'),
				'BOOTS': array('name': 'IRON_BOOTS'),
			));
		}
	}
}

bind('entity_death', null, array('type': 'SKELETON'), @e) {
	if(array_index_exists(@e['cause'], 'cause') && @e['cause']['cause'] === 'ENTITY_ATTACK'
	&& length(@e['cause']['damager']) < 17
	&& !rand(10)
	&& (get_entity_persistence(@e['id']) || array_contains(get_scoreboard_tags(@e['id']), 'halloween'))) {
		modify_event('drops', array(array('name': 'SKELETON_SKULL')));
	}
}
