proc _snake_menu() {
	create_virtual_inventory('snake', 'HOPPER', color('bold').'Choose a Mode', array(
		'0': array(name: 'IRON_SWORD', meta: array(
			display: color('white').color('bold').'ELIMINATION MODE',
			lore: array(
				color('white').'Win a round by being the last snake slithering.',
				color('white').'Win the game by winning two rounds.',
			),
		)),
		'1': array(name: 'DIAMOND_SWORD', meta: array(
			display: color('aqua').color('bold').'VERSUS MODE',
			lore: array(
				color('white').'Like elimination, but with no bots.',
				color('white').'Win a round by being the last snake slithering.',
				color('white').'Win the game by winning three rounds.',
			)
		)),
		'2': array(name: 'CLOCK', meta: array(
			display: color('yellow').color('bold').'ENDLESS MODE',
			lore: array(
				color('white').'Bots respawn and retain powerups.',
				color('white').'Survive as long as you can.',
			)
		)),
		'3': array(name: 'BLUE_GLAZED_TERRACOTTA', meta: array(
			display: color('blue').color('bold').'CAPTURE MODE',
			lore: array(
				color('white').'Capture and return the enemy block.',
				color('white').'First team to three captures wins.',
			)
		)),
		'4': array(name: 'REDSTONE_BLOCK', meta: array(
			display: color('red').color('bold').'GLUTTONY MODE',
			lore: array(
				color('white').'Just regular snake.',
			)
		)),
	));
	popen_inventory('snake');
	bind('inventory_click', array('id': 'snake-invclick'), array('player': player()), @event) {
		@item = @event['slotitem'];
		if(@item) {
			close_pinv();
			include('game.ms');
			try {
				@modes = array(
					0: 'elimination',
					1: 'versus',
					2: 'endless',
					3: 'capture',
					4: 'gluttony',
				);
				_snake_queue(array_get(@modes, @event['slot'], 'secret'));
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
	bind('inventory_close', null, null, @event) {
		if(@event['holder'] == 'snake') {
			unbind();
			unbind('snake-invclick');
			delete_virtual_inventory('snake');
		}
	}
}
