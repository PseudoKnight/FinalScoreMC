switch(@action) {
	case 'load':
		set_pexp(@player, 99);
		set_pflight(@player, true);
		set_pflyspeed(@player, 0.08);
		bind('player_toggle_flight', array('id': @player.'bountyhunter'), array('player': @player, 'flying': true), @event,
			@gasSound = array('sound': 'BLOCK_FIRE_EXTINGUISH', 'pitch': 1.1),
			@hissSound = array('sound': 'ENTITY_CAT_HISS', 'volume': 0.3, 'pitch': 1.1),
			@smokeEffect = array('speed': 0.02, 'particleCount': 10, 'offsetX': 0.25, 'offsetY': 0.25, 'offsetZ': 0.25, 'distance': 64),
			@stallSound = array('sound': 'BLOCK_CHEST_CLOSE', 'pitch': 0.5),
			@deathSound = array('sound': 'ENTITY_BLAZE_DEATH', 'pitch': 2.0)
		) {
			if(pexp() == 0) {
				play_sound(ploc(), @gasSound);
				cancel();
				die();
			}
			@loc = ploc();
			@y = array(@loc['y']);

			play_sound(@loc, @gasSound);
			play_sound(@loc, @hissSound);
			play_effect(@loc, 'CLOUD', @smokeEffect);
			
			set_interval(100, 600, closure(){
				try {
					@loc = ploc();
					@xp = pexp();
					if(@xp == 0 || @loc['y'] <= @y[0] + 0.3) {
						clear_task();
						try(set_pflying(false));
						if(@xp == 0) {
							play_sound(@loc, @stallSound);
							play_sound(@loc, @deathSound);
						}
					} else {
						@y[0] = @loc['y'];
						@loc['y'] += 1.3;
						play_sound(@loc, @gasSound);
						play_sound(@loc, @hissSound);
						play_effect(@loc, 'CLOUD', @smokeEffect);
						set_pexp(max(0, @xp - 1));
					}
				} catch(PlayerOfflineException @ex) {
					clear_task();
				}
			});
		}
		
	case 'equip':
		set_pinv(@player, array(103: array('name': 'SKULL_ITEM', 'data': 3, 'meta': array('owner': 'Rigzlii'))));
		
	case 'powerup':
		set_pexp(@player, 99);
	
	case 'unload':
		unbind(@player.'bountyhunter');
		set_pflyspeed(@player, 0.1);

}
