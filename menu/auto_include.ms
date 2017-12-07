proc _menu_refresh_pvp() {
	@menuTemplate = import('menu.pvp');
	@menu = @menuTemplate['menu'][];
	@count = array_size(all_players('custom'));
	foreach(@slot: @item in @menuTemplate['inv']) {
		@min = integer(@item['meta']['lore'][0][2]);
		if(@min > @count) {
			@item = @item[];
			@item['name'] = 'BARRIER';
		} else if((@pvp = import('pvp'.to_lower(substr(@item['meta']['display'], 2)))) && @pvp['players']) {
			@item = @item[];
			@item['data'] = 10;
			@item['qty'] = array_size(@pvp['players']);
		}
		@menu[@slot] = @item;
	}
	create_virtualchest(@menu);
}
