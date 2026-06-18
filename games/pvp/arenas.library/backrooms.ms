proc _arena_prepare(@pvp) {
	@world = @pvp['arena']['world'];
	_generator_create('dungeon', 'backrooms', 'backrooms', @world, 0, closure(@start, @end, @spawns) {
		@spawns = @spawns[0]; // we only want one floor of spawns
		if(array_index_exists(@pvp, 'team')) {
			if(array_size(@spawns) == 1) {
				@pvp['arena']['spawn'] = array(@spawns, @spawns);
			} else {
				@splitIndex = min(integer((array_size(@spawns) - 1) / 2), 3);
				@team1Spawns = @spawns[cslice(0, @splitIndex)];
				@team2Spawns = @spawns[cslice(@splitIndex + 1, min(@splitIndex + 4, array_size(@spawns) - 1))];
				@pvp['arena']['spawn'] = array(@team1Spawns, @team2Spawns);
			}
		} else {
			@playerSpawns = @spawns[cslice(0, min(array_size(@spawns) - 1, 7))];
			@pvp['arena']['spawn'] = array(@playerSpawns);
		}
		// adjust each spawn location y-1 for set_ploc()
		foreach(@spawnGroup in @pvp['arena']['spawn']) {
			foreach(@spawn in @spawnGroup) {
				@spawn[1] -= 1;
			}
		}

		@remainingSpawnLocations = @spawns[cslice(min(array_size(@spawns) - 1, 7), -1)];
		@randomSpawnLocations = array_rand(@remainingSpawnLocations, array_size(@remainingSpawnLocations), false);
		@pvp['arena']['itemspawn'] = array();
		@pvp['arena']['mobspawn'] = array();
		@count = 0;
		foreach(@loc in @randomSpawnLocations) {
			// 10 item spawns but much longer cooldowns to encourage players to move around
			if(@count < 10) {
				@pvp['arena']['itemspawn'][] = array(
					start: true,
					cooldown: 120,
					loc: array(floor(@loc[0]) + 0.5, floor(@loc[1]), floor(@loc[2]) + 0.5, @loc[3]),
					item: array(name: 'LILY_PAD', meta: array(enchants: array(unbreaking: 1))),
				);
			} else if(@count < 15) {
				@pvp['arena']['mobspawn'][] = array(
					start: true,
					respawn: 3600,
					loc: array(floor(@loc[0]) + 0.5, floor(@loc[1]), floor(@loc[2]) + 0.5, @loc[3], rand(360), 0),
					type: array(type: 'ARMOR_STAND', scoreboardtags: array('remove')),
				);
			} else {
				break();
			}
			@count++;
		}
	});
}

proc _arena_bind_events(@id) {}