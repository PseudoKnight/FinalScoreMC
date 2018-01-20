/*
	Infinite Cauldrons
	Refills buckets and water bottles without reducing water levels, unless sneaking.
	Also lets players incrementally fill cauldrons with water bottles.
	
	Undyeing More items
	Stained clay, Wool, Carpet
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
		@result = null;
		switch(split(':', @event['item'])[0]) {
			case '325': // bucket
				if(@data < 3) {
					die();
				}
				@result = 'WATER_BUCKET';
			case '374':
				@result = 'WATER_BOTTLE';
			case '159':
				@result = 'HARD_CLAY';
			case '35':
				@result = 'WOOL';
			case '171':
				@result = 'CARPET';
			default:
				die();
		}
		@loc = @event['location'];
		@loc['x'] += 0.5;
		@loc['y'] += 1;
		@loc['z'] += 0.5;
		play_effect(@loc, 'SPLASH', array('particleCount': 10, 'offsetX': 0.15, 'offsetZ': 0.15));
		play_sound(@loc, array('sound': 'SPLASH', 'pitch': 2, 'volume': 0.3));
		cancel();
		@item = pinv(player(), @slot);
		if(@item['qty'] == 1) {
			set_pinv(player(), @slot, array('name': @result));
		} else {
			@item['qty']--;
			set_pinv(player(), @slot, @item);
			@remaining = pgive_item(array('name': @result));
			if(@remaining) {
				drop_item(array('name': @result));
			}
		}

		// Remove some water from the cauldron if sneaking
		if(psneaking()) {
			if(@result == 373) {
				@data--;
				set_block_at(@event['location'], '118:'.@data);
			} else {
				set_block_at(@event['location'], '118:0');
			}
		}

	}
}
