proc _bind(@pvp) {
	@pvp['binds'][] = bind('item_pickup', array(priority: 'LOW'), null, @e, @pvp) {
		if(!array_index_exists(@pvp['players'], player()) || max_stack_size(@e['item']) != 1) {
			die();
		}

		foreach(@slot: @item in pinv()) {
			if(@item
			&& @e['item']['name'] == @item['name']
			&& @e['item']['name'] != 'POTION'
			&& @e['item']['meta'] && @item['meta']
			&& @e['item']['meta']['enchants'] == @item['meta']['enchants']) {
				if(@item['meta']['damage'] > @e['item']['meta']['damage']) {
					set_pinv(player(), @slot, @e['item']);
				} else if(@item['meta'] && @item['meta']['lore'] && array_size(@item['meta']['lore']) == 3
				&& @e['item']['meta'] && @e['item']['meta']['lore'] && array_size(@e['item']['meta']['lore']) == 3) {
					// might be ammo count, try to combine
					try {
						@currentAmmo = integer(@item['meta']['lore'][0]);
						@maxAmmo = integer(@item['meta']['lore'][1]);
						@newAmmo = integer(@e['item']['meta']['lore'][0]) + integer(@e['item']['meta']['lore'][1]);
						@item['meta']['lore'][1] = min(integer(@item['meta']['lore'][2]), @maxAmmo + @newAmmo);
						set_pinv(player(), @slot, @item);
					} catch(CastException @ex) {
						// not numbers, skip
					}
				}
				modify_event('item', null);
				break();
			}
		}
	}
}