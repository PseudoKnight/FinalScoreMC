proc _snake_menu() {
	if(array_contains(all_virtualchests(), 'snake')
	|| array_contains(get_scoreboards(), 'snake')) {
		die('Already running.');
	}
	create_virtualchest(array(
		'id': 'snake',
		'type': 'HOPPER',
		'title': color('bold').'Choose a Mode',
		'1': array('name': 'REDSTONE_BLOCK', 'meta': array(
			'display': color('red').color('bold').'ELIMINATION MODE',
			'lore': color('white').'Be the last snake slithering.',
		)),
		'3': array('name': 'WATCH', 'meta': array(
			'display': color('yellow').color('bold').'ENDLESS MODE',
			'lore': array(
				color('white').'Bots respawn and retain powerups.',
				color('white').'Survive as long as you can.',
			)
		)),
	));
	popen_virtualchest('snake');
	bind(inventory_click, array('id': 'snake-invclick'), null, @event) {
		if(pget_virtualchest() == 'snake') {
			@item = @event['slotitem'];
			if(@item) {
				close_pinv();
				try {
					include('game.ms');
					if(@event['slot'] == 1) {
						_snake_queue('standard');
					} else if(@event['slot'] == 3) {
						_snake_queue('endless');
					}
				} catch(Exception @ex) {
					console(@ex['classType'].': '.@ex['message'], false);
					foreach(@trace in @ex['stackTrace']) {
						console(split('LocalPackages', @trace['file'])[-1].':'.@trace['line'].' '.@trace['id'], false);
					}
					msg(color('red').@ex['message']);
					msg(color('yellow').'Cleaning up game...');
					_snake_cleanup(import('snake'));
					return(true);
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
