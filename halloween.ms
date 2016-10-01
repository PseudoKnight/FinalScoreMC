bind(creature_spawn, null, array('type': 'ZOMBIE', 'reason': 'NATURAL'), @e) {
	queue_push(closure(){
		try(
			if(rand(2)) {
				set_mob_equipment(@e['id'], array('HELMET': array('name': 'JACK_O_LANTERN')));
				if(rand(2)) {
					set_mob_effect(@e['id'], 14, 0, 99999);
				}
			} else {
				set_mob_equipment(@e['id'], array(
					'WEAPON': array('name': 'PUMPKIN'),
					'HELMET': array('name': 'CARROT_ITEM'),
					'CHESTPLATE': array('name': 'LEATHER_CHESTPLATE'),
					'LEGGINGS': array('name': 'LEATHER_LEGGINGS'),
					'BOOTS': array('name': 'LEATHER_BOOTS'),
				));
				set_mob_effect(@e['id'], 14, 0, 99999);
			}
		);
	}, 'zombies');
}

bind(entity_death, null, array('type': 'ZOMBIE'), @e) {
	if(@e['cause']['cause'] === 'ENTITY_ATTACK'
	&& ponline(@e['cause']['damager'])
	&& !rand(15)
	&& array_size(entities_in_radius(entity_loc(@e['id']), 2, 'ZOMBIE')) == 1) {
		modify_event('drops', array(array('name': 'SKULL_ITEM', 'data': 2)));
	}
}

bind(creature_spawn, null, array('type': 'SKELETON', 'reason': 'NATURAL'), @e) {
	if(@e['location']['y'] > 62 && !rand(18)) {
		queue_push(closure(){
			try(
				set_entity_persistence(@e['id'], true);
				/*
				Enable in 1.11+
				@horse = spawn_mob('HORSE', 1, @e['location'])[0];
				set_entity_spec(@horse, array('variant': if(rand(2), 'SKELETON', 'ZOMBIE')));
				set_entity_rider(@horse, @e['id']);
				*/
				if(rand(3)) {
					set_mob_equipment(@e['id'], array(
						'WEAPON': array('name': 'BOW', 'enchants': array(array('etype': 'ARROW_DAMAGE', 'elevel': 2))),
						'HELMET': array('name': 'JACK_O_LANTERN'),
						'CHESTPLATE': array('name': 'IRON_CHESTPLATE'),
						'LEGGINGS': array('name': 'LEATHER_LEGGINGS'),
						'BOOTS': array('name': 'LEATHER_BOOTS'),
					));
				} else {
					set_mob_equipment(@e['id'], array(
						'WEAPON': array('name': 'BOW', 'enchants': array(array('etype': 'ARROW_DAMAGE', 'elevel': 2), array('etype': 'ARROW_FIRE', 'elevel': 1))),
						'HELMET': array('name': 'JACK_O_LANTERN'),
						'CHESTPLATE': array('name': 'DIAMOND_CHESTPLATE'),
						'LEGGINGS': array('name': 'IRON_LEGGINGS'),
						'BOOTS': array('name': 'IRON_BOOTS'),
					));
				}
			);
		}, 'skeletons');
	}
}

bind(entity_death, null, array('type': 'SKELETON'), @e) {
	if(@e['cause']['cause'] === 'ENTITY_ATTACK'
	&& ponline(@e['cause']['damager'])
	&& !rand(15)
	&& array_size(entities_in_radius(entity_loc(@e['id']), 2, 'SKELETON')) == 1) {
		modify_event('drops', array(array('name': 'SKULL_ITEM')));
	}
}
