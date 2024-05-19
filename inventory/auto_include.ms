/*
	Removes all items from a player's inventory and armor slots
*/
proc _clear_pinv(@player) {
	if(!@player) {
		@player = player();
	}
	@world = pworld(@player);
	if(_is_survival_world(@world)) {
		return();
	}
	clear_pinv(@player);
}

/*
	Sets a player's inventory with a preset kit
*/
proc _equip_kit(@player, @inv) {
	if(!@player) {
		@player = player();
	}

	if(!ponline(@player)) {
		return();
	}

	@worldInfo = _worlds_config()[pworld(@player)];
	switch(@worldInfo['group']) {
		case 'minigames':
			@mode = pmode(@player);
			if(@mode != @worldInfo['mode']) {
				set_pmode(@player, @worldInfo['mode']);
			}
			clear_pinv(@player);
			@pdata = _pdata(@player);
			@kit = array(
				4: array(
					name: 'KNOWLEDGE_BOOK',
					meta: array(
						display: color('green').'Park Directory',
						lore: array(
							color('white').'Opens a menu to view and teleport to various',
							color('white').'games and attractions here in Frog Park.'
				))),
				3: array(
					name: 'COOKED_MUTTON',
					qty: 32,
					meta: array(
						display: color('white').'Frog Legs',
						lore: array(
							color('gray').'Good eatin\''
				))),
			);
			if(array_index_exists(@pdata, 'support') && @pdata['support'] >= 10) {
				@kit[5] = array(
					name: 'FIREWORK_ROCKET',
					meta: array(
						display: colorize('&r&kX&a&l Random Firework &r&kX'),
						lore: array(
							color('white').'A dynamic donor detonation!',
				)));
			}
			if(is_array(@inv)) {
				set_pinv(@player, array_merge(@kit, @inv));
			} else {
				set_pinv(@player, @kit);
			}
			set_pflight(@player, false);

		case 'dev':
			@session = _psession(@player);
			if(array_index_exists(@session, 'devInventory')) {
				set_pinv(@player, @session['devInventory']);
			} else {
				clear_pinv(@player);
			}
	}
}

/*
	Returns specific item meta or null if it doesn't exist
*/
proc _item_meta(@item, @index) {
	if(is_null(@item)
	|| is_null(@item['meta'])) {
		return(null);
	}
	return(@item['meta'][@index]);
}

/*
	Compacts all of an inventory array by removing unnecessary keys in item arrays
*/
proc _minify_inv(@inv, @keepnulls = false) {
	if(!is_array(@inv)) {
		throw('FormatException', 'This must be an item!');
	}

	/*
		Reduces an item array down to their necessary components to recreate the item.
	*/
	proc _minify_item(@item) {
		if(@item['qty'] == 1) {
			array_remove(@item, 'qty');
		}
		if(is_null(@item['meta'])) {
			array_remove(@item, 'meta');
		} else {
			@meta = @item['meta'];
			if(array_size(@meta['enchants']) == 0) {
				array_remove(@meta, 'enchants');
			} else {
				foreach(@enchant: @enchantArray in @meta['enchants']) {
					@meta['enchants'][@enchant] = @enchantArray['elevel'];
				}
			}
			if(is_null(@meta['display'])) {
				array_remove(@meta, 'display');
			}
			if(is_null(@meta['lore'])) {
				array_remove(@meta, 'lore');
			}
			if(is_null(@meta['model'])) {
				array_remove(@meta, 'model');
			}
			if(is_null(@meta['modifiers'])) {
				array_remove(@meta, 'modifiers');
			}
			if(is_null(@meta['tags'])) {
				array_remove(@meta, 'tags');
			}
			if(@meta['repair'] == 0) {
				array_remove(@meta, 'repair');
			}
			if(array_size(@meta['flags']) == 0) {
				array_remove(@meta, 'flags');
			}
			if(array_index_exists(@meta, 'damage')) {
				if(!@meta['damage']) {
					array_remove(@meta, 'damage');
				}
				if(!@meta['unbreakable']) {
					array_remove(@meta, 'unbreakable');
				}
			}
			if(array_index_exists(@meta, 'blockdata') && is_null(@meta['blockdata'])) {
				array_remove(@meta, 'blockdata');
			}
			// specific meta
			if(array_index_exists(@meta, 'inventory')) {
				_minify_inv(@meta['inventory']);
			} else if(array_index_exists(@meta, 'trim') && is_null(@meta['trim'])) {
				array_remove(@meta, 'trim');
			}
		}
	}

	if(array_index_exists(@inv, 'name')) {
		_minify_item(@inv);
	} else {
		foreach(@slot: @item in @inv) {
			if(@item == null) {
				if(!@keepnulls) {
					array_remove(@inv, @slot);
				}
			} else {
				_minify_item(@item);
			}
		}
	}
	return(@inv);
}
