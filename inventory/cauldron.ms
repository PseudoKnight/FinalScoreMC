/*
	Infinite Cauldrons
	Refills buckets and water bottles without reducing water levels, unless sneaking.
	Also lets players incrementally fill cauldrons with water bottles.

	Undyeing More items
	Stained Terracotta, Shulker Boxes
*/
bind('player_interact', null, array('block': 'CAULDRON', 'button': 'right'), @event) {
	@slot = null;
	if(@event['hand'] == 'off_hand') {
		@slot = -106;
	}
	if(@event['item'] && @event['item']['name'] == 'POTION'){
		@item = pinv(player(), @slot);
		if(@item['meta'] && @item['meta']['base']['type'] == 'WATER') {
			cancel();
			set_blockdata_string(@event['location'], 'water_cauldron[level=1]');
			set_pinv(player(), @slot, array('name': 'GLASS_BOTTLE'));
		}
	}
}
bind('player_interact', null, array('block': 'WATER_CAULDRON', 'button': 'right'), @event) {
	@slot = null;
	if(@event['hand'] == 'off_hand') {
		@slot = -106;
	}
	@level = reg_match('level\\=(\\d)', get_blockdata_string(@event['location']))[1];
	if(@level < 3 && @event['item'] && @event['item']['name'] == 'POTION'){
		@item = pinv(player(), @slot);
		if(@item['meta'] && @item['meta']['base']['type'] == 'WATER') {
			cancel();

			// Fill cauldron with some water
			@level++;
			set_blockdata_string(@event['location'], 'water_cauldron[level='.@level.']');

			// Give empty bottle
			set_pinv(player(), @slot, array('name': 'GLASS_BOTTLE'));
		}
	} else if(@level > 0) {
		// There is some water
		@item = pinv(player(), @slot);
		if(!@item) {
			die();
		}

		@loc = @event['location'][];
		@pos = @event['position'];
		if(@event['facing'] == 'up' && @pos['y'] < 1.0) {
			@loc['x'] += @event['position']['x'];
			@loc['y'] += 1;
			@loc['z'] += @event['position']['z'];
		} else {
			@loc['x'] += 0.5;
			@loc['y'] += 1;
			@loc['z'] += 0.5;
		}

		spawn_particle(@loc, array('particle': 'WATER_SPLASH', 'count': 10, 'xoffset': 0.15, 'zoffset': 0.15));
		play_sound(@loc, array('sound': 'ENTITY_GENERIC_SPLASH', 'pitch': 2, 'volume': 0.3));

		@newItem = @item[];

		if(@item['name'] == 'BUCKET') {
			if(@level < 3) {
				die();
			}
			@newItem['name'] = 'WATER_BUCKET';
			@newItem['qty'] = 1;
		} else if(@item['name'] == 'GLASS_BOTTLE') {
			@newItem['name'] = 'POTION';
			@newItem['meta'] = array('base': array('type': 'WATER'));
			@newItem['qty'] = 1;
		} else if(string_ends_with(@item['name'], '_TERRACOTTA')) {
			@newItem['name'] = 'TERRACOTTA';
		} else {
			die();
		}

		cancel();
		if(@item['qty'] == @newItem['qty']) {
			set_pinv(player(), @slot, @newItem);
		} else {
			@item['qty'] -= @newItem['qty'];
			set_pinv(player(), @slot, @item);
			@remaining = pgive_item(@newItem);
			if(@remaining) {
				@newItem['qty'] = @remaining;
				drop_item(@newItem);
			}
		}

		// Remove some water from the cauldron if sneaking
		if(psneaking()) {
			if(@newItem['name'] == 'POTION') {
				@level--;
				if(@level) {
					set_blockdata_string(@event['location'], 'water_cauldron[level='.@level.']');
				} else {
					set_block(@event['location'], 'CAULDRON');
				}
				
			} else {
				set_blockdata_string(@event['location'], 'cauldron');
			}
		}

	}
}
