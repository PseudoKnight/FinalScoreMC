switch(@action) {
	case 'load':
		set_pexp(@player, 99);
		set_pflight(@player, true);
		set_pflyspeed(@player, 0.08);
		bind('player_toggle_flight', array('id': @player.'bountyhunter'), array('player': @player, 'flying': true), @event) {
			@sound1 = array('sound': 'BLOCK_FIRE_EXTINGUISH');
			if(pexp() == 0) {
				play_sound(ploc(), @sound1);
				cancel();
				die();
			}
			@y = array(ploc()['y']);
			@sound2 = array('sound': 'ENTITY_CAT_HISS', 'volume': 0.3);
			@effect1 = array('speed': 0.02, 'particleCount': 10, 'offsetX': 0.25, 'offsetY': 0.25, 'offsetZ': 0.25);
			set_interval(100, 600, closure(){
				try {
					@loc = ploc();
					@xp = pexp();
					if(@xp == 0 || @loc['y'] <= @y[0] + 0.3) {
						clear_task();
						try(set_pflying(false));
						if(@xp == 0) {
							play_sound(@loc, array('sound': 'BLOCK_CHEST_CLOSE', 'pitch': 0.5));
							play_sound(@loc, array('sound': 'ENTITY_BLAZE_DEATH', 'pitch': 2.0));
						}
					} else {
						@y[0] = @loc['y'];
						@loc['y'] += 1.3;
						play_sound(@loc, @sound1);
						play_sound(@loc, @sound2);
						play_effect(@loc, 'CLOUD', @effect1);
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
