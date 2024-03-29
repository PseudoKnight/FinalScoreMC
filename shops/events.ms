// Shop Sign Interaction
bind('player_interact', null, array(hand: 'main_hand'), @event) {
	if(!@event['block'] || !string_ends_with(@event['block'], 'WALL_SIGN')) {
		die();
	}
	@signLoc = @event['location'];
	include_dir('core.library');
	if(@shop = _sign_get_shop(@signLoc)) {
		if(!@shop['item']) {
			// handle null items
			die('Cannot determine the item type for this shop.');
		}

		if(@event['button'] == 'left') {
			_shop_show_info(@shop);
		} else if(!_is_shop_owner(@shop)) {
			cancel();
			_shop_process_transaction(@shop);
		}

		// cache current stock
		if(_is_survival_world(@signLoc['world'])) {
			set_timeout(50, closure(){ // do this after a transaction
				include_dir('cache.library');
				_cache_shop(@shop);
			});
		}
	}
}

// Shop Sign Break
bind('block_break', array('priority': 'LOWEST'), null, @event) {
	if(sk_can_build(@event['location']) && string_ends_with(@event['block'], 'WALL_SIGN')) {
		include_dir('core.library');
		if(@shop = _sign_get_shop(@event['location'])) {
			if(_is_shop_owner(@shop) || has_permission('shop.admin')) {
				if(_is_survival_world(@shop['loc']['world'])) {
					include_dir('cache.library');
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
		include_dir('core.library');
		if(@shop = _sign_get_shop(location_shift(@event['location'], 'up'))) {
			if(_is_shop_owner(@shop) || has_permission('shop.admin')) {
				if(_is_survival_world(@shop['loc']['world'])) {
					include_dir('cache.library');
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
		include_dir('core.library');
		if(@shop = _sign_get_shop(location_shift(@event['location'], 'up'))) {
			if(_is_shop_owner(@shop) || has_permission('shop.admin')) {
				if(_is_survival_world(@shop['loc']['world'])) {
					include_dir('cache.library');
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
			if(string_ends_with(get_block(@signLoc), 'WALL_SIGN')) {
				include_dir('core.library');
				if(@shop = _sign_get_shop(@signLoc)) {
					if(!_is_shop_owner(@shop) && !has_permission('shop.admin')) {
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
				if(string_ends_with(get_block(@signLoc), 'WALL_SIGN')) {
					include_dir('core.library');
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
				if(string_ends_with(get_block(@signLoc), 'WALL_SIGN')) {
					include_dir('core.library');
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
		include_dir('core.library');
		if(@shop = _sign_get_shop(location_shift(@event['location'], 'up'))) {
			if(!_is_shop_owner(@shop) && !has_permission('shop.admin')) {
				cancel();
				msg(color('red').'[Shop] You do not own this shop.');
			}
		}
	}
}

bind('player_interact', array('priority': 'LOWEST'), array('block': 'TRAPPED_CHEST', 'button': 'right'), @event) {
	if(sk_can_build(@event['location'])) {
		include_dir('core.library');
		if(@shop = _sign_get_shop(location_shift(@event['location'], 'up'))) {
			if(!_is_shop_owner(@shop) && !has_permission('shop.admin')) {
				cancel();
				msg(color('red').'[Shop] You do not own this shop.');
			}
		}
	}
}
