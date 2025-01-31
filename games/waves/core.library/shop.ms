proc _prepare_shops(@waves, @tier = 0) {
	@tierName = null;
	if(array_index_exists(@waves['config'], 'shoptiers')) {
		@tierName = @waves['config']['shoptiers'][@tier]['name'];
	}
	@shop = associative_array();
	@items = associative_array();
	foreach(@index: @item in @waves['config']['shop']) {
		if(@tierName && array_index_exists(@item, 'tier') && @item['tier'] !== @tierName) {
			continue();
		}
		@name = @item['name'];
		@meta = associative_array();
		if(array_index_exists(@item, 'meta')) {
			@meta = @item['meta'];
		}
		@meta['lore'] = array('Buy for '.@item['cost'].' level'.if(@item['cost'] > 1, 's'));
		@shop[@index] = array(name: @name, qty: @item['cost'], meta: @meta);
		@items[@name] = @item['cost'];
	}
	if(array_index_exists(@waves['config'], 'shoptiers') && array_index_exists(@waves['config']['shoptiers'], @tier + 1)) {
		@shop[53] = array(
			name: @waves['config']['shoptiers'][@tier + 1]['item'],
			qty: @waves['config']['shoptiers'][@tier + 1]['cost'],
			meta: array(display: 'Upgrade shop to '.@waves['config']['shoptiers'][@tier + 1]['name'].' tier'));
	}
	@waves['shop'] = @items;
	create_virtual_inventory('waves'.@waves['region'], 54, 'BUY OR SELL', @shop);
}

proc _bind_shop_events(@waves) {
	@waves['binds'][] = bind('player_interact', null, array(button: 'right', itemname: 'EMERALD'), @event, @waves) {
		if(array_contains(@waves['players'], player()) && pworld() == @waves['world']) {
			popen_inventory('waves'.@waves['region']);
		}
	}

	@waves['binds'][] = bind('item_pickup', null, null, @event, @waves) {
		if(array_contains(@waves['players'], player())) {
			@item = @event['item'];
			if(!@item['meta'] || !@item['meta']['lore']) {
				@name = @item['name'];
				if(!@item['meta']) {
					@item['meta'] = associative_array();
				}
				@refund = null;
				if(array_index_exists(@waves['shop'], @name)) {
					@refund = @waves['shop'][@name] / 2;
				} else {
					@refund = round(1 / min(16, material_info(@name)['maxStacksize']), 2);
				}
				@item['meta']['lore'] = array('Sell each for '.@refund.' levels');
				modify_event('item', @item);
			}
		}
	}

	@waves['binds'][] = bind('inventory_click', null, array(action: 'PICKUP_ALL', virtual: true), @event, @waves) {
		if(pinventory_holder() == 'waves'.@waves['region']) {
			@item = @event['slotitem'];
			if(@event['rawslot'] == 53 && array_index_exists(@waves['config'], 'shoptiers')) {
				@newTier = 0;
				foreach(@index: @tier in @waves['config']['shoptiers']) {
					if(@index && @tier['item'] === @item['name']) {
						@newTier = @index;
						if(plevel() < @tier['cost']) {
							die();
						}
						set_plevel(plevel() - @tier['cost']);
						play_sound(ploc(), array(sound: 'BLOCK_ANVIL_USE', volume: 2));
						break();
					}
				}
				if(@newTier) {
					delete_virtual_inventory('waves'.@waves['region']);
					_prepare_shops(@waves, @newTier);
				}
				die();
			}
			if(@item['name'] === 'EMERALD') {
				if(@item['meta'] && @item['meta']['display'] === 'Open Shop') {
					cancel();
				} else {
					@amount = @item['qty'];
					set_plevel(plevel() + @amount);
					action_msg(colorize("&e+@amount level"));
					set_pinv(player(), @event['slot'], null);
					play_sound(ploc(), array(sound: 'ENTITY_PLAYER_LEVELUP', pitch: 2, volume: 0.5), player());
				}
				die();
			}
			if(@item && @item['meta'] && @item['meta']['lore']) {
				@parts = parse_args(@item['meta']['lore'][0]);
				if(array_size(@parts) > 2 && @parts[0] == 'Buy' && is_integral(@parts[2])) {
					@cost = integer(@parts[2]);
					if(plevel() >= @cost) {
						@name = @item['name'];
						@meta = @item['meta'];
						@meta['lore'] = array('Sell each for '.@waves['shop'][@name] / 2.' levels');
						@item['qty'] = 1;
						pgive_item(@item);
						set_plevel(plevel() - @cost);
						play_sound(ploc(), array(sound: 'BLOCK_ANVIL_LAND', pitch: 2, volume: 0.5), player());
					}
					die();
				}
			}
			if(@item) {
				@refund = 0.5
				@name = @item['name'];
				if(array_index_exists(@waves['shop'], @name)) {
					@refund = @waves['shop'][@name] / 2;
				} else {
					@refund /= min(16, material_info(@name)['maxStacksize']);
				}
				@totalRefund = @item['qty'] * @refund;
				@xp = (pexp() / 100) + @totalRefund;
				@levels = floor(@xp);
				if(@levels) {
					set_plevel(plevel() + @levels);
				}
				@xp -= @levels;
				set_pexp(integer(@xp * 100));
				set_pinv(player(), @event['slot'], null);
				play_sound(ploc(), array(sound: 'ENTITY_PLAYER_LEVELUP', pitch: 2, volume: 0.5), player());
			}
		}
	}
}