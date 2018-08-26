# An alternate function for pickaxes
# Smooths certain block types:

bind('player_interact', null, array('button': 'right'), @event) {
	@item = pinv(player(), null);
	if(is_null(@item) || (@item['name'] != 'DIAMOND_PICKAXE' && @item['name'] != 'IRON_PICKAXE')) {
		die();
	}
	
	if(@event['block'] != 'SANDSTONE_SLAB' && @event['block'] != 'QUARTZ_SLAB' && @event['block'] != 'STONE_SLAB') {
		die();
	}
	@type = split('_', @event['block'])[0];
	
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
			@unbreaking = @item['meta']['enchants']['unbreaking'];
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
