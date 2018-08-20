array_push(@pvp['binds'], @id.'flamethrower');
bind('player_interact', array('id': @id.'flamethrower'), array('itemname': 'BREWING_STAND', 'button': 'right'), @e, @id) {
	@pvp = import('pvp'.@id);
	if(!array_index_exists(@pvp['players'], player()) || pinfo(player(), 6) != @e['item']['name']) {
		die();
	}
	
	@xp = pexp();
	if(@xp == 0) {
		play_sound(ploc(), array('sound': 'ITEM_FLINTANDSTEEL_USE'));
		die();
	}

	@loc = ploc();
	play_sound(@loc, array('sound': 'BLOCK_FIRE_EXTINGUISH', 'pitch': 0.7));
	play_sound(@loc, array('sound': 'ENTITY_CAT_HISS', 'volume': 0.2, 'pitch': 0.7));
	play_sound(@loc, array('sound': 'BLOCK_FIRE_AMBIENT', 'volume': 2));
	
	@facing = pfacing(player());
	@facing[0] = @facing[0] + 90;
	@facing[1] = 0 - @facing[1];
	@x = cos(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
	@y = sin(to_radians(@facing[1]));
	@z = sin(to_radians(@facing[0])) * cos(to_radians(@facing[1]));

	@loc['y'] += 2;
	@target = array('world': 'custom');
	@id = time();
	for(@range = 1, @range <= 8, @range++) {
		queue_push(closure(){
			@target['x'] = @loc['x'] + (@x * @range);
			@target['y'] = @loc['y'] + (@y * @range);
			@target['z'] = @loc['z'] + (@z * @range);
			spawn_particle(@target, array(
				'particle': 'FLAME',
				'count': @range * 2,
				'speed': 0.02,
				'xoffset': 0.028 * @range,
				'yoffset': 0.028 * @range,
				'zoffset': 0.028 * @range,
			));
			spawn_particle(@target, array('particle': 'CLOUD', 'speed': 0.03));
			foreach(@p in array_keys(@pvp['players'])) {
				if(@p == player() || phealth(@p) == 0) {
					continue();
				}
				@ploc = ploc(@p);
				@ploc['y'] += 1.9;
				@dist = distance(@ploc, @target);
				if(@dist < 1.4) { # 1.5 ^ 2
					@uuid = puuid(@p);
					if(entity_can_see(puuid(), @uuid)) {
						damage_entity(@uuid, 2, puuid());
						set_entity_onfire(@uuid, 2);
					} else {
						damage_entity(@uuid, 1, puuid());
					}
					continue();
				}
			}
		}, @id);
	}

	set_pexp(player(), max(0, @xp - 1));
}
