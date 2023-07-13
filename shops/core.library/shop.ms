include('item.ms');
include('chest.ms');
include('sign.ms');

proc _is_shop_owner(@shop) {
	return(@shop['owner'] == player());
}

proc _shop_show_info(@shop) {
	@chestLoc = location_shift(@shop['loc'], 'down');
	@chestInv = null;
	try {
		@chestInv = get_inventory(@chestLoc);
	} catch(Exception @ex) {
		die(color('red').'This shop doesn\'t have a chest.');
	}
	
	if(array_size(@chestInv) > 35) {
		die(color('red').'Shops do not support double chests at this time.');
	}

	if(@shop['buy']) {
		@itemCount = _chest_item_count(@chestInv, @shop['item']);
		if(@itemCount >= @shop['buy'][2]) {
			msg(colorize("&aShop has &l@itemCount&a &l"._item_display(@shop['item'])."&a left."));
		} else {
			msg(colorize("&6Shop has insufficient stock of &l"._item_display(@shop['item']).'.'));
		}
	}
	if(@shop['sell']) {
		@currency = _item_get_currency(@shop['sell'][4]);
		@currencyCount = _chest_item_count(@chestInv, @currency);
		if(@currencyCount >= @shop['sell'][3]) {
			msg(colorize("&aShop has &l@currencyCount&a &l"._item_display(@currency)."&a left."));
		} else {
			msg(colorize("&6Shop has insufficient stock of &l"._item_display(@currency).'.'));
		}
	}
}

proc _shop_process_transaction(@shop) {
	@chestLoc = location_shift(@shop['loc'], 'down');
	@chestInv = null;
	try {
		@chestInv = get_inventory(@chestLoc);
	} catch(Exception @ex) {
		die(color('red').'This shop doesn\'t have a chest.');
	}
	
	if(array_size(@chestInv) > 35) {
		die(color('red').'Shops do not support double chests at this time.');
	}
	
	@slotItem = pinv(player(), null);
	
	if(!@slotItem) {
		die(colorize('&6You need to hold an item in your hand.'));
	}
	
	@transaction = 'buy';
	if(@slotItem['name'] == @shop['item']) {
		@transaction = 'sell';
	}
	if(!@shop[@transaction]) {
		die(colorize('&6Cannot '.@transaction.' from this shop.'));
	}
	
	@currency = _item_get_currency(@shop[@transaction][4]);
	@chestItem = null;
	if(@transaction == 'buy') {
		if(@slotItem['name'] != @currency || @slotItem['qty'] < @shop[@transaction][3]) {
			die(colorize('&6You need to hold at least &l'.@shop[@transaction][3].'&6 of '.@currency.' in your hand.'));
		}
		@slotItem['qty'] = integer(@shop[@transaction][3]);
		@chestItem = array('name': @shop['item'], 'qty': @shop[@transaction][2]);
	} else if(@transaction == 'sell') {
		if(@slotItem['qty'] < @shop[@transaction][2]) {
			die(colorize('&6You need to hold at least &l'.@shop[@transaction][2].'&6 of '.@shop['item'].' in your hand.'));
		}
		@slotItem['qty'] = integer(@shop[@transaction][2]);
		@chestItem = array('name': @currency, 'qty': @shop[@transaction][3]);
	}
	
	@count = _chest_item_count(@chestInv, @chestItem['name']);
	if(@count < @chestItem['qty']) {
		die(colorize('&6Not enough &l'.@chestItem['name'].'&6 in this shop.'));
	}

	@maxSlotItem = max_stack_size(@slotItem);
	@maxChestItem = max_stack_size(@chestItem);
	
	@availableSlots = array_filter(pitem_slot(null), closure(@key, @value) {
		return(@value >= 0 && @value <= 35);
	});
	if(array_size(@availableSlots) < @chestItem['qty'] / @maxChestItem) {
		die(colorize('&6Not enough space in your inventory.'));
	}
	
	if(@chestItem['qty'] < @maxChestItem && !_chest_has_space(@chestInv)) {
		die(colorize('&6Not enough space in this shop.'));
	}
	
	// we can do the transaction!
	@itemsLeft = @chestItem['qty'];
	foreach(@slot in range(36)) {
		@item = @chestInv[@slot];
		if(@item && @item['name'] == @chestItem['name']) {
			if(@item['qty'] > @itemsLeft) {
				// take some from this stack
				@item['qty'] -= @itemsLeft;
				@newItem = @item[];
				@newItem['qty'] = @itemsLeft;
				pgive_item(@newItem);
				@itemsLeft = 0;
				break();
			} else if(@item['qty'] < @itemsLeft) {
				// take what we can and move to the next stack
				pgive_item(@item);
				@itemsLeft -= @item['qty'];
				@chestInv[@slot] = null;
			} else {
				// move this stack
				pgive_item(@item);
				@itemsLeft = 0;
				@chestInv[@slot] = null;
				break();
			}
		}
	}
	
	set_inventory(@chestLoc, @chestInv);
	add_to_inventory(@chestLoc, @slotItem);
	
	@item = pinv(player(), null);
	@item['qty'] -= @slotItem['qty'];
	set_pinv(player(), null, @item);
}
