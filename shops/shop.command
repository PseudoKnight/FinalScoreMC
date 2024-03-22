register_command('shop', array(
	description: 'List cached item shops or edit owned item shops.',
	usage: '/shop list <item_name> | /shop edit <buy|sell> <#qty> for <#currency>',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('list', 'edit'), @args[-1]));
		} else if(array_size(@args) == 2) {
			if(@args[0] == 'list') {
				return(_strings_start_with_ic(import('materials', array()), @args[-1]));
			} else if(@args[0] == 'edit') {
				return(_strings_start_with_ic(array('buy', 'sell', '['), @args[-1]));
			}
		}
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		include_dir('core.library');
		
		if(@args[0] == 'list') {
			if(array_size(@args) == 1) {
				msg(color('yellow').'[Shop] Lists stocked shops for an item.');
				msg('Example: '.color('gray').'"/shop list diamond"');
				msg('The location of each shop is shown as (x,y,z world) coordinates.');
				die('You can see your current coordinates by pressing F3.');
			}
			
			@item = to_upper(array_implode(@args[1..-1], '_'));
			try {
				material_info(@item);
			} catch(IllegalArgumentException @ex) {
				die(color('gold').'Unknown item: '.@item);
			}
			@shops = get_value('shops', @item);
			if(!@shops) {
				die(color('gold').'No stocked shops found for '.color('o').'"'.@item.'"');
			} else {
				msg(color('gold').'Shops you can buy or sell '.color('o').'"'.@item.'"');
				msg(color('gray').'-----------------------------------------------------');
			}
			@save = false;
			foreach(@key: @shop in @shops[0]) {
				if(_is_survival_world(@shop['location'][3]) && (@shopsign = _sign_get_shop(@shop['location'])) && @shopsign['item'] == @item) {
					msg(colorize('Buy '.@shop['price'].'&7 ('.@shop['stock'].') &e'.@shop['owner'].'&7 '
					.@shop['location'][0].','.@shop['location'][1].','.@shop['location'][2].' '._world_name(@shop['location'][3])));
				} else {
					array_remove(@shops[0], @key);
					@save = true;
				}
			}
			msg(color('gray').'-----------------------------------------------------');
			set_timeout(50, closure(){
				foreach(@key: @shop in @shops[1]) {
					if(_is_survival_world(@shop['location'][3]) && (@shopsign = _sign_get_shop(@shop['location'])) && @shopsign['item'] == @item) {
						msg(colorize('Sell '.@shop['price'].'&7 ('.@shop['stock'].') &e'.@shop['owner'].'&7 '
						.@shop['location'][0].','.@shop['location'][1].','.@shop['location'][2].' '._world_name(@shop['location'][3])));
					} else {
						array_remove(@shops[1], @key);
						@save = true;
					}
				}
				msg(color('gray').'-----------------------------------------------------');
				if(@save) {
					store_value('shops', @item, @shops);
				}
			});
			
		} else if(@args[0] == 'edit') {
			if(array_size(@args) < 2) {
				msg(color('gold').'[Shop] Edits a line on your shop that you are looking at.');
				die('Example: '.color('gray').'"/shop edit buy 1 for 1g"');
			}
		
			@loc = pcursor();
		
			if(!@shop = _sign_get_shop(@loc)) {
				die(color('gold').'[Shop] There is no shop sign there.');
			}

			if(!_is_shop_owner(@shop) && !has_permission('shop.admin')) {
				die(color('gold').'[Shop] You do not own this shop.');
			}
		
			@signText = get_sign_text(@loc);

			// Check first for item name change
			if(string_starts_with(@args[1], '[') && string_ends_with(@args[-1], ']')) {
				include_dir('cache.library');
				@signText[0] = array_implode(@args[1..-1], ' ');
				// Remove and create new cache when changing item name
				_remove_cached_shop(@shop);
				set_sign_text(@loc, @signText);
				@shop = _sign_get_shop(@loc);
				if(!@shop['item']) {
					die(color('red').'Cannot determine the item type.');
				}
				_cache_shop(@shop);
				msg(color('green').'[Shop] Modified');
				die();
			}

			// Now check for price changes
			@transaction = @args[1];	
			@value = array_implode(@args[2..-1]);
			if(@transaction == 'buy') {
				@signText[1] = 'Buy '.@value;
				@shop[@transaction] = _sign_get_buy_price(@signText);
			} else if(@transaction == 'sell') {
				@signText[2] = 'Sell '.@value;
				@shop[@transaction] = _sign_get_sell_price(@signText);
			} else {
				die(color('gold').'[Shop] You need to specify "buy" or "sell".');
			}
			if(!@shop[@transaction]) {
				die(color('gold').'[Shop] Usage Example: /shop edit buy 16 for 1g');
			}
			set_sign_text(@loc, @signText);
			msg(color('green').'[Shop] Modified');
		
			@shops = get_value('shops', @shop['item']);
			if(!@shops) {
				die();
			}
		
			@loc = array(integer(@loc['x']), integer(@loc['y']), integer(@loc['z']), @loc['world']);
		
			@t = if(@transaction == 'buy', 0, 1);
			foreach(@i: @s in @shops[@t]) {
				if(@s['location'] == @loc) {
					array @chestInv;
					if(@t == 0) {
						try {
							@chestInv = get_inventory(location_shift(@loc, 'down'));
						} catch(FormatException @ex) {
							die(color(6).'[Shop] No container below this shop sign.');
						}
						@count = _chest_item_count(@chestInv, @shop['item']);

						if(@count < @shop['buy'][2]) {
							array_remove(@shops[@t], @i);
						} else {
							@shops[@t][@i] = array(
								location: @loc,
								price: @shop['buy'][1],
								owner: @shop['owner'],
								stock: @count,
							);
						}
					} else {
						@currency = _item_get_currency(@shop['sell'][4]);
						try {
							@chestInv = get_inventory(location_shift(@loc, 'down'));
						} catch(FormatException @ex) {
							die(color(6).'[Shop] No container below this shop sign.');
						}
						@count = _chest_item_count(@chestInv, @shop['item']);
						if(@count < @shop['sell'][3]) {
							array_remove(@shops[@t], @i);
						} else {
							@shops[@t][@i] = array(
								location: @loc,
								price: @shop['sell'][1],
								owner: @shop['owner'],
								stock: @count
							);
						}
					}
					break();
				}
			}
			store_value('shops', @shop['item'], @shops);
			
		} else {
			return(false);
		}
	}
));
