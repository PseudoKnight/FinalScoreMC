proc _menu_refresh_pvp() {
	@menuTemplate = import('menu.pvp');
	@menu = @menuTemplate['menu'][];
	@count = array_size(all_players('custom'));
	foreach(@slot: @item in @menuTemplate['inv']) {
		@min = integer(@item['meta']['lore'][0][2]);
		if(@min > @count) {
			@item = @item[];
			@item['name'] = 'BARRIER';
		} else {
			@pvp = import('pvp'.to_lower(substr(@item['meta']['display'], 2)));
			if(@pvp && @pvp['players']) {
				foreach(@p: @v in @pvp['players']) {
					if(!ponline(@p)) {
						array_remove(@pvp['players'], @p);
					}
				}
				if(@pvp['players']) {
					@item = @item[];
					@item['name'] = 'LIME_DYE';
					@item['qty'] = array_size(@pvp['players']);
				}
			}
		}
		@menu[@slot] = @item;
	}
	delete_virtual_inventory(@menuTemplate['id']);
	create_virtual_inventory(@menuTemplate['id'], 63, @menuTemplate['title'], @menu);
}
