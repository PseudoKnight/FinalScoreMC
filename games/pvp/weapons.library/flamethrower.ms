proc _weapon_bind_events(@pvp) {
	@pvp['binds'][] = bind('player_interact', null, array(itemname: 'BREWING_STAND', button: 'right', hand: 'main_hand'), @e, @pvp) {
		if(!array_index_exists(@pvp['players'], player())) {
			die();
		}

		@xp = pexp();
		if(@xp == 0) {
			play_sound(ploc(), array(sound: 'ITEM_FLINTANDSTEEL_USE'));
			die();
		}

		@loc = ploc();
		play_sound(@loc, array(sound: 'BLOCK_FIRE_EXTINGUISH', pitch: 0.7));
		play_sound(@loc, array(sound: 'ENTITY_CAT_HISS', volume: 0.2, pitch: 0.7));
		play_sound(@loc, array(sound: 'BLOCK_FIRE_AMBIENT', volume: 2));

		@facing = pfacing(player());
		@facing[0] = @facing[0] + 90;
		@facing[1] = 0 - @facing[1];
		@x = cos(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
		@y = sin(to_radians(@facing[1]));
		@z = sin(to_radians(@facing[0])) * cos(to_radians(@facing[1]));

		@loc['y'] += 2;
		@target = array(world: @loc['world']);
		@id = time();
		for(@range = 1, @range <= 6, @range++) {
			queue_push(closure(){
				@target['x'] = @loc['x'] + (@x * @range);
				@target['y'] = @loc['y'] + (@y * @range);
				@target['z'] = @loc['z'] + (@z * @range);
				spawn_particle(@target, array(
					particle: 'FLAME',
					count: @range * 2,
					speed: 0.02,
					xoffset: 0.028 * @range,
					yoffset: 0.028 * @range,
					zoffset: 0.028 * @range,
					force: true,
				));
				spawn_particle(@target, array(particle: 'CLOUD', speed: 0.03, force: true));
				foreach(@p in array_keys(@pvp['players'])) {
					if(@p == player() || phealth(@p) == 0) {
						continue();
					}
					@ploc = ploc(@p);
					@ploc['y'] += 1.9;
					@dist = distance(@ploc, @target);
					if(@dist < 1.4) {
						@uuid = puuid(@p);
						if(entity_can_see(puuid(), @uuid)) {
							damage_entity(@uuid, 1.5, puuid());
							set_entity_onfire(@uuid, 1);
						} else {
							damage_entity(@uuid, 0.5, puuid());
						}
						continue();
					}
				}
			}, @id);
		}

		set_pexp(player(), max(0, @xp - 1));
	}
}
