if(extension_exists('chvirtualchests')) {
queue_push(closure(){
	include('includes.library/menu.ms');
	_repopulate_menu();

	bind(player_interact, null, array('item': 340, 'button': 'right'), @event) {
		if(pworld() === 'custom') {
			@item = pinv(player(), null);
			if(!is_null(@item) # sometimes an earlier event handler will remove the item
			&& !is_null(@item['meta'])
			&& @item['meta']['display'] === 'Park Directory') {
				cancel();
				popen_virtualchest('main');
				play_sound(ploc(), array('sound': 'STEP_WOOL', 'pitch': 1.2), player());
			}
		}
	}

	bind(inventory_click, null, null, @e) {
		if(is_null(pget_virtualchest())) {
			die();
		}
		cancel();
		@lore = _item_meta(@e['slotitem'], 'lore');
		if(@lore) {
			@action = split(': ', to_lower(strip_colors(@lore[-1])));
			switch(@action[0]) {
			case 'open':
				popen_virtualchest(@action[1]);
				play_sound(ploc(), array('sound': 'CLICK', 'pitch': 1.2), player());
			case 'run':
				run_cmd(@action[1]);
				close_pinv();
			}
		}
	}

	bind(inventory_drag, null, null, @e) {
		if(!is_null(pget_virtualchest())) {
			cancel();
		}
	}
});
}
