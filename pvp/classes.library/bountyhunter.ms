switch(@action) {
	case 'load':
		set_pexp(@player, 99);
		set_pflight(@player, true);
		bind('player_toggle_flight', array('id': @player.'bountyhunter'), array('player': @player, 'flying': true), @event) {
			@y = array(ploc()['y']);
			@sound1 = array('sound': 'BLOCK_FIRE_EXTINGUISH');
			@sound2 = array('sound': 'ENTITY_CAT_HISS', 'volume': 0.5);
			@effect1 = array('speed': 0.05, 'particleCount': 5, 'offsetX': 0.1, 'offsetY': 0.1, 'offsetZ': 0.1);
			@effect2 = array('speed': 0.08, 'particleCount': 10, 'offsetX': 0.4, 'offsetY': 0.4, 'offsetZ': 0.4);
			@effect3 = array('id': 4);
			set_interval(100, 600, closure(){
				try {
					@loc = ploc();
					@xp = pexp();
					if(@xp == 0 || @loc['y'] <= @y[0] + 0.3) {
						set_pflying(false);
						clear_task();
						if(@xp == 0) {
							play_sound(@loc, array('sound': 'BLOCK_CHEST_CLOSE', 'pitch': 0.5));
							play_sound(@loc, array('sound': 'ENTITY_BLAZE_DEATH', 'pitch': 2.0));
						}
					} else {
						@y[0] = @loc['y'];
						play_sound(@loc, @sound1);
						play_sound(@loc, @sound2);
						play_effect(@loc, 'FLAME', @effect1);
						play_effect(@loc, 'CLOUD', @effect2);
						play_effect(@loc, 'SMOKE', @effect3);
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

}
