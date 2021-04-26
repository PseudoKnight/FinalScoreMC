proc _bind(@pvp) {
	@pvp['binds'][] = bind('inventory_click', null, null, @e, @pvp) {
		if(array_index_exists(@pvp['players'], player())) {
			cancel();
		}
	}

	@pvp['binds'][] = bind('item_swap', null, null, @e, @pvp) {
		if(array_index_exists(@pvp['players'], player())) {
			cancel();
		}
	}
}