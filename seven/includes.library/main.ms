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
						if(_7_remove_player(@player, @7)) {
							clear_task()
							break()
						}
					} else {
					
						if(!is_null(@p['queue'])) {
							set_block_at(@p['queue'], 0);
							@p['queue'] = null;
						}
					
						@p['time'] -= 0.1;
						@loc = ploc(@player);
						
						if(entity_grounded(pinfo(@player, 13))) {
							@block = get_block_at(@loc)
							switch(@block) {
							case '16:0':
								@p['time'] += 0.15;
								play_sound(@loc, array('sound': 'ORB_PICKUP', 'pitch': 0.62), @player)
							case '15:0':
								@p['time'] += 0.18;
								play_sound(@loc, array('sound': 'ORB_PICKUP', 'pitch': 0.7), @player)
							case '73:0':
							case '74:0':
								@p['time'] += 0.23;
								play_sound(@loc, array('sound': 'ORB_PICKUP', 'pitch': 0.8), @player)
							case '21:0':
								@p['time'] += 0.28;
								play_sound(@loc, array('sound': 'ORB_PICKUP', 'pitch': 0.95), @player)
							case '14:0':
								@p['time'] += 0.33;
								play_sound(@loc, array('sound': 'ORB_PICKUP', 'pitch': 1.05), @player)
							case '56:0':
								@p['time'] += 0.38;
								play_sound(@loc, array('sound': 'ORB_PICKUP', 'pitch': 1.25), @player)
							case '129:0':
								@p['time'] += 0.43;
								play_sound(@loc, array('sound': 'ORB_PICKUP', 'pitch': 1.4), @player)
							}

							if(@block != '0:0') {
								@p['queue'] = @loc;
							}
						}
						
						@int = ceil(@p['time'])
						set_pscore('time', @player, @int, '7')
						set_pexp(@player, min(100, integer(100 * (@p['time'] / 7))))
						set_plevel(@player, @int)
						
						if(@p['time'] <= 0) {
							if(_7_remove_player(@player, @7)) {
								clear_task()
								break()
							}
						} else if(@p['time'] < 2) {
							play_sound(@loc, array('sound': 'NOTE_PIANO', 'pitch': 1.9), @player)
							play_sound(@loc, array('sound': 'NOTE_PIANO', 'pitch': 2))
						}
					}
				}
			})
		}
	})
}

proc _7_remove_player(@player, @7) {
	if(ponline(@player)) {
		if(pworld(@player) == 'custom' && pinfo(@player, 5) > 0) {
			pkill(@player)
			explosion(ploc(@player), 3)
			@timeleft = round(@7['players'][@player]['time'], 1);
			if(@timeleft <= 0) {
				_regionmsg('7', @player.' ran out of time.')
			} else {
				_regionmsg('7', @player.' blew up with '.color('gold').@timeleft.' seconds'.color('r').' left.')
			}
		}
		set_pscoreboard(@player)
	}
	array_remove(@7['players'], @player)
	if(array_size(@7['players']) <= 1) {
		if(array_size(@7['players']) == 1) {
			@winner = array_implode(array_keys(@7['players']))
			_worldmsg('custom', @winner.' wins with '.color('gold').round(@7['players'][@winner]['time'], 1).' Seconds to Live')
			set_timeout(3000, closure(){
				if(ponline(@winner)) {
					set_ploc(@winner, @7['lobby'])
				}
			})
		} else {
			_worldmsg('custom', colorize('&6Spoiler alert:&r Everybody dies.'))
		}
		set_timeout(7000, closure(){
			remove_scoreboard('7')
		})
		@7['players'] = array()
		@7['state'] = 0
		export('currently', null)
		return(true)
	}
	return(false)
}