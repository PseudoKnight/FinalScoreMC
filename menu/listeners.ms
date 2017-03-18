bind(inventory_click, null, null, @event) {
	if(pget_virtualchest()) {
		cancel();
		@lore = _item_meta(@event['slotitem'], 'lore');
		if(@lore) {
			@action = split(': ', @lore[-1]);
			switch(substr(@action[0], 2)) {
				case 'Open':
					popen_virtualchest(@action[1]);
					play_sound(ploc(), array('sound': 'CLICK', 'pitch': 1.2), player());
				case 'Run':
					run_cmd(@action[1]);
					close_pinv();
			}
		}
	}
}
