proc _cache_shop(@shop, @location) {
	@key = replace(@shop['item'], ':', '.');
	@shops = get_value('shop', @key);
	if(!@shops) {
		@shops = array(array(), array());
	}

	@location = array(
		integer(@location['x']),
		integer(@location['y']),
		integer(@location['z']),
		@location['world'],
	);

	include('chest.ms');
	if(@shop['buy']) {
		@count = _chest_item_count(location_shift(@location, 'down'), @shop['item']);
		if(is_null(@count)) {
			return();
		}

		@found = false;
		foreach(@i: @s in @shops[0]) {
			if(@s['location'][0] == @location[0]
			&& @s['location'][1] == @location[1]
			&& @s['location'][2] == @location[2]
			&& @s['location'][3] == @location[3]) {
				if(@count < @shop['buy'][2]) {
					@msg = color('gold').'[OUT OF STOCK] '.color('r').data_name(@shop['item']).color(7)
						.' @ '.@location[0].','.@location[1].','.@location[2].' '._worldname(@location[3]);
					if(ponline(@shop['owner'])) {
						tmsg(@shop['owner'], @msg);
					} else {
						@pdata = _pdata(@shop['owner']);
						if(!array_index_exists(@pdata, 'mail')) {
							 @pdata['mail'] = array();
						}
						array_push(@pdata['mail'], array(
							simple_date('MMM d h:mm a', time(), 'CST'),
							player(),
							@msg,
						));
						_store_pdata(@shop['owner'], @pdata);
					}
					array_remove(@shops[0], @i);
				} else {
					@shops[0][@i] = array(
						'location': @location,
						'price': @shop['buy'][1],
						'owner': @shop['owner'],
						'stock': @count,
					);
				}
				@found = true;
				break();
			}
		}
		if(!@found && @count >= @shop['buy'][2]) {
			@shops[0][] = array(
				'location': @location,
				'price': @shop['buy'][1],
				'owner': @shop['owner'],
				'stock': @count,
			);
		}
	}

	if(@shop['sell']) {
		switch(@shop['sell'][4]) {
		case 'g':
			@currency = '266';
		case 'i':
			@currency = '265';
		case 'd':
			@currency = '264';
		case 'e':
			@currency = '388';
		default:
			die();
		}

		@count = _chest_item_count(location_shift(@location, 'down'), @currency.':0');
		if(is_null(@count)) {
			return();
		}

		@found = false;
		foreach(@i: @s in @shops[1]) {
			if(@s['location'][0] == @location[0]
			&& @s['location'][1] == @location[1]
			&& @s['location'][2] == @location[2]
			&& @s['location'][3] == @location[3]) {
				if(@count < @shop['sell'][3]) {
					@msg = color('gold').'[OUT OF CURRENCY] '.color('r').data_name(@currency).color(7)
						.' @ '.@location[0].','.@location[1].','.@location[2].' '._worldname(@location[3]);
					if(ponline(@shop['owner'])) {
						tmsg(@shop['owner'], @msg);
					} else {
						@pdata = _pdata(@shop['owner']);
						if(!array_index_exists(@pdata, 'mail')) {
							 @pdata['mail'] = array();
						}
						array_push(@pdata['mail'], array(
							simple_date('MMM d h:mm a', time(), 'CST'),
							player(),
							@msg,
						));
						_store_pdata(@shop['owner'], @pdata);
					}
					array_remove(@shops[1], @i);
				} else {
					@shops[1][@i] = array(
						'location': @location,
						'price': @shop['sell'][1],
						'owner': @shop['owner'],
						'stock': @count,
					);
				}
				@found = true;
				break();
			}
		}
		if(!@found && @count >= @shop['sell'][3]) {
			@shops[1][] = array(
				'location': @location,
				'price': @shop['sell'][1],
				'owner': @shop['owner'],
				'stock': @count,
			);
		}
	}

	if(!@shops[0] && !@shops[1]) {
		clear_value('shop', @key);
	} else {
		store_value('shop', @key, @shops);
	}
}

proc _remove_cached_shop(@shop, @location) {
	@key = replace(@shop['item'], ':', '.');
	@shops = get_value('shop', @key);
	if(!@shops) {
		die();
	}
	
	@location = array(
		integer(@location['x']),
		integer(@location['y']),
		integer(@location['z']),
		@location['world'],
	);
	
	include('shop.ms');
	if(@shop['buy'] && @shops[0]) {
		foreach(@i: @s in @shops[0]) {
			if(@s['location'][0] == @location[0]
			&& @s['location'][1] == @location[1]
			&& @s['location'][2] == @location[2]
			&& @s['location'][3] == @location[3]
			&& (_is_shop_owner(@shop) || has_permission('shop.admin'))) {
				array_remove(@shops[0], @i);
				break();
			}
		}
	}

	if(@shop['sell'] && @shops[1]) {
		foreach(@i: @s in @shops[1]) {
			if(@s['location'][0] == @location[0]
			&& @s['location'][1] == @location[1]
			&& @s['location'][2] == @location[2]
			&& @s['location'][3] == @location[3]
			&& (_is_shop_owner(@shop) || has_permission('shop.admin'))) {
				array_remove(@shops[1], @i);
				break();
			}
		}
	}

	if(!@shops[0] && !@shops[1]) {
		clear_value('shop', @key);
	} else {
		store_value('shop', @key, @shops);
	}
}
