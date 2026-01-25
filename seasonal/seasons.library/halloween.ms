bind('creature_spawn', null, null, @event) {
	if(@event['location']['world'] === 'outworld'
	&& array_contains(array('SPIDER', 'PHANTOM', 'ENDERMAN'), @event['type'])
	&& !rand(3)) {
		set_mob_effect(@event['id'], 'invisibility', 0, -1);
	}
}

bind('creature_spawn', null, array(type: 'ZOMBIE', reason: 'NATURAL'), @event) {
	if(sk_region_check_flag(@event['location'], 'deny-spawn')) {
		die();
	}
	@id = @event['id'];
	@rand = rand(5);
	if(@rand == 0 && @event['location']['world'] === 'outworld'){
		cancel();
		switch(rand(6)) {
			case 0:
				spawn_entity('VINDICATOR', 1, @event['location'], closure(@vindicator) {
					if(rand(2)) {
						set_mob_name(@vindicator, 'Johnny');
						set_entity_persistence(@vindicator, false);
					}
				});
			case 1:
				spawn_entity('EVOKER', 1, @event['location']);
			case 2:
				spawn_entity('RABBIT', 1, @event['location'], closure(@rabbit) {
					set_entity_spec(@rabbit, array(type: 'THE_KILLER_BUNNY'));
					set_entity_persistence(@rabbit, false);
				});
			case 3:
				spawn_entity('ILLUSIONER', 1, @event['location']);
			case 4:
				spawn_entity('VEX', 1, @event['location'], closure(@vex) {
					set_mob_equipment(@vex, array(weapon: null));
				});
			case 5:
				spawn_entity('CREAKING', 1, @event['location']);
		}
	} else if(@rand == 1) {
		set_mob_equipment(@id, array(
			weapon: array(name: 'ZOMBIE_HEAD'),
			helmet: null,
			chestplate: array(name: 'LEATHER_CHESTPLATE'),
			leggings: array(name: 'LEATHER_LEGGINGS'),
			boots: array(name: 'LEATHER_BOOTS'),
		));
		set_mob_effect(@id, 'invisibility', 0, -1);
	} else if(@rand == 2 && @event['location']['world'] === 'outworld') {
		set_mob_equipment(@id, array(
			helmet: array(name: 'PLAYER_HEAD', meta: array(
				owneruuid: '5777109f-f9ab-4af6-b87d-59d504a5b437',
				texture: 'eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvOThiN2NhM2M3ZDMxNGE2MWFiZWQ4ZmMxOGQ3OTdmYzMwYjZlZmM4NDQ1NDI1YzRlMjUwOTk3ZTUyZTZjYiJ9fX0='
			)),
			chestplate: array(name: 'LEATHER_CHESTPLATE', meta: array(color: array(50, 230, 255))),
			leggings: array(name: 'LEATHER_LEGGINGS', meta: array(color: array(70, 60, 222))),
			boots: null,
			weapon: null,
		));
		set_equipment_droprates(@id, array(
			helmet: null,
			chestplate: null,
			leggings: null,
		));
		add_scoreboard_tag(@id, 'Herobrine');
		set_mob_effect(@id, 'SPEED', 7, -1, true, false);
		set_entity_silent(@id, true);
	} else {
		set_mob_equipment(@id, array(helmet: array(name: 'JACK_O_LANTERN')));
		if(!rand(3)) {
			set_mob_effect(@id, 'invisibility', 0, -1);
		}
	}
}

bind('creature_spawn', null, array(type: 'SKELETON', reason: 'NATURAL'), @event) {
	set_mob_equipment(@event['id'], array(helmet: array(name: 'JACK_O_LANTERN')));
}

bind('entity_damage', array(priority: 'LOWEST'), array(type: 'ZOMBIE', cause: 'ENTITY_ATTACK', world: 'outworld'), @event) {
	if(has_scoreboard_tag(@event['id'], 'Herobrine')) {
		try(entity_remove(@event['id']))
		play_sound(@event['location'], array(sound: 'ENTITY_EVOKER_PREPARE_ATTACK', pitch: 0.7));
		spawn_particle(location_shift(@event['location'], 'up'), array(particle: 'CAMPFIRE_COSY_SMOKE', count: 3, yoffset: 1));
	}
}

bind('entity_damage_player', null, array(damager: 'ZOMBIE'), @event) {
	if(has_scoreboard_tag(@event['id'], 'Herobrine')) {
		try(entity_remove(@event['id']))
		play_sound(@event['location'], array(sound: 'ENTITY_EVOKER_PREPARE_ATTACK', pitch: 0.7));
		spawn_particle(location_shift(@event['location'], 'up'), array(particle: 'CAMPFIRE_COSY_SMOKE', count: 3, yoffset: 1));
	}
}

bind('target_player', null, array(mobtype: 'ZOMBIE'), @event) {
	@id = @event['id'];
	if(entity_exists(@id) && has_scoreboard_tag(@id, 'Herobrine')) {
		@loc = entity_loc(@id);
		@timer = array(160);
		set_interval(50, closure(){
			@timer[0]--;
			if(!entity_exists(@id)) {
				clear_task();
			} else if(!ponline(@event['player']) || pworld(@event['player']) !== @loc['world'] || @timer[0] < 0) {
				clear_task();
				try(entity_remove(@id))
			} else {
				@newLoc = entity_loc(@id);
				@dist = distance(ploc(@event['player']), @newLoc);
				if(@dist > 14) {
					play_sound(@newLoc, array(sound: 'ENTITY_EVOKER_PREPARE_ATTACK', pitch: 0.5 + rand() * 1.5, volume: 2));
				} else if(@dist > 8) {
					set_mob_effect(@id, 'invisibility', 1, -1, true, false);
					set_mob_equipment(@id, array(
						helmet: null,
						chestplate: null,
						leggings: null,
					));
					stop_sound(@event['player'], 'ENTITY_EVOKER_PREPARE_ATTACK');
				} else {
					set_mob_effect(@id, 'invisibility', 0, 0, true, false);
					set_mob_equipment(@id, array(
						helmet: array(name: 'PLAYER_HEAD', meta: array(
							display: 'Herobrine\'s Head',
							owneruuid: '00000000-0000-0048-6572-6f6272696e65',
							texture: 'eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvOThiN2NhM2M3ZDMxNGE2MWFiZWQ4ZmMxOGQ3OTdmYzMwYjZlZmM4NDQ1NDI1YzRlMjUwOTk3ZTUyZTZjYiJ9fX0='
						)),
						chestplate: array(name: 'LEATHER_CHESTPLATE', meta: array(color: array(50, 230, 255))),
						leggings: array(name: 'LEATHER_LEGGINGS', meta: array(color: array(70, 60, 222))),
					));
					play_sound(@newLoc, array(sound: 'ENTITY_EVOKER_PREPARE_ATTACK', pitch: 0.5 + rand() * 1.5, volume: 2));
				}
			}
		});
	}
}