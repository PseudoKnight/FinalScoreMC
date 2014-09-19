include('includes.library/shops.ms')

# CLICKING SIGNS!
bind(player_interact, null, array(block: 68), @event) {
	if(@shop = _get_shop(@event[location])) {
		queue_push(closure(){
			@shops = get_value('shop', @shop[key])
			if(!@shops, @shops = array(array(), array()))
			@location = array(round(@event[location][0]), round(@event[location][1]), round(@event[location][2]), @event[location][3])
			if(@shop[buy]) {
				@count = _get_inventory_count(_relative(@event[location], 'down'), @shop[item])
				if(is_null(@count), return())
				foreach(@i in array_keys(@shops[0])) {
					if(@shops[0][@i][location][0] == @location[0]
					&& @shops[0][@i][location][1] == @location[1]
					&& @shops[0][@i][location][2] == @location[2]
					&& @shops[0][@i][location][3] == @location[3]) {
						if(@count < @shop[buy][2]) {
							array_remove(@shops[0], @i)
						} else {
							@shops[0][@i] = array(location: @location, price: @shop[buy][1], owner: @shop[owner], stock: @count)
						}
						break()
					}
					if(@i == array_size(@shops[0]) - 1
					&& @count >= @shop[buy][2]) {
						@shops[0][] = array(location: @location, price: @shop[buy][1], owner: @shop[owner], stock: @count)
					}
				} else {
					if(@count >= @shop[buy][2]) {
						@shops[0] = array(array(location: @location, price: @shop[buy][1], owner: @shop[owner], stock: @count))
					}
				}
			}

			if(@shop[sell]) {
				switch(@shop[sell][4]) {
				case 'g':
					@currency = '266'
				case 'i':
					@currency = '265'
				case 'd':
					@currency = '264'
				case 'e':
					@currency = '388'
				default:
					die()
				}
				@count = _get_inventory_count(_relative(@event[location], 'down'), @currency.':0')
				if(is_null(@count), return())
				foreach(@i in array_keys(@shops[1])) {
					if(@shops[1][@i][location][0] == @location[0]
					&& @shops[1][@i][location][1] == @location[1]
					&& @shops[1][@i][location][2] == @location[2]
					&& @shops[1][@i][location][3] == @location[3]) {
						if(@count < @shop[sell][3]) {
							array_remove(@shops[1], @i)
						} else {
							@shops[1][@i] = array(location: @location, price: @shop[sell][1], owner: @shop[owner], stock: @count)
						}
						break()
					}
					if(@i == array_size(@shops[1]) - 1
					&& @count >= @shop[sell][3]) {
						@shops[1][] = array(location: @location, price: @shop[sell][1], owner: @shop[owner], stock: @count)
					}
				} else {
					if(@count >= @shop[sell][3]) {
						@shops[1] = array(array(location: @location, price: @shop[sell][1], owner: @shop[owner], stock: @count))
					}
				}
			}

			if(@shops == array(array(), array())) {
				clear_value('shop', @shop[key])
			} else {
				store_value('shop', @shop[key], @shops)
			}
		})
	}
}

# Breaking signs
bind(block_break, null, array(type: 68), @event) {
	if(@shop = _get_shop(@event[location])) {
		@shops = get_value('shop', @shop[key])
		if(!@shops, die())
		@location = array(round(@event[location][0]), round(@event[location][1]), round(@event[location][2]), @event[location][3])
		if(@shop[buy] && @shops[0]) {
			for(@i = 0, @i < length(@shops[0]), @i++) {
				if(@shops[0][@i][location][0] == @location[0]
				&& @shops[0][@i][location][1] == @location[1]
				&& @shops[0][@i][location][2] == @location[2]
				&& @shops[0][@i][location][3] == @location[3] 
				&& (_is_shop_owner(player(), @shop[owner]) || has_permission('shop.admin'))) {
					array_remove(@shops[0], @i)
					break()
				}
			}
		}
		if(@shop[sell] && @shops[1]) {
			for(@i = 0, @i < length(@shops[1]), @i++) {
				if(@shops[1][@i][location][0] == @location[0]
				&& @shops[1][@i][location][1] == @location[1]
				&& @shops[1][@i][location][2] == @location[2]
				&& @shops[1][@i][location][3] == @location[3] 
				&& (_is_shop_owner(player(), @shop[owner]) || has_permission('shop.admin'))) {
					array_remove(@shops[1], @i)
					break()
				}
			}
		}
		if(@shops == array(array(), array())) {
			clear_value('shop', @shop[key])
		} else {
			store_value('shop', @shop[key], @shops)
		}
	}
}