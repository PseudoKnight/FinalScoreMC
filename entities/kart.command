register_command('kart', array(
	description: 'Spawns a temporary kart.',
	usage: '/kart',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	permission: 'command.kart',
	executor: closure(@alias, @sender, @args, @info) {
		if(_psession()['activity']) {
			die('You are busy doing something.');
		}
		include('custom.library/kart.ms');
		@loc = entity_loc(puuid());
		@loc['pitch'] = 0;
		@kart = _kart_spawn(@loc, player());
		@mode = pmode();
		set_pmode('ADVENTURE');
		set_phealth(20.0);
		set_phunger(20);
		bind('player_command', array(id: player().'kartcommand'), array(player: player()), @event, @kart, @mode) {
			if(array_contains(array('/accept', '/warp', '/spawn', '/home', '/join', '/dev', '/park', '/survival', '/tpa', '/kart'), @event['prefix'])) {
				unbind();
				unbind(player().'kartquit');
				unbind(player().'kartdismount');
				unbind(player().'kartdismount2');
				@kart['explode'] = true;
				if(@event['prefix'] === '/kart') {
					set_pmode(@mode);
					cancel();
				}
			}
		}
		bind('player_quit', array(id: player().'kartquit'), array(player: player()), @event, @kart) {
			unbind();
			unbind(player().'kartcommand');
			unbind(player().'kartdismount');
			unbind(player().'kartdismount2');
			_kart_remove(player(), @kart);
		}
		bind('entity_dismount', array(id: player().'kartdismount2'), array(type: 'ARMOR_STAND'), @event, @kart) {
			if(@event['mountid'] === @kart['base']) {
				unbind();
				unbind(player().'kartcommand');
				unbind(player().'kartquit');
				unbind(player().'kartdismount');
			}
		}
		bind('entity_dismount', array(id: player().'kartdismount'), array(type: 'PLAYER'), @event, @player = player(), @kart) {
			try {
				if(player(@event['id']) === @player) {
					@kart['drift'] = 2;
					cancel();
				}
			} catch(PlayerOfflineException @ex) {
				// entity was not a player
			}
		}
		_kart_tick(player(), @kart);
	}
));
