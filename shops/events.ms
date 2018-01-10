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
	if(!is_cancelled() && sk_can_build(@event['location'])) {
		include('core.library/shop.ms');
		if(@shop = _get_shop(@event['location'])) {
			_remove_cached_shop(@shop, @event['location']);
		}
	}
}

// Shop Protections
bind(block_place, null, array('name': 'HOPPER'), @event) {
	include('core.library/shop.ms');
	@loc = _relative(@event['location'], 'up');
	@type = split(':', get_block_at(@loc))[0];
	if(@type === '54' || @type === '146') {
		@signs = array();
		if(split(':', get_block_at(_relative(@loc, 'up')))[0] === '68') {
			@signs[0] = _relative(@loc, 'up');
		}
		if(get_inventory_size(@loc) == 54) {
			foreach(@dir in array('north', 'south', 'east', 'west')) {
				@rel = _relative(@loc, @dir);
				if(split(':', get_block_at(@rel))[0] == @type) {
					if(split(':', get_block_at(_relative(@rel, 'up')))[0] === '68') {
						@signs[1] = _relative(@rel, 'up');
					}
					break();
				}
			}
		}

		if(@signs) {
			foreach(@sign in @signs) {
				if((@shop = _get_shop(@sign)) && !_is_shop_owner(player(), @shop['owner'])) {
					cancel();
					die(color('red').'[Shop] You cannot place a hopper below a shop you don\'t own.');
				}
			}
		}
	}
}

bind(player_interact, array('priority': 'LOWEST'), array(block: 54, button: 'right'), @event) {
	if(!is_cancelled() && sk_can_build(@event['location'])) {
		include('core.library/shop.ms');
		if(@shop = _get_shop(_relative(@event['location'], 'up'))) {
			if(!_is_shop_owner(player(), @shop['owner'])) {
				cancel();
				msg(color('red').'[Shop] You do not own this shop.');
			}
		}
	}
}

bind(player_interact, array('priority': 'LOWEST'), array(block: 146, button: 'right'), @event) {
	if(!is_cancelled() && sk_can_build(@event['location'])) {
		include('core.library/shop.ms');
		if(@shop = _get_shop(_relative(@event['location'], 'up'))) {
			if(!_is_shop_owner(player(), @shop['owner'])) {
				cancel();
				msg(color('red').'[Shop] You do not own this shop.');
			}
		}
	}
}

/*
# Protect breaking shop signs and chests
bind(block_break, null, null, @event) {
	@type = get_block_at(@event[location])[0]
	switch(@type) {
		case 54:
		case 146:


		case 68:


		default:
			if(material_info(@type)[isSolid]) {

			}
	}
}

# Explosion protection for chests
bind(entity_explode, null, null, @event) {
	foreach(@block in @event[blocks]) {
		@type = split(':', get_block_at(@block))[0]
		if(@type == 54 || @type == 146) {

		} else if(@type == 68) {

		}
	}
}

# Piston protection
bind(piston_retract, null, null, @event) {

}

bind(piston_extend, null, null, @event) {

}
*/
