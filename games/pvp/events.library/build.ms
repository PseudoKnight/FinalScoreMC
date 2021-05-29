proc _bind(@pvp) {
	@pvp['binds'][] = bind('block_break', null, null, @e, @pvp) {
		if(array_index_exists(@pvp['players'], player())) {
			cancel();
		}
	}

	@pvp['binds'][] = bind('block_place', null, null, @e, @pvp) {
		if(array_index_exists(@pvp['players'], player())) {
			cancel();
		}
	}
}