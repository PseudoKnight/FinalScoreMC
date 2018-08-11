switch(@action) {
case 'load':
	@glideState = array(false);
	set_interval(100, closure(){
		try {
			if(pmode(@player) == 'SPECTATOR'
			|| !array_index_exists(@pvp['players'], @player)
			|| @pvp['players'][@player]['class'] != 'swift') {
				clear_task();
				die();
			}
			@xp = pexp(@player);
			if(@glideState[0] && @xp > 1) {
				set_pexp(@player, @xp - 1);
			} else if(@glideState[0]) {
				@glideState[0] = false;
				set_entity_gliding(puuid(@player), false);
				set_entity_fall_distance(puuid(), 0);
			} else if(@xp < 99) {
				set_pexp(@player, @xp + 1);
			}
		} catch(Exception @ex) {
			clear_task();
		}
	});
	
	bind('entity_toggle_glide', array('id': @player.'glide'), array('type': 'PLAYER', 'player': @player), @e, @glideState) {
		if(@e['gliding']) {
			@glideState[0] = true;
		} else if(@glideState[0]) {
			cancel();
		}
	}

	bind('player_toggle_sneak', array('id': @player.'sneak'), array('sneaking': true), @e, @player, @glideState) {
		if(player() == @player) {
			@glideState[0] = false;
			set_entity_gliding(puuid(), false);
			set_entity_fall_distance(puuid(), 0);
			play_sound(ploc(), array('sound': 'ENTITY_ENDER_DRAGON_FLAP', 'category': 'PLAYERS', 'pitch': 1.3, 'volume': 0.4));
		}
	}
	
	bind('player_interact', array('id': @player.'boost'), array('player': @player, 'button': 'right', 'item': 271), @e) {
		if(!pcooldown('WOOD_AXE')) {
			set_pvelocity(player(), get_vector(ploc(), 0.6));
			set_pcooldown('WOOD_AXE', 4000 / 50);
			play_sound(ploc(), array('sound': 'ENTITY_ENDER_DRAGON_FLAP', 'category': 'PLAYERS', 'pitch': 1.3, 'volume': 0.4));
		}
	}
	
case 'powerup':
	set_pexp(@player, min(99, pexp(@player) + 33));

case 'unload':
	unbind(@player.'sneak');
	unbind(@player.'glide');
	unbind(@player.'boost');

}
