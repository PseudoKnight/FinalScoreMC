bind(player_interact, null, array('item': 401, 'button': 'right'), @event) {
	if(pworld() !== 'custom'
	|| pinfo(player(), 6) != @event['item']) {
		die();
	}
	@pdata = _pdata(player());
	if(!array_index_exists(@pdata, 'support')) {
		die();
	}
	cancel();
	if(@event['action'] === 'right_click_block') {
		@loc = _relative(@event['location'], @event['facing']);
	} else {
		@loc = ploc();
	}
	@loc['x'] += 0.5;
	@loc['z'] += 0.5;

	@colors = array();
	for(@i = 0, @i < 3, @i++) {
		@colors[] = array(rand(256), rand(256), rand(256));
	}

	foreach(@f in range(rand(1, 4))) {
		@meta = associative_array('strength': @f, 'effects': array());
		foreach(@m in range(rand(1, 3))) {
			@type = array_rand(array('BALL', 'BALL_LARGE', 'STAR', 'BURST', 'CREEPER'), 1, false)[0];
			@startcolors = array_rand(@colors, rand(1, 3), false);
			@endcolors = array_filter(@colors, closure(@key, @value){
				return(!array_contains(@startcolors, @value));
			});
			@meta['effects'][] = associative_array(
				'flicker': rand(2),
				'trail': rand(2),
				'colors': @startcolors,
				'fade': @endcolors,
				'type': @type,
			);
		}
		launch_firework(@loc, @meta);
	}

	@slot = pinfo(player(), 15);
	@item = pinv(player(), @slot);
	@item['type'] = 402;
	@item['name'] = 'FIREWORK_CHARGE';
	set_pinv(player(), array(null: @item));
	set_timeout(5000, closure(){
		try {
			@item = pinv(player(), @slot);
			if(@item && @item['type'] == 402) {
				@item['type'] = 401;
				@item['name'] = 'FIREWORK';
				@inv = associative_array();
				@inv[@slot] = @item;
				set_pinv(player(), @inv);
			}
		} catch(PlayerOfflineException @ex) {
			// ignore
		}
	});
}
