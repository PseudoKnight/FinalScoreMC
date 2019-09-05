bind('player_move', null, array('world': 'outworld'), @event) {
	@loc = ploc();
	@block = get_block(@loc);
	switch(@block) {
		case 'GRASS_BLOCK':
			set_block(@loc, 'DIRT');
		case 'DIRT':
			set_block(@loc, 'COARSE_DIRT');
		case 'COARSE_DIRT':
			set_block(@loc, 'GRAVEL');
		case 'GRAVEL':
			set_block(@loc, 'COBBLESTONE');
		case 'COBBLESTONE':
			set_block(@loc, 'ANDESITE');
		case 'ANDESITE':
			set_block(@loc, 'STONE');
	}

}

bind('item_despawn', null, null, @event) {
	if(@event['location']['world'] !== 'outworld' || !string_ends_with(@event['item']['name'], '_SAPLING')) {
		die();
	}

	@block = get_block(location_shift(@event['location'], 'down'));
	if(@block == 'GRASS_BLOCK' || @block == 'DIRT') {
		set_block(@event['location'], @event['item']['name']);
	}
}
