register_command('shop', array(
	'description': 'List cached item shops or edit owned item shops.',
	'usage': '/shop list <item_name> | /shop edit <buy|sell> <#qty> for <#currency>',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('list', 'edit'), @args[-1]));
		}
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		include('core.library/shop.ms');
		
		if(@args[0] == 'list') {
			if(array_size(@args) == 1) {
				msg(color('yellow').'[Shop] Lists stocked shops for an item.');
				msg('Example: '.color('gray').'"/shop list diamond"');
				msg('The location of each shop is shown as (x,y,z world) coordinates.');
				die('You can see your current coordinates by pressing F3.');
			}
			
			@value = array_implode(@args[1..-1]);
			@item = _data_values(@value);
			if(!@item) {
				die(color('gold').'Unknown item');
			}
			@itemid = replace(@item, ':', '.');
			@shops = get_value('shop', @itemid);
			if(!@shops) {
				die(color('gold').'No stocked shops found for '.color('o').'"'.@value.'" ('.@item.')');
			} else {
				msg(color('gold').'Shops you can buy or sell '.color('o').'"'.@value.'"');
				msg(color('gray').'-----------------------------------------------------');
			}
			@save = false;
			foreach(@key: @shop in @shops[0]) {
				if(@shop['location'][3] != 'shard' && (@shopsign = _get_shop(@shop['location'])) && @shopsign['item'] == @item) {
					msg(colorize('Buy '.@shop['price'].'&7 ('.@shop['stock'].') &e'.@shop['owner'].'&7 '
					.@shop['location'][0].','.@shop['location'][1].','.@shop['location'][2].' '._worldname(@shop['location'][3])));
				} else {
					array_remove(@shops[0], @key);
					@save = true;
				}
			}
			msg(color('gray').'-----------------------------------------------------');
			set_timeout(50, closure(){
				foreach(@key: @shop in @shops[1]) {
					if(@shop['location'][3] != 'shard' && (@shopsign = _get_shop(@shop['location'])) && @shopsign['item'] == @item) {
						msg(colorize('Sell '.@shop['price'].'&7 ('.@shop['stock'].') &e'.@shop['owner'].'&7 '
						.@shop['location'][0].','.@shop['location'][1].','.@shop['location'][2].' '._worldname(@shop['location'][3])));
					} else {
						array_remove(@shops[1], @key);
						@save = true;
					}
				}
				msg(color('gray').'-----------------------------------------------------');
				if(@save) {
					store_value('shop', @itemid, @shops);
				}
			});
			
		} else if(@args[0] == 'edit') {
			if(array_size(@args) < 5) {
				msg(color('gold').'[Shop] Edits a line on your shop that you\'re looking at.');
				die('Example: '.color('gray').'"/shop edit buy 1 for 1g"');
			}
			
			@line = 0;
			@transaction = @args[1];
			if(@transaction === 'buy') {
				@line = 1;
			} else if(@transaction === 'sell') {
				@line = 2;
			} else {
				die(color('gold').'[Shop] You need to specify "buy" or "sell".');
			}
			
			
			@value = array_implode(@args[2..-1]);
		
			@loc = pcursor();
		
			if(!@shop = _get_shop(@loc)) {
				die(color('gold').'[Shop] There is no shop sign there.');
			}
		
			if(!_is_shop_owner(player(), @shop['owner']) && !has_permission('shop.admin')) {
				die(color('gold').'[Shop] You do not own this shop.');
			}
		
			@signText = get_sign_text(@loc);
			@signText[@line] = if(@line == 1, 'Buy ', 'Sell ').@value;
			@shop[@transaction] = _get_shop_price(@signText[@line]);
			if(!@shop[@transaction]) {
				die(color('gold').'[Shop] Usage Example: /shop edit buy 16 for 1g');
			}
			set_sign_text(@loc, @signText);
			msg(color('green').'[Shop] Modified');
		
			@shops = get_value('shop', @shop['key']);
			if(!@shops) {
				die();
			}
		
			@loc = array(integer(@loc['x']), integer(@loc['y']), integer(@loc['z']), @loc['world']);
		
			@t = @line - 1;
			foreach(@i: @s in @shops[@t]) {
				if(@s['location'] == @loc) {
					if(@t == 0) {
						@count = _get_inventory_count(location_shift(@loc, 'down'), @shop['item']);
						if(is_null(@count)) {
							die(color(6).'[Shop] No container below this shop sign.');
						}
						if(@count < @shop['buy'][2]) {
							array_remove(@shops[@t], @i);
						} else {
							@shops[@t][@i] = array(
								'location': @loc,
								'price': @shop['buy'][1],
								'owner': @shop['owner'],
								'stock': @count,
							);
						}
					} else {
						switch(@shop['sell'][4]) {
							case 'g':
								@currency = '266';
							case 'i':
								@currency = '265';
							case 'd':
								@currency = '264';
							case 'e':
								@currency = '388';
							default:
								die(color(6).'[Shop] Unknown currency.');
						}
						@count = _get_inventory_count(location_shift(@loc, 'down'), @currency.':0');
						if(is_null(@count)) {
							die(color(6).'[Shop] No container below this shop sign.');
						}
						if(@count < @shop['sell'][3]) {
							array_remove(@shops[@t], @i);
						} else {
							@shops[@t][@i] = array(
								'location': @loc,
								'price': @shop['sell'][1],
								'owner': @shop['owner'],
								'stock': @count
							);
						}
					}
					break();
				}
			}
			store_value('shop', @shop['key'], @shops);
			
		} else {
			return(false);
		}
	}
));
