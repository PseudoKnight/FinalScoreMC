bind('inventory_click', null, array('virtual': true), @event) {
	cancel();
	@lore = _item_meta(@event['slotitem'], 'lore');
	if(@lore) {
		@action = split(': ', @lore[-1]);
		if(array_size(@action) != 2) {
			die();
		}
		@value = @action[1];
		switch(substr(@action[0], 2)) {
			case 'Open':
				try {
					popen_inventory(@value);
				} catch(IllegalArgumentException @ex) {
					_menu_refresh(@value);
					popen_inventory(@value);
				}
				play_sound(ploc(), array('sound': 'UI_BUTTON_CLICK', 'pitch': 1.2), player());
			case 'Load':
				@menu = import('menu.'.@value);
				if(@menu) {
					execute(player(), @menu, @menu['loadMenu']);
					play_sound(ploc(), array('sound': 'UI_BUTTON_CLICK', 'pitch': 1.2), player());
				}
			case 'Run':
				console(@event['player'].' clicked: '.@value, false);
				run_cmd(@value);
				close_pinv();
		}
	}
}

bind('player_interact_at_entity', array('priority': 'HIGH'), array('clicked': 'ARMOR_STAND'), @event) {
	if(pmode() == 'ADVENTURE' && string_starts_with(get_mob_name(@event['id']), color('green'))) {
		@equipment = get_mob_equipment(@event['id']);
		if(@equipment['helmet'] && @equipment['helmet']['meta']) {
			run_cmd(@equipment['helmet']['meta']['display']);
			consume();
		}
	}
}

bind('player_interact', null, array(itemname: 'KNOWLEDGE_BOOK', button: 'right', hand: 'main_hand'), @event) {
	if(pworld() == 'custom') {
		@display = _item_meta(pinv(player(), null), 'display');
		if(@display == 'Park Directory') {
			cancel();
			popen_inventory('main');
			play_sound(ploc(), array('sound': 'BLOCK_WOOL_STEP', 'pitch': 1.2), player());
		}
	}
}