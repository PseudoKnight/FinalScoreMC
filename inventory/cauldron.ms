/*
	Infinite Cauldrons
	Refills buckets and water bottles without reducing water levels, unless sneaking.
	Also lets players incrementally fill cauldrons with water bottles.
	
	Undyeing More items
	Stained clay, Wool, Carpet, Shulker Boxes
*/
bind(player_interact, null, array('block': 118, 'button': 'right'), @event) {
	@slot = null;
	if(@event['hand'] == 'off_hand') {
		@slot = -106;
	}
	@data = integer(array_get(split(':', @event['block']), 1, 0));
	if(@data < 3 && @event['item'] == '373:0'){
		@item = pinv(player(), @slot);
		if(@item['meta']['base']['type'] == 'WATER') {
			cancel();

			// Fill cauldron with some water
			@data++;
			set_block_at(@event['location'], '118:'.@data);

			// Give empty bottle
			set_pinv(player(), @slot, array('name': 'GLASS_BOTTLE'));
		}
	} else if(@data > 0) {
		// There's some water
		@item = pinv(player(), @slot);
		if(!@item) {
			die();
		}
		@newItem = @item[];
		@newItem['qty'] = 1;
		switch(@item['name']) {
			case 'BUCKET':
				if(@data < 3) {
					die();
				}
				@newItem['name'] = 'WATER_BUCKET';
			case 'GLASS_BOTTLE':
				@newItem['name'] = 'POTION';
			case 'STAINED_CLAY':
				@newItem['name'] = 'HARD_CLAY';
			case 'WOOL':
				@newItem['data'] = 0;
			case 'CARPET':
				@newItem['data'] = 0;
			default:
				if(string_ends_with(@item['name'], '_SHULKER_BOX')) {
					// 1.13
					@newItem['name'] = 'PURPLE_SHULKER_BOX';
				} else {
					die();
				}
		}
		@loc = @event['location'][];
		@loc['x'] += 0.5;
		@loc['y'] += 1;
		@loc['z'] += 0.5;
		play_effect(@loc, 'SPLASH', array('particleCount': 10, 'offsetX': 0.15, 'offsetZ': 0.15));
		play_sound(@loc, array('sound': 'SPLASH', 'pitch': 2, 'volume': 0.3));
		cancel();
		if(@item['qty'] == 1) {
			set_pinv(player(), @slot, @newItem);
		} else {
			@item['qty']--;
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
				@data--;
				set_block_at(@event['location'], '118:'.@data);
			} else {
				set_block_at(@event['location'], '118:0');
			}
		}1

	}
}
