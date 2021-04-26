proc _bind(@pvp) {
	@pvp['binds'][] = bind('player_interact', null, array(block: 'CHEST'), @e, @pvp) {
		if(!array_index_exists(@pvp['players'], player())) {
			die();
		}
		@arena = @pvp['arena'];
		for(@i = 0, @i < array_size(@arena['chestspawn']), @i++) {
			if(@arena['chestspawn'][@i]['loc'][0] == @e['location'][0]
			&& @arena['chestspawn'][@i]['loc'][1] == @e['location'][1]
			&& @arena['chestspawn'][@i]['loc'][2] == @e['location'][2]
			&& array_index_exists(@arena['chestspawn'][@i], 'cooldown')) {
				cancel();
				@loc = @e['location'];
				set_block(@loc, 'AIR');
				@loc = @e['location'];
				@loc['x'] += 0.5;
				@loc['y'] += 0.5;
				@loc['z'] += 0.5;
				spawn_particle(@loc, array(
					particle: 'BLOCK_CRACK',
					count: 10,
					xoffset: 0.5,
					yoffset: 0.5,
					zoffset: 0.5,
					block: 'CHEST'
				));
				play_sound(@loc, array(sound: 'BLOCK_WOOD_BREAK'));
				@pvp['chestspawn'][@i] = time();
				if(array_index_exists(@pvp, 'stats')) {
					@pvp['stats'][player()]['pickups']++;
				}
				break();
			}
		}
	}
}