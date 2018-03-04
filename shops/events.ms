// Shop Sign Interaction
bind(player_interact, null, array('block': 68), @event) {
	include('core.library/sign.ms');
	if(@shop = _sign_get_shop(@event['location'])) {
		// cache current stock
		if(@event['location']['world'] != 'shard') {
			set_timeout(50, closure(){ // do this after a transaction
				include('core.library/cache.ms');
				_cache_shop(@shop, @event['location']);
			});
		}
	}
}

// Shop Sign Break
bind(block_break, array('priority': 'LOWEST'), array('name': 'WALL_SIGN'), @event) {
	if(sk_can_build(@event['location'])) {
		include('core.library/sign.ms');
		if(@shop = _sign_get_shop(@event['location'])) {
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
			@signLoc = location_shift(@loc, 'up');
			if(split(':', get_block_at(@signLoc))[0] == '68') {
				include('core.library/sign.ms');
				if((@shop = _sign_get_shop(@signLoc)) && !_is_shop_owner(player(), @shop['owner'])) {
					cancel();
					msg(color('red').'[Shop] You cannot place a hopper below a shop you don\'t own.');
				}
			}
		}
	}
}

bind(player_interact, array('priority': 'LOWEST'), array('block': 54, 'button': 'right'), @event) {
	if(sk_can_build(@event['location'])) {
		include('core.library/sign.ms');
		if(@shop = _sign_get_shop(location_shift(@event['location'], 'up'))) {
			if(!_is_shop_owner(player(), @shop['owner'])) {
				cancel();
				msg(color('red').'[Shop] You do not own this shop.');
			}
		}
	}
}

bind(player_interact, array('priority': 'LOWEST'), array('block': 146, 'button': 'right'), @event) {
	if(sk_can_build(@event['location'])) {
		include('core.library/sign.ms');
		if(@shop = _sign_get_shop(location_shift(@event['location'], 'up'))) {
			if(!_is_shop_owner(player(), @shop['owner'])) {
				cancel();
				msg(color('red').'[Shop] You do not own this shop.');
			}
		}
	}
}
