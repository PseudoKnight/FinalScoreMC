bind('creature_spawn', null, null, @e) {
	if(@e['location']['world'] == 'outworld'
	&& array_contains(array('SPIDER', 'PHANTOM', 'WITCH', 'ENDERMAN'), @e['type'])
	&& !rand(3)) {
		set_mob_effect(@e['id'], 'invisibility', 0, 107374182);
	}
}

bind('creature_spawn', null, array('type': 'CREEPER', 'reason': 'NATURAL'), @e) {
	if(@e['location']['world'] == 'outworld' && !rand(4)) {
		set_entity_spec(@e['id'], array('powered': true));
	}
}

bind('creature_spawn', null, array('type': 'ZOMBIE', 'reason': 'NATURAL'), @e) {
	@rand = rand(4);
	if(@rand == 3 && @e['location']['world'] == 'outworld'){
		cancel();
		switch(rand(4)) {
			case 0:
				@vindicator = spawn_entity('VINDICATOR', 1, @e['location'])[0];
				if(rand(2)) {
					set_mob_name(@vindicator, 'Johnny');
				}
			case 1:
				spawn_entity('EVOKER', 1, @e['location']);
			case 2:
				spawn_entity('ILLUSIONER', 1, @e['location']);
			case 3:
				@rabbit = spawn_entity('RABBIT', 1, @e['location'])[0];
				set_entity_spec(@rabbit, array('type': 'THE_KILLER_BUNNY'));
		}
	} else if(@rand == 2) {
		set_mob_equipment(@e['id'], array(
			'WEAPON': array('name': 'ZOMBIE_HEAD'),
			'HELMET': null,
			'CHESTPLATE': array('name': 'LEATHER_CHESTPLATE'),
			'LEGGINGS': array('name': 'LEATHER_LEGGINGS'),
			'BOOTS': array('name': 'LEATHER_BOOTS'),
		));
		set_mob_effect(@e['id'], 'invisibility', 0, 107374182);
		add_scoreboard_tag(@e['id'], 'halloween');
	} else {
		set_mob_equipment(@e['id'], array('HELMET': array('name': 'JACK_O_LANTERN')));
		if(rand(2)) {
			set_mob_effect(@e['id'], 'invisibility', 0, 107374182);
		}
		add_scoreboard_tag(@e['id'], 'halloween');
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
	if(@e['location']['world'] == 'outworld' && !rand(4)) {
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
