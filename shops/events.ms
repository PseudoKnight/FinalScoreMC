// Shop Sign Interaction
bind('player_interact', null, array('block': 68), @event) {
	@signLoc = @event['location'];
	include('core.library/sign.ms');
	if(@shop = _sign_get_shop(@signLoc)) {
		if(@signLoc['world'] == 'dev') {
			cancel();
			if(@event['button'] == 'left') {
				include('core.library/chest.ms');
				// info
				@chestLoc = location_shift(@signLoc, 'down');
				if(@shop['buy']) {
					@itemCount = _chest_item_count(@chestLoc, @shop['item']);
					if(@itemCount >= @shop['buy'][2]) {
						msg(colorize("&aShop has &l@itemCount&a &l".data_name(@shop['item'])."&a left."));
					} else {
						msg(colorize("&6Shop has insufficient stock of &l".data_name(@shop['item']).'.'));
					}
				}
				if(@shop['sell']) {
					@currency = null;
					switch(@shop['sell'][4]) {
						case 'd':
							@currency = 264; // 'DIAMOND'
						case 'e':
							@currency = 388; // 'EMERALD'
						case 'g':
							@currency = 266; // 'GOLD_INGOT'
						case 'i':
							@currency = 265; // 'IRON_INGOT'
						default:
							throw('FormatException', 'Shop has unhandled currency: '.@shop['sell'][4]);
					}
					@currencyCount = _chest_item_count(@chestLoc, @currency);
					if(@currencyCount >= @shop['sell'][3]) {
						msg(colorize("&aShop has &l@currencyCount&a &l".data_name(@currency)."&a left."));
					} else {
						msg(colorize("&6Shop has insufficient stock of &l".data_name(@currency).'.'));
					}
				}
				
			} else {
				// transaction
				@chestLoc = location_shift(@signLoc, 'down');
				@chestInv = null;
				try {
					@chestInv = get_inventory(@chestLoc);
				} catch(FormatException @ex) {
					die(color('red').'This shop doesn\'t have a chest.');
				}
				
				@pInv = pinv();
				@slotItem = @pInv[pheld_slot()];
				
				if(!@slotItem) {
					die();
				}
				
				@transaction = 'buy';
				if(@slotItem['type'].':'.@slotItem['data'] == @shop['item']) {
					@transaction = 'sell';
				}
					
				@currency = null;
				switch(@shop[@transaction][4]) {
					case 'd':
						@currency = 264; // 'DIAMOND'
					case 'e':
						@currency = 388; // 'EMERALD'
					case 'g':
						@currency = 266; // 'GOLD_INGOT'
					case 'i':
						@currency = 265; // 'IRON_INGOT'
					default:
						throw('FormatException', 'Shop has unhandled currency: '.@shop[@transaction][4]);
				}
				
				@takeType = @currency;
				@takeData = null;
				if(@transaction == 'buy') {
					if(@slotItem['type'] != @currency || @slotItem['qty'] < @shop[@transaction][3]) {
						die(color('gold').'You need to hold '.@shop[@transaction][3].' '.data_name(@currency)
								.if(@shop[@transaction][3] > 1, 's').' in your hand.');
					}
					@split = split(':', @shop['item'], 1);
					@takeType = @split[0];
					if(array_size(@split) == 2) {
						@takeData = @split[1];
					}
				}

				@items = array();
				@itemsLeft = integer(@shop[@transaction][2]);
				@currencyLeft = integer(@shop[@transaction][3]);
				foreach(@index: @invItem in @chestInv) {
					if(@invItem && @invItem['type'] == @takeType && (is_null(@takeData) || @invItem['data'] == @takeData)) {
						if(@invItem['qty'] > @itemsLeft) {
							// take some from this stack
							@invItem['qty'] -= @itemsLeft;
							@newItem = @invItem[];
							@newItem['qty'] = @itemsLeft;
							@items[] = @newItem;
							@itemsLeft = 0;
							break();
						} else if(@invItem['qty'] < @itemsLeft) {
							// take what we can and move to the next stack
							@items[] = @invItem[];
							@itemsLeft -= @invItem['qty'];
							@chestInv[@index] = null;
						} else {
							// move this stack
							@items[] = @invItem;
							@itemsLeft = 0;
							@chestInv[@index] = null;
							break();
						}
					}
				}

				if(@itemLeft == 0) {
					// enough in stock
					set_inventory(@chestLoc, @chestInv);
					foreach(@item in @items) {
						pgive_item(@item);
					}
					msg(color('green').'Success');
				} else {
					msg(color('gold').'Not enough in stock.');
				}
			}
		}
		
		// cache current stock
		if(@signLoc['world'] != 'shard') {
			set_timeout(50, closure(){ // do this after a transaction
				include('core.library/cache.ms');
				_cache_shop(@shop, @signLoc);
			});
		}
	}
}

// Shop Sign Break
bind('block_break', array('priority': 'LOWEST'), array('name': 'WALL_SIGN'), @event) {
	if(sk_can_build(@event['location'])) {
		include('core.library/sign.ms');
		if(@shop = _sign_get_shop(@event['location'])) {
			include('core.library/shop.ms');
			if(_is_shop_owner(@shop)) {
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
bind('block_place', null, array('name': 'HOPPER'), @event) {
	if(sk_can_build(@event['location'])) {
		@loc = location_shift(@event['location'], 'up');
		@type = split(':', get_block_at(@loc))[0];
		if(@type === '54' || @type === '146') {
			@signLoc = location_shift(@loc, 'up');
			if(split(':', get_block_at(@signLoc))[0] == '68') {
				include('core.library/sign.ms');
				if(@shop = _sign_get_shop(@signLoc)) {
					include('core.library/shop.ms');
					if(!_is_shop_owner(@shop)) {
						cancel();
						msg(color('red').'[Shop] You cannot place a hopper below a shop you don\'t own.');
					}
				}
			}
		}
	}
}

bind('player_interact', array('priority': 'LOWEST'), array('block': 54, 'button': 'right'), @event) {
	if(sk_can_build(@event['location'])) {
		include('core.library/sign.ms');
		if(@shop = _sign_get_shop(location_shift(@event['location'], 'up'))) {
			include('core.library/shop.ms');
			if(!_is_shop_owner(@shop)) {
				cancel();
				msg(color('red').'[Shop] You do not own this shop.');
			}
		}
	}
}

bind('player_interact', array('priority': 'LOWEST'), array('block': 146, 'button': 'right'), @event) {
	if(sk_can_build(@event['location'])) {
		include('core.library/sign.ms');
		if(@shop = _sign_get_shop(location_shift(@event['location'], 'up'))) {
			include('core.library/shop.ms');
			if(!_is_shop_owner(@shop)) {
				cancel();
				msg(color('red').'[Shop] You do not own this shop.');
			}
		}
	}
}
