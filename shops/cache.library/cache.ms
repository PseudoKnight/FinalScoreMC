proc _cache_shop(@shop) {
	if(!@shop['item']) {
		return();
	}
	@location = @shop['loc'];
	@item = @shop['item'];
	@shops = get_value('shops', @item);
	if(!@shops) {
		@shops = array(array(), array());
	}

	@location = array(
		integer(@location['x']),
		integer(@location['y']),
		integer(@location['z']),
		@location['world'],
	);
	
	@chestLoc = location_shift(@location, 'down');
	array @chestInv;
	try {
		@chestInv = get_inventory(@chestLoc);
	} catch(IllegalArgumentException @ex) {
		die(color('red').'This shop does not have a chest.');
	}
	
	if(@shop['buy']) {
		@count = _chest_item_count(@chestInv, @item);
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
					@msg = color('gold').'[OUT OF STOCK] '.color('r')._item_display(@item).color(7)
						.' @ '.@location[0].','.@location[1].','.@location[2].' '._world_name(@location[3]);
					if(ponline(@shop['owner'])) {
						tmsg(@shop['owner'], @msg);
					} else {
						@pdata = _pdata(@shop['owner']);
						if(!array_index_exists(@pdata, 'mail')) {
							 @pdata['mail'] = array();
						}
						@pdata['mail'][] = array(
							simple_date('MMM d h:mm a', time(), 'US/Central'),
							player(),
							@msg,
						);
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
		@currency = _item_get_currency(@shop['sell'][4]);
		@count = _chest_item_count(@chestInv, @currency);
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
						.' @ '.@location[0].','.@location[1].','.@location[2].' '._world_name(@location[3]);
					if(ponline(@shop['owner'])) {
						tmsg(@shop['owner'], @msg);
					} else {
						@pdata = _pdata(@shop['owner']);
						if(!array_index_exists(@pdata, 'mail')) {
							 @pdata['mail'] = array();
						}
						@pdata['mail'][] = array(
							simple_date('MMM d h:mm a', time(), 'US/Central'),
							player(),
							@msg,
						);
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
		clear_value('shops', @item);
	} else {
		store_value('shops', @item, @shops);
	}
}

proc _remove_cached_shop(@shop) {
	if(!@shop['item']) {
		return();
	}
	@location = @shop['loc'];
	@item = @shop['item'];
	@shops = get_value('shops', @item);
	if(!@shops) {
		return();
	}
	
	@location = array(
		integer(@location['x']),
		integer(@location['y']),
		integer(@location['z']),
		@location['world'],
	);

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
		clear_value('shops', @item);
	} else {
		store_value('shops', @item, @shops);
	}
}
