proc _snake_menu() {
	create_virtual_inventory('snake', 'HOPPER', color('bold').'Choose a Mode', array(
		array(name: 'CLOCK', meta: array(
			display: color('yellow').color('bold').'ENDLESS MODE',
			lore: array(
				color('white').'Bots respawn and retain powerups.',
				color('white').'Survive as long as you can.',
				color('gray').'RECORDS: /snake top endless',
			)
		)),
		array(name: 'NETHERITE_SWORD', meta: array(
			display: color('white').color('bold').'ELIMINATION MODE',
			lore: array(
				color('white').'Win a round by being the last snake slithering.',
				color('white').'Win the game by winning two rounds.',
			),
		)),
		array(name: 'BLUE_GLAZED_TERRACOTTA', meta: array(
			display: color('blue').color('bold').'CAPTURE MODE',
			lore: array(
				color('white').'Capture and return the enemy block.',
				color('white').'First team to three captures wins.',
			)
		)),
		array(name: 'COMPOSTER', meta: array(
			display: color('green').color('bold').'PIT MODE (Experimental)',
			lore: array(
				color('white').'Cooperative defense of the bottom panel against bots.',
				color('white').'Similar to Endless Mode except you only get points',
				color('white').'when you have exclusive control of your panel.',
			)
		)),
	));
	popen_inventory('snake');
	bind('inventory_click', array(id: 'snake-invclick'), array(player: player()), @event) {
		@item = @event['slotitem'];
		if(@item) {
			close_pinv();
			include('game.ms');
			try {
				@modes = array(
					0: 'endless',
					1: 'elimination',
					2: 'capture',
					3: 'pit',
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
			}
		}
	}
	bind('inventory_close', null, null, @event) {
		if(@event['holder'] === 'snake') {
			unbind();
			unbind('snake-invclick');
			delete_virtual_inventory('snake');
		}
	}
}
