proc _prepare_shops(@waves) {
	@shop = associative_array();
	@items = associative_array();
	foreach(@index: @item in @waves['config']['shop']) {
		@name = @item['name'];
		@meta = associative_array();
		if(array_index_exists(@item, 'meta')) {
			@meta = @item['meta'];
		}
		@meta['lore'] = array('Buy for '.@item['cost'].' level'.if(@item['cost'] > 1, 's'));
		@shop[@index] = array(name: @name, qty: @item['cost'], meta: @meta);
		@items[@name] = @item['cost'];
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

	@waves['binds'][] = bind('player_interact', null, array(button: 'right', itemname: 'NETHER_STAR'), @event, @waves) {
		foreach(@p in players_in_radius(ploc(), 16)) {
			if(pmode(@p) == 'SPECTATOR') {
				set_pmode(@p, 'ADVENTURE');
				_waves_add_player(@p, @waves);
				set_ploc(@p, ploc());
				ptake_item(array(name: 'NETHER_STAR'));
				die();
			}
		}
		msg('Ghost player must be within 16 meters to resurrect!')
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