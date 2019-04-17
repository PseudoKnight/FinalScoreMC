# An alternate function for pickaxes
# Smooths certain block types:

bind('player_interact', null, array('button': 'right'), @event) {
	@item = pinv(player(), null);
	if(is_null(@item) || (@item['name'] != 'DIAMOND_PICKAXE' && @item['name'] != 'IRON_PICKAXE')) {
		die();
	}

	@block = @event['block']
	if(@block != 'SANDSTONE_SLAB' && @block != 'QUARTZ_SLAB' && @block != 'STONE_SLAB' && @block != 'RED_SANDSTONE_SLAB') {
		die();
	}

	@type = split('_', @event['block'])[0];
	if(@type == 'RED') {
		@type = 'RED_SANDSTONE';
	}

	@location = @event['location'];
	if(!sk_can_build(@location)) {
		die('You are not allowed to chisel this.');
	}

	@match = reg_match('type\\=([a-z]+)', get_blockdata_string(@location));
	if(!@match || @match[1] != 'double') {
		die();
	}
	set_block(@location, 'SMOOTH_'.@type);
	@location['x'] += 0.5;
	@location['y'] += 0.5;
	@location['z'] += 0.5;
	spawn_particle(@location, array(
		'particle': 'BLOCK_CRACK',
		'block': @event['block'],
		'count': 25,
		'xoffset': 1.2,
		'yoffset': 1.2,
		'zoffset': 1.2,
	));
	play_sound(@location, array('sound': 'BLOCK_STONE_BREAK', 'category': 'BLOCKS'));
	pswing_hand();

	@unbreaking = 0;
	if(@item['meta']) {
		if(array_index_exists(@item['meta']['enchants'], 'unbreaking')) {
			@unbreaking = @item['meta']['enchants']['unbreaking']['elevel'];
		}
	} else {
		@item['meta'] = associative_array('damage': 0);
	}

	if(1 / (@unbreaking + 1) > rand()) {
		@item['meta']['damage'] += 1;
		@maxDamage = 1561; # diamond pickaxe
		if(@item['name'] == 'IRON_PICKAXE') {
				@maxDamage = 250;
		}
		if(@item['meta']['damage'] > @maxDamage) {
			set_pinv(player(), null, null);
			play_sound(ploc(), array('sound': 'ENTITY_ITEM_BREAK', 'category': 'PLAYERS'));
		} else {
			set_pinv(player(), null, @item);
		}
	}
}
