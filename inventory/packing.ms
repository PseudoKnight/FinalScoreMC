/*
	EXPERIMENTAL
	Allows players to manually "pack" certain item types with low max stack sizes up to 64.
	Can be used to make certain consumables more practical on the hotbar.
	(e.g. potions, soups, ender pearls)
 */
bind('inventory_click', null, array(clicktype: 'LEFT', virtual: false), @event) {
	@cursorItem = @event['cursoritem'];
	@slotItem = @event['slotitem'];
	if(has_permission('inventory.packing') 
	&& @cursorItem && (!@slotItem || @cursorItem['name'] == @slotItem['name'])) {
		@type = @cursorItem['name'];

		// If the slot item or cursor item stack is already 64, we do not need to pack
		@cursorItemQty = @cursorItem['qty'];
		@slotItemQty = 0;
		if(@slotItem) {
			if(@cursorItemQty >= 64) {
				die();
			}
			@slotItemQty = @slotItem['qty'];
		}
		if(@slotItemQty >= 64) {
			die();
		}

		// Filter item types that we can pack
		// This should primarily be under-utilized consumables with low stack counts
		if(!array_contains(array('ENDER_PEARL', 'POTION', 'SPLASH_POTION', 'LINGERING_POTION',
				'MUSHROOM_STEW', 'BEETROOT_SOUP', 'RABBIT_STEW'), @type)) {
			die();
		}

		// If total quantity is less than the item stack size, normal stacking is fine
		@maxStacksize = material_info(@type, 'maxStacksize');
		if(@cursorItemQty + @slotItemQty <= @maxStacksize) {
			die();
		}

		// Exclude items where meta is not identical
		if(@slotItem && (is_null(@cursorItem['meta']) != is_null(@slotItem['meta']) 
				|| @slotItem['meta'] && !array_subset_of(@cursorItem['meta'], @slotItem['meta']))) {
			die();
		}

		cancel();

		if(@slotItem) {
			// Pack items up to 64
			@qty = min(@cursorItemQty, 64 - @slotItemQty);
			@cursorItem['qty'] -= @qty;
			@slotItem['qty'] += @qty;
			modify_event('cursoritem', @cursorItem);
			modify_event('slotitem', @slotItem);
			play_sound(ploc(), array(sound: 'ITEM_BUNDLE_INSERT'));
		} else {
			// Place packed item into slot
			modify_event('cursoritem', null);
			modify_event('slotitem', @cursorItem);
		}
	}
}