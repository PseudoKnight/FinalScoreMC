# An alternate function for pickaxes
# Smooths certain block types:
# 43:0 -> 43:8 - Smooth Stone Double Slab
# 43:1 -> 43:9 - Smooth Sandstone Double Slab

proc _chisel(@location, @id) {
	@block = split(':', @id);
	@data = array_get(@block, 1, 0);
	if(@data > 7) {
		die();
	}
	
	@item = pinv(player(), null);
	if(is_null(@item) || !array_contains(array(
		'DIAMOND_PICKAXE',
		'IRON_PICKAXE',
		'STONE_PICKAXE',
		'WOOD_PICKAXE',
	), @item['name'])) {
		die();
	}
	
	if(!sk_can_build(@location)) {
		die('You are not allowed to chisel this.');
	}
		
	set_block_at(@location, @block[0].':'.(@data + 8));
	@location['x'] += 0.5;
	@location['y'] += 0.5;
	@location['z'] += 0.5;
	play_effect(@location, 'TILE_BREAK', array(
		'id': @block[0],
		'data': @data,
		'particleCount': 20,
		'offsetX': 0.3,
		'offsetY': 0.3,
		'offsetZ': 0.3,
	));
	play_sound(@location, array('sound': 'DIG_STONE', 'category': 'BLOCKS'));
	pswing_hand();
	
	@unbreaking = 0;
	@enchants = @item['enchants'];
	foreach(@enchant in @enchants) {
		if(@enchant['etype'] === 'DURABILITY') {
			@unbreaking = @enchant['elevel'];
			break();
		}
	}
	
	if(1 / (@unbreaking + 1) > rand()) {
		@item['data'] += 1;
		@maxDamage = 1561; # diamond pickaxe
		switch(@item['name']) {
			case 'IRON_PICKAXE':
				@maxDamage = 250;
			case 'STONE_PICKAXE':
				@maxDamage = 131;
			case 'WOOD_PICKAXE':
				@maxDamage = 59;
		}
		if(@item['data'] > @maxDamage) {
			set_pinv(player(), null, null);
			play_sound(ploc(), array('sound': 'ITEM_BREAK', 'category': 'PLAYERS'));
		} else {
			set_pinv(player(), null, @item);
		}
	}
}

bind('player_interact', null, array('button': 'right', 'block': 43), @event) {
	_chisel(@event['location'], @event['block']);
}

bind('player_interact', null, array('button': 'right', 'block': 181), @event) {
	_chisel(@event['location'], @event['block']);
}
