// Features from 1.15.
// These will be removed once 1.15 comes out.
bind('player_interact', null, array('button': 'right', 'block': 'CAMPFIRE'), @event) {
	@item = pinv(player(), null);
	if(is_null(@item) || !string_ends_with(@item['name'], '_SHOVEL')) {
		die();
	}
	
	@location = @event['location'];
	if(!sk_can_build(@location)) {
		die('You are not allowed to snuff this.');
	}

	@campfire = get_blockdata(@location);
	if(!@campfire['lit']) {
		die();
	}
	@campfire['lit'] = false;
	set_blockdata(@location, @campfire);

	// effects
	@location['x'] += 0.5;
	@location['y'] += 0.5;
	@location['z'] += 0.5;
	spawn_particle(@location, 'SMOKE_NORMAL');
	play_sound(@location, array('sound': 'ENTITY_GENERIC_EXTINGUISH_FIRE', 'category': 'BLOCKS', 'pitch': 2, 'volume': 0.3));
	pswing_hand();
	
	// shovel damage
	@unbreaking = 0;
	if(@item['meta'] && array_index_exists(@item['meta']['enchants'], 'unbreaking')) {
		@unbreaking = @item['meta']['enchants']['unbreaking']['elevel'];
	}
	
	if(1 / (@unbreaking + 1) > rand()) {
		if(!@item['meta']) {
			@item['meta'] = array('damage': 1);
		} else {
			@item['meta']['damage'] += 1;
		}
		if(@item['meta']['damage'] > material_info(@item['name'], 'maxDurability')) {
			set_pinv(player(), null, null);
			play_sound(ploc(), array('sound': 'ENTITY_ITEM_BREAK', 'category': 'PLAYERS'));
		} else {
			set_pinv(player(), null, @item);
		}
	}
}
