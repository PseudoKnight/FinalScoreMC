switch(@action) {
case 'load':
	@glideState = array(false);
	bind(entity_toggle_glide, array('id': @player.'glide'), array('type': 'PLAYER', 'player': @player), @e, @glideState) {
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
