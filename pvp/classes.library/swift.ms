switch(@action) {
case 'load':
	@glideState = array(false);
	set_interval(150, closure(){
		try {
			if(pinfo(@player, 5) == 0
			|| !array_index_exists(@pvp['players'], @player)
			|| @pvp['players'][@player]['class'] != 'swift') {
				clear_task();
				die();
			}
			@xp = pexp(@player);
			if(@glideState[0] && @xp > 1) {
				set_pexp(@player, @xp - 2);
			} else if(@glideState[0]) {
				@glideState[0] = false;
				set_entity_gliding(puuid(@player), false);
			} else if(@xp < 98) {
				set_pexp(@player, @xp + 2);
			}
		} catch(Exception @ex) {
			clear_task();
		}
	});
	
	bind(entity_toggle_glide, array('id': @player.'glide'), array('type': 'PLAYER', 'player': @player), @e, @glideState, @player) {
		if(@player != @e['player']) {
			die();
		}
		if(@e['gliding']) {
			@glideState[0] = true;
		} else if(@glideState[0]) {
			cancel();
		}
	}

	bind(player_toggle_sneak, array('id': @player.'sneak'), array('sneaking': true), @e, @player, @glideState) {
		if(player() == @player) {
			@glideState[0] = false;
			set_entity_gliding(puuid(), false);
		}
	}

case 'unload':
	unbind(@player.'sneak');
	unbind(@player.'glide');

}
