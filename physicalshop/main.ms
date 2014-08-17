####################
# SIGN CHEST SHOPS #
####################

# CLICKING SIGNS!
bind(player_interact, null, array('block': 68), @event) {
	@signtext = get_sign_text(@event['location'])
	if(length(@signtext[0]) > 2 && @signtext[0][0] == '['
	&& (length(@signtext[1]) > 7 && substr(@signtext[1], 0, 3) == 'Buy'
	|| length(@signtext[2]) > 8 && substr(@signtext[2], 0, 4) == 'Sell')) {
		set_timeout(50, closure(){
			include('includes.library/shops.ms')
			@itemid = _shop_item(@signtext[0])
			@shops = get_value('shop', @itemid)
			if(!@shops, @shops = array(array(), array()))
			@signloc = array(round(@event['location'][0]), round(@event['location'][1]), round(@event['location'][2]), @event['location'][3])
			if(length(@signtext[1]) > 7 && substr(@signtext[1], 0, 3) == 'Buy') {
				@count = _get_inventory_count(_relative(@event['location'], 'down'), reg_replace('\\.', ':', @itemid))
				if(!is_array(@shops[0]), console('This shop list is not an array: '.@shops))
				foreachelse(@i in array_keys(@shops[0])) {
					if(@shops[0][@i]['location'][0] == @signloc[0]
					&& @shops[0][@i]['location'][1] == @signloc[1]
					&& @shops[0][@i]['location'][2] == @signloc[2]
					&& @shops[0][@i]['location'][3] == @signloc[3]) {
						if(@count < parse_args(@signtext[1])[1]) {
							array_remove(@shops[0], @i)
						} else {
							@shops[0][@i] = array('location': @signloc, 'price': substr(@signtext[1], 4), 'owner': @signtext[3], 'stock': @count)
						}
						break()
					}
					if(@i == (length(@shops[0]) - 1)
					&& @count >= parse_args(@signtext[1])[1]) {
						@shops[0][] = array('location': @signloc, 'price': substr(@signtext[1], 4), 'owner': @signtext[3], 'stock': @count)
					}
				} else {
					if(@count >= parse_args(@signtext[1])[1]) {
						@shops[0] = array(array('location': @signloc, 'price': substr(@signtext[1], 4), 'owner': @signtext[3], 'stock': @count))
					}
				}
			}

			if(length(@signtext[2]) > 8 && substr(@signtext[2], 0, 4) == 'Sell') {
				switch(substr(@signtext[2], length(@signtext[2]) - 1)) {
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
				@count = _get_inventory_count(_relative(@event['location'], 'down'), @currency.':0')
				try(@cost = parse_args(@signtext[2])[3],
					console('"Sell" line is incorrect at '.@signloc)
					die()
				)
				try(
				foreachelse(@i in array_keys(@shops[1])) {
					if(@shops[1][@i]['location'][0] == @signloc[0]
					&& @shops[1][@i]['location'][1] == @signloc[1]
					&& @shops[1][@i]['location'][2] == @signloc[2]
					&& @shops[1][@i]['location'][3] == @signloc[3]) {
						if(@count < substr(@cost, 0, length(@cost) - 1)) {
							array_remove(@shops[1], @i)
						} else {
							@shops[1][@i] = array('location': @signloc, 'price': substr(@signtext[2], 5), 'owner': @signtext[3], 'stock': @count)
						}
						break()
					}
					if(@i == (length(@shops[1]) - 1)
					&& @count >= substr(@cost, 0, length(@cost) - 1)) {
						@shops[1][] = array('location': @signloc, 'price': substr(@signtext[2], 5), 'owner': @signtext[3], 'stock': @count)
					}
				} else {
					if(@count >= substr(@cost, 0, length(@cost) - 1)) {
						@shops[1] = array(array('location': @signloc, 'price': substr(@signtext[2], 5), 'owner': @signtext[3], 'stock': @count))
					}
				}
				, #catch
					console('Shop debug: '.@shops)
				)
			}

			if(@shops == array(array(), array())) {
				clear_value('shop', @itemid)
			} else {
				store_value('shop', @itemid, @shops)
			}

		})
	}
}

# Breaking signs
bind(block_break, null, array('type': 68), @event) {
	@location = array(round(@event['location'][0]), round(@event['location'][1]), round(@event['location'][2]), @event['location'][3])
	@signtext = get_sign_text(@location)
	if(length(@signtext[0]) < 3 || @signtext[0][0] != '[', die())
	if(!(length(@signtext[1]) > 7 && substr(@signtext[1], 0, 3) == 'Buy')
	&& !(length(@signtext[2]) > 8 && substr(@signtext[2], 0, 4) == 'Sell'), die())
	include('includes.library/shops.ms')
	@itemid = _shop_item(@signtext[0])
	@shops = get_value('shop', @itemid)
	if(!@shops, die())
	if(length(@signtext[1]) > 7 
	&& substr(@signtext[1], 0, 3) == 'Buy'
	&& @shops[0]) {
		for(@i = 0, @i < length(@shops[0]), @i++) {
			if(@shops[0][@i]['location'][0] == @location[0]
			&& @shops[0][@i]['location'][1] == @location[1]
			&& @shops[0][@i]['location'][2] == @location[2]
			&& @shops[0][@i]['location'][3] == @location[3] 
			&& (@shops[0][@i]['owner'] == player() || has_permission('group.moderators'))) {
				array_remove(@shops[0], @i)
				break()
			}
		}
	}
	if(length(@signtext[2]) > 8 
	&& substr(@signtext[2], 0, 4) == 'Sell'
    && @shops[1]) {
		for(@i = 0, @i < length(@shops[1]), @i++) {
			if(@shops[1][@i]['location'][0] == @location[0]
			&& @shops[1][@i]['location'][1] == @location[1]
			&& @shops[1][@i]['location'][2] == @location[2]
			&& @shops[1][@i]['location'][3] == @location[3] 
			&& (@shops[1][@i]['owner'] == player() || has_permission('group.moderators'))) {
				array_remove(@shops[1], @i)
				break()
			}
		}
    }
	if(@shops == array(array(), array())) {
		clear_value('shop', @itemid)
	} else {
		store_value('shop', @itemid, @shops)
	}
}

#prevent hoppers under shop chests
bind(block_place, null, array('type': 154), @event) {
	@loc = _relative(@event['location'], 'up')
	@type = split(':', get_block_at(@loc))[0]
	if(@type == '54' || @type == '146') {
		if(split(':', get_block_at(_relative(@loc, 'up')))[0] == '68') {
			@signs[0] = _relative(@loc, 'up')
		}
		if(get_inventory_size(@loc) == 54) {
			foreach(@dir in array('north', 'south', 'east', 'west')) {
				@rel = _relative(@loc, @dir)
				if(split(':', get_block_at(@rel))[0] == @type) {
					if(split(':', get_block_at(_relative(@rel, 'up')))[0] == '68') {
						@signs[1] = _relative(@rel, 'up')
					}
					break()
				}
			}
		}
    
		if(@signs) {
			include('includes.library/shops.ms')
			foreach(@sign in @signs) {
				if(_is_shop(@sign) && !_is_shop_owner(@sign)) {
					cancel()
					die(color('red').'You cannot place a hopper below a shop you don\'t own.')
				}
			}
		}
	}
}