proc _7_start(@7) {
	@i = 0
	foreach(@player in array_keys(@7['players'])) {
		if(@i == array_size(@7['spawns'])) {
			@i = 0
		}
		set_ploc(@player, @7['spawns'][@i])
		set_pexp(@player, 100)
		set_pbed_location(@player, @7['lobby'])
		@i++
	}
	
	@countdown = array(3)
	@7['task'] = set_interval(1000, closure(){
		if(@countdown[0] > 0) {
			foreach(@player in array_keys(@7['players'])) {
				if(ponline(@player)) {
					play_sound(ploc(@player), array('sound': 'NOTE_PIANO', 'pitch': 1, 'volume': 2), @player)
					play_sound(ploc(@player), array('sound': 'NOTE_PIANO', 'pitch': 1.1, 'volume': 2), @player)
				}
			}
			@countdown[0] -= 1
		} else {
			foreach(@player in array_keys(@7['players'])) {
				if(ponline(@player)) {
					play_sound(ploc(@player), array('sound': 'NOTE_PIANO', 'pitch': 1, 'volume': 2), @player);
					play_sound(ploc(@player), array('sound': 'NOTE_PIANO', 'pitch': 1.5, 'volume': 2), @player);
					play_sound(ploc(@player), array('sound': 'NOTE_PIANO', 'pitch': 2, 'volume': 2), @player);
					set_pwalkspeed(@player, 0.2);
					set_peffect(@player, 8, 0, 0);
				}
			}
			clear_task()
			
			@7['task'] = set_interval(100, closure(){
				foreach(@player: @p in @7['players']) {
					if(!ponline(@player) 
					|| !array_contains(sk_current_regions(@player), '7_schematic')
					|| pinfo(@player, 5) <= 0) {
						_7_remove_player(@player, @7);
					} else {
						@p['time'] -= 0.10;
						
						@loc = ploc(@player);
						@loc['x'] = floor(@loc['x']);
						@loc['y'] = floor(@loc['y']);
						@loc['z'] = floor(@loc['z']);
					
						if(!is_null(@p['block'])
						&& (@p['block'][0] != @loc['x'] 
						|| @p['block'][2] != @loc['z']
						|| @p['block'][1] != @loc['y'])) {
							@pitch = 0;
							switch(get_block_at(@p['block'])) {
								case '16:0':
									@p['time'] += 0.10;
									@pitch = 0.62;
								case '15:0':
									@p['time'] += 0.15;
									@pitch = 0.7;
								case '73:0':
								case '74:0':
									@p['time'] += 0.20;
									@pitch = 0.8;
								case '21:0':
									@p['time'] += 0.25;
									@pitch = 0.95;
								case '14:0':
									@p['time'] += 0.35;
									@pitch = 1.05;
								case '56:0':
									@p['time'] += 0.50;
									@pitch = 1.25;
								case '129:0':
									@p['time'] += 0.65;
									@pitch = 1.4;
							}
							set_block_at(@p['block'], '0:0');
							if(@pitch) {
								play_sound(@p['block'], array('sound': 'ORB_PICKUP', 'pitch': @pitch), @player);
								@note = @p['block'][];
								@note[0] += 0.5;
								@note[1] += 0.5;
								@note[2] += 0.5;
								play_effect(@note, 'NOTE');
							}
							@p['block'] = null;
						}
						
						if(is_null(@p['block']) && entity_grounded(puuid(@player))) {
							@p['block'] = array(@loc['x'], @loc['y'], @loc['z'], 'custom');
						}
						
						@int = ceil(@p['time'])
						set_pscore('time', @player, @int, '7')
						set_pexp(@player, min(100, integer(100 * (@p['time'] / 7))))
						set_plevel(@player, @int)
						
						if(@p['time'] <= 0) {
							_7_remove_player(@player, @7);
						} else if(@p['time'] < 2) {
							play_sound(@loc, array('sound': 'NOTE_PIANO', 'pitch': 1.9), @player)
							play_sound(@loc, array('sound': 'NOTE_PIANO', 'pitch': 2))
						}
					}
				}
				if(array_size(@7['players']) <= 1) {
					if(array_size(@7['players']) == 1) {
						@winner = array_implode(array_keys(@7['players']));
						_worldmsg('custom', @winner.' wins with '.color('gold').round(@7['players'][@winner]['time'], 1).' Seconds to Live');
						set_timeout(3000, closure(){
							if(ponline(@winner)) {
								set_ploc(@winner, @7['lobby']);
							}
						})
					} else {
						_worldmsg('custom', color(6).'Everybody dies.');
					}
					set_timeout(7000, closure(){
						remove_scoreboard('7');
						_remove_activity('7');
					});
					@7['players'] = associative_array();
					@7['state'] = 0;
					clear_task();
				}
			})
		}
	})
}

proc _7_remove_player(@player, @7) {
	if(ponline(@player)) {
		if(pworld(@player) == 'custom') {
			if(array_contains(sk_current_regions(@player), '7')) {
				if(pinfo(@player, 5) > 0) {
					pkill(@player);
					explosion(ploc(@player), 4);
				}
				@timeleft = round(@7['players'][@player]['time'], 1);
				if(@timeleft <= 0) {
					_regionmsg('7', @player.' ran out of time.');
				} else {
					_regionmsg('7', @player.' blew up with '.color('gold').@timeleft.' seconds'.color('r').' left.');
				}
			} else {
				_regionmsg('7', @player.' left the game.');
			}

		} else {
			_regionmsg('7', @player.' left the game.');
			set_pscoreboard(@player);
		}
	}
	array_remove(@7['players'], @player);
}