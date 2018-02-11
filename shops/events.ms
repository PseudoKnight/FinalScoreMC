// Shop Sign Interaction
bind(player_interact, null, array('block': 68), @event) {
	include('core.library/shop.ms');
	if(@shop = _get_shop(@event['location'])) {
		if(@event['location']['world'] != 'shard') {
			queue_push(closure(){
				include('core.library/cache.ms');
				_cache_shop(@shop, @event['location']);
			}, 'shop');
		}
	}
}

// Shop Sign Break
bind(block_break, array('priority': 'MONITOR'), array('name': 'WALL_SIGN'), @event) {
	if(sk_can_build(@event['location'])) {
		include('core.library/shop.ms');
		if(@shop = _get_shop(@event['location'])) {
			if(_is_shop_owner(player(), @shop['owner'])) {
				if(@event['location']['world'] != 'shard') {
					include('core.library/cache.ms');
					_remove_cached_shop(@shop, @event['location']);
				}
			} else {
				cancel();
				msg(color('red').'[Shop] You do not own this shop.');
			}
		}
	}
}

// Shop Protections
bind(block_place, null, array('name': 'HOPPER'), @event) {
	if(sk_can_build(@event['location'])) {
		@loc = location_shift(@event['location'], 'up');
		@type = split(':', get_block_at(@loc))[0];
		if(@type === '54' || @type === '146') {
			@signs = array();
			if(split(':', get_block_at(location_shift(@loc, 'up')))[0] === '68') {
				@signs[0] = location_shift(@loc, 'up');
			}
			if(get_inventory_size(@loc) == 54) {
				foreach(@dir in array('north', 'south', 'east', 'west')) {
					@rel = location_shift(@loc, @dir);
					if(split(':', get_block_at(@rel))[0] == @type) {
						if(split(':', get_block_at(location_shift(@rel, 'up')))[0] === '68') {
							@signs[1] = location_shift(@rel, 'up');
						}
						break();
					}
				}
			}

			if(@signs) {
				include('core.library/shop.ms');
				foreach(@sign in @signs) {
					if((@shop = _get_shop(@sign)) && !_is_shop_owner(player(), @shop['owner'])) {
						cancel();
						die(color('red').'[Shop] You cannot place a hopper below a shop you don\'t own.');
					}
				}
			}
		}
	}
}

bind(player_interact, array('priority': 'LOWEST'), array('block': 54, 'button': 'right'), @event) {
	if(sk_can_build(@event['location'])) {
		include('core.library/shop.ms');
		if(@shop = _get_shop(location_shift(@event['location'], 'up'))) {
			if(!_is_shop_owner(player(), @shop['owner'])) {
				cancel();
				msg(color('red').'[Shop] You do not own this shop.');
			}
		}
	}
}

bind(player_interact, array('priority': 'LOWEST'), array('block': 146, 'button': 'right'), @event) {
	if(sk_can_build(@event['location'])) {
		include('core.library/shop.ms');
		if(@shop = _get_shop(location_shift(@event['location'], 'up'))) {
			if(!_is_shop_owner(player(), @shop['owner'])) {
				cancel();
				msg(color('red').'[Shop] You do not own this shop.');
			}
		}
	}
}
