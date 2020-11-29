proc _menu_refresh_pvp() {
	@menuTemplate = import('menu.pvp');
	@menu = @menuTemplate['menu'][];
	@slot = 0;
	foreach(@item in @menuTemplate['inv']) {
		@pvp = import('pvp'.to_lower(substr(@item['meta']['display'], 2)));
		if(@pvp && @pvp['players']) {
			foreach(@p: @v in @pvp['players']) {
				if(!ponline(@p) || pworld(@p) != @pvp['arena']['lobby'][3]) {
					array_remove(@pvp['players'], @p);
				}
			}
			if(@pvp['players']) {
				@item = @item[];
				@item['name'] = 'DIAMOND_SWORD';
			}
		}
		@menu[@slot++] = @item;
	}
	delete_virtual_inventory(@menuTemplate['id']);
	create_virtual_inventory(@menuTemplate['id'], 36, @menuTemplate['title'], @menu);
}
