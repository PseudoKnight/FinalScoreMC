/*
	Shared menus can be refreshed sparingly when state changes occur.
	This should be called when a value changes that the menu view uses for its creation.
 */
proc _menu_refresh(@id) {
	if(@id == 'pvp') {
		// menu view depends on player count in minigames worldgroup
		@menuTemplate = import('menu.pvp');
		@joined = import('pvp.joined');
		@menu = @menuTemplate['menu'][];
		@slot = 0;
		foreach(@item in @menuTemplate['inv']) {
			@id = to_lower(substr(@item['meta']['display'], 2));
			if(array_contains(@joined, @id)) {
				@pvp = import('pvp'.@id);
				foreach(@p: @v in @pvp['players']) {
					if(!ponline(@p)) {
						array_remove(@pvp['players'], @p);
					}
				}
				if(@pvp['players']) {
					@item = @item[];
					if(@item['name'] == 'IRON_SWORD') {
						@item['name'] = 'DIAMOND_SWORD';
					} else if(@item['name'] == 'IRON_PICKAXE') {
						@item['name'] = 'DIAMOND_PICKAXE';
					} else if(@item['name'] == 'IRON_HELMET') {
						@item['name'] = 'DIAMOND_HELMET';
					} else if(@item['name'] == 'WHITE_BANNER') {
						@item['name'] = 'LIGHT_BLUE_BANNER';
					} else {
						@item['meta']['enchants'] = array(unbreaking: 1);
					}
				} else {
					array_remove_values(@joined, @id);
				}
			}
			@menu[@slot++] = @item;
		}
		delete_virtual_inventory(@menuTemplate['id']);
		create_virtual_inventory(@menuTemplate['id'], @menuTemplate['size'], @menuTemplate['title'], @menu);
	}
}
