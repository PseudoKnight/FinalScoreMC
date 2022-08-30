proc _arena_prepare(@pvp) {
	@world = @pvp['arena']['lobby'][3];
	_generator_create('scaled_level', 'showdown', 'showdowndungeon', @world, 0, closure(@start, @end, @spawns) {
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

		@itemSpawns = @spawns[cslice(integer(length(@spawns) / 2), -1)];
		@pvp['arena']['itemspawn'] = array();
		foreach(@spawn in @itemSpawns) {
			@pvp['arena']['itemspawn'][] = array(
				start: true,
				cooldown: 60,
				loc: @spawn,
				item: array(name: 'LILY_PAD', meta: array(enchants: array(unbreaking: 1))),
			);
			set_block(location_shift(@spawn, 'down'), 'EMERALD_BLOCK');
		}
	});
}

proc _arena_bind_events(@id) {}