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
				@result = 326; // water bucket
			case '374': // bottle
				@result = 373; // water bottle
			case '159':
				@result = 172; // hardened clay
			case '35':
				@result = 35; // wool
			case '171':
				@result = 171; // wool carpet
			default:
				die();
		}
		cancel();
		@item = pinv(player(), @slot);
		if(@item['qty'] == 1) {
			set_pinv(player(), @slot, array('type': @result, 'qty': 1));
		} else {
			@item['qty']--;
			set_pinv(player(), @slot, @item);
			@remaining = pgive_item(@result, 1);
			if(@remaining) {
				drop_item(associative_array('type': @result));
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
