proc _arena_prepare(@pvp) {
	@world = @pvp['arena']['lobby'][3];
	_generator_create('dungeon_v1', 'showdown', 'showdowndungeon', @world, 0, closure(@start, @end, @spawns) {
		@spawns = @spawns[0]; // we only want one floor
		@playerSpawns = @spawns[cslice(0, integer(length(@spawns) / 2) - 1)];
		@itemSpawns = @spawns[cslice(integer(length(@spawns) / 2), -1)]
		@pvp['arena']['spawn'] = array(@playerSpawns);
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

proc _arena_bind_events(@id) {
	noop();
}