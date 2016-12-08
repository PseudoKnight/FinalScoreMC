# An alternate function for axes
# Creates six-sided bark on logs:
# 17:0 -> 17:12 - six-side oak log
# 162:0 -> 162:12 - six-side acacia log

proc _axe_carve(@event) {
	@block = split(':', @event['block']);
    @type = @block[0];
	@data = array_get(@block, 1, 0);
	if(@data > 7) {
		die();
	}
	
	@item = pinv(player(), null);
	if(is_null(@item) || !array_contains(array(
		'DIAMOND_AXE',
		'IRON_AXE',
		'STONE_AXE',
		'WOOD_AXE',
	), @item['name'])) {
		die();
	}
	
	if(!sk_can_build(@event['location'])) {
		die('You are not allowed to carve this.');
	}
		
	set_block_at(@event['location'], @type.':'.(@data + 12));
	@event['location']['x'] += 0.5;
	@event['location']['y'] += 0.5;
	@event['location']['z'] += 0.5;
	play_effect(@event['location'], 'TILE_BREAK', array(
		'id': @type,
		'data': @data,
		'particleCount': 20,
		'offsetX': 0.3,
		'offsetY': 0.3,
		'offsetZ': 0.3,
	));
	play_sound(@event['location'], array('sound': 'DIG_WOOD'));
	
	@unbreaking = 0;
	@enchants = @item['enchants'];
	foreach(@enchant in @enchants) {
		if(@enchant['etype'] === 'DURABILITY') {
			@unbreaking = @enchant['elevel'];
		}
	}
	
	if(1 / (@unbreaking + 1) > rand()) {
		@item['data'] += 1;
		@maxDamage = 1561; # diamond axe
		switch(@item['name']) {
			case 'IRON_AXE':
				@maxDamage = 250;
			case 'STONE_AXE':
				@maxDamage = 131;
			case 'WOOD_AXE':
				@maxDamage = 59;
		}
		if(@item['data'] > @maxDamage) {
			set_pinv(player(), array(null: null));
			play_sound(ploc(), array('sound': 'ITEM_BREAK'));
		} else {
			set_pinv(player(), array(null: @item));
		}
	}
}

bind(player_interact, null, array('button': 'right', 'block': 17), @event) {
	_axe_carve(@event);
}

bind(player_interact, null, array('button': 'right', 'block': 162), @event) {
	_axe_carve(@event);
}
