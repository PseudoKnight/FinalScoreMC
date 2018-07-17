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
				popen_inventory(@value);
				play_sound(ploc(), array('sound': 'CLICK', 'pitch': 1.2), player());
			case 'Load':
				@menu = import('menu.'.@value);
				if(@menu) {
					execute(player(), @menu, @menu['loadMenu']);
					popen_inventory(@value);
					play_sound(ploc(), array('sound': 'CLICK', 'pitch': 1.2), player());
				}
			case 'Run':
				run_cmd(@value);
				close_pinv();
		}
	}
}

bind('player_interact_at_entity', array('priority': 'HIGH'), array('clicked': 'ARMOR_STAND'), @event) {
	if(pmode() != 'CREATIVE' && get_mob_name(@event['id']) == color('green').'Start') {
		@equipment = get_mob_equipment(@event['id']);
		if(@equipment['helmet'] && @equipment['helmet']['meta']) {
			run_cmd(@equipment['helmet']['meta']['display']);
		}
	}
}
