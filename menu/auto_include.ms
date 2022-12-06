/*
	Shared menus can be refreshed sparingly when state changes occur.
	This should be called when a value changes that the menu view uses for its creation.
 */
proc _menu_refresh(@id) {
	switch(@id) {
		// menu view depends on player count in minigames worldgroup
		case 'pvp':
			@menuTemplate = import('menu.pvp');
			@menu = @menuTemplate['menu'][];
			@slot = 0;
			foreach(@item in @menuTemplate['inv']) {
				@pvp = import('pvp'.to_lower(substr(@item['meta']['display'], 2)));
				if(@pvp && @pvp['players']) {
					foreach(@p: @v in @pvp['players']) {
						if(!ponline(@p) || _world_group(pworld(@p)) != 'minigames') {
							array_remove(@pvp['players'], @p);
						}
					}
					if(@pvp['players']) {
						@item = @item[];
						if(@item['name'] == 'IRON_SWORD') {
							@item['name'] = 'DIAMOND_SWORD';
						} else if(@item['name'] == 'IRON_HELMET') {
							@item['name'] = 'DIAMOND_HELMET';
						} else if(@item['name'] == 'WHITE_BANNER') {
							@item['name'] = 'LIGHT_BLUE_BANNER';
						} else {
							@item['meta']['enchants'] = array(unbreaking: 1);
						}
					}
				}
				@menu[@slot++] = @item;
			}
			delete_virtual_inventory(@menuTemplate['id']);
			create_virtual_inventory(@menuTemplate['id'], @menuTemplate['size'], @menuTemplate['title'], @menu);
	}
}
