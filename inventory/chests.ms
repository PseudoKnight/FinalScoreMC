// Open inventories without having to place them.
// While a convenience, this also helps players who are in protected regions where they cannot place blocks.
bind('inventory_click', null, array('clicktype': 'SHIFT_RIGHT'), @event) {
	if(!@event['slotitem'] || !_is_survival_world(pworld())) {
		die();
	}
	switch(@event['slotitem']['name']) {
		case 'CRAFTING_TABLE':
			cancel();
			pworkbench();
		case 'ENDER_CHEST':
			cancel();
			play_sound(ploc(), array('sound': 'BLOCK_ENDER_CHEST_OPEN'));
			set_timeout(10, closure(){
				show_enderchest();
			});
	}
}

// Open an ender chest or crafting table if they cannot place one
bind('block_place', null, array(block: 'ENDER_CHEST'), @event) {
	if(_is_survival_world(pworld()) && !sk_can_build(@event['location'])) {
		play_sound(ploc(), array('sound': 'BLOCK_ENDER_CHEST_OPEN'));
		show_enderchest();
	}
}
bind('block_place', null, array(block: 'CRAFTING_TABLE'), @event) {
	if(_is_survival_world(pworld()) && !sk_can_build(@event['location'])) {
		pworkbench();
	}
}
