// Shop Sign Interaction
bind('player_interact', null, array('block': 'WALL_SIGN'), @event) {
	@signLoc = @event['location'];
	include('core.library/shop.ms');
	if(@shop = _sign_get_shop(@signLoc)) {
		if(!@shop['item']) {
			// handle null items
			die('Cannot determine the item type for this shop.');
		}
		cancel();
		if(@event['button'] == 'left') {
			_shop_show_info(@shop);
		} else {
			_shop_process_transaction(@shop);
		}

		// cache current stock
		if(_is_survival_world(@signLoc['world'])) {
			set_timeout(50, closure(){ // do this after a transaction
				include('core.library/cache.ms');
				_cache_shop(@shop);
			});
		}
	}
}

// Shop Sign Break
bind('block_break', array('priority': 'LOWEST'), array('block': 'WALL_SIGN'), @event) {
	if(sk_can_build(@event['location'])) {
		include('core.library/shop.ms');
		if(@shop = _sign_get_shop(@event['location'])) {
			if(_is_shop_owner(@shop)) {
				if(_is_survival_world(@shop['world'])) {
					include('core.library/cache.ms');
					_remove_cached_shop(@shop);
				}
			} else {
				cancel();
				msg(color('red').'[Shop] You do not own this shop.');
			}
		}
	}
}

// Chest Protections
bind('block_break', array('priority': 'LOWEST'), array('block': 'CHEST'), @event) {
	if(sk_can_build(@event['location'])) {
		include('core.library/shop.ms');
		if(@shop = _sign_get_shop(location_shift(@event['location'], 'up'))) {
			if(_is_shop_owner(@shop) || pisop()) {
				if(_is_survival_world(@shop['world'])) {
					include('core.library/cache.ms');
					_remove_cached_shop(@shop);
				}
			} else {
				cancel();
				msg(color('red').'[Shop] You do not own this shop.');
			}
		}
	}
}

bind('block_break', array('priority': 'LOWEST'), array('block': 'TRAPPED_CHEST'), @event) {
	if(sk_can_build(@event['location'])) {
		include('core.library/shop.ms');
		if(@shop = _sign_get_shop(location_shift(@event['location'], 'up'))) {
			if(_is_shop_owner(@shop) || pisop()) {
				if(_is_survival_world(@shop['world'])) {
					include('core.library/cache.ms');
					_remove_cached_shop(@shop);
				}
			} else {
				cancel();
				msg(color('red').'[Shop] You do not own this shop.');
			}
		}
	}
}

bind('block_place', null, array('block': 'HOPPER'), @event) {
	if(sk_can_build(@event['location'])) {
		@loc = location_shift(@event['location'], 'up');
		@type = get_block(@loc);
		if(@type === 'CHEST' || @type === 'TRAPPED_CHEST') {
			@signLoc = location_shift(@loc, 'up');
			if(get_block(@signLoc) == 'WALL_SIGN') {
				include('core.library/shop.ms');
				if(@shop = _sign_get_shop(@signLoc)) {
					if(!_is_shop_owner(@shop)) {
						cancel();
						msg(color('red').'[Shop] You cannot place a hopper below a shop you don\'t own.');
					}
				}
			}
		}
	}
}

bind('block_place', null, array('block': 'CHEST'), @event) {
	if(!psneaking() && sk_can_build(@event['location'])) {
		foreach(@dir in array('south', 'north', 'east', 'west')) {
			@loc = location_shift(@event['location'], @dir);
			if(get_block(@loc) == @event['block']) {
				@signLoc = location_shift(@loc, 'up');
				if(get_block(@signLoc) == 'WALL_SIGN') {
					include('core.library/shop.ms');
					if(_sign_get_shop(@signLoc)) {
						cancel();
						die(color('red').'[Shop] You cannot connect a chest to a shop.');
					}
				}
			}
		}
	}
}

bind('block_place', null, array('block': 'TRAPPED_CHEST'), @event) {
	if(!psneaking() && sk_can_build(@event['location'])) {
		foreach(@dir in array('south', 'north', 'east', 'west')) {
			@loc = location_shift(@event['location'], @dir);
			if(get_block(@loc) == @event['block']) {
				@signLoc = location_shift(@loc, 'up');
				if(get_block(@signLoc) == 'WALL_SIGN') {
					include('core.library/shop.ms');
					if(_sign_get_shop(@signLoc)) {
						cancel();
						die(color('red').'[Shop] You cannot connect a chest to a shop.');
					}
				}
			}
		}
	}
}

bind('player_interact', array('priority': 'LOWEST'), array('block': 'CHEST', 'button': 'right'), @event) {
	if(sk_can_build(@event['location'])) {
		include('core.library/shop.ms');
		if(@shop = _sign_get_shop(location_shift(@event['location'], 'up'))) {
			if(!_is_shop_owner(@shop) && !pisop()) {
				cancel();
				msg(color('red').'[Shop] You do not own this shop.');
			}
		}
	}
}

bind('player_interact', array('priority': 'LOWEST'), array('block': 'TRAPPED_CHEST', 'button': 'right'), @event) {
	if(sk_can_build(@event['location'])) {
		include('core.library/shop.ms');
		if(@shop = _sign_get_shop(location_shift(@event['location'], 'up'))) {
			if(!_is_shop_owner(@shop) && !pisop()) {
				cancel();
				msg(color('red').'[Shop] You do not own this shop.');
			}
		}
	}
}
