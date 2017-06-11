proc _snake_menu() {
	if(array_contains(all_virtualchests(), 'snake')) {
		die('Already running.');
	}
	create_virtualchest(array(
		'id': 'snake',
		'type': 'HOPPER',
		'title': color('bold').'Choose a Mode',
		'1': array('name': 'REDSTONE_BLOCK', 'meta': array('display': color('red').color('bold').'ELIMINATION MODE')),
		'3': array('name': 'WATCH', 'meta': array('display': color('yellow').color('bold').'ENDLESS MODE')),
	));
	popen_virtualchest('snake');
	bind(inventory_click, array('id': 'snake-invclick'), null, @event) {
		if(pget_virtualchest() == 'snake') {
			@item = @event['slotitem'];
			if(@item) {
				close_pinv();
				include('game.ms');
				if(@event['slot'] == 1) {
					_snake_queue('standard');
				} else if(@event['slot'] == 3) {
					_snake_queue('endless');
				}
			}
		}
	}
	bind(inventory_close, null, null, @event) {
		if(pget_virtualchest() == 'snake') {
			unbind();
			unbind('snake-invclick');
			del_virtualchest('snake');
		}
	}
}