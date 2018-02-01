switch(@action) {
case 'load':
	bind(player_move, array('id': @player.'move'), array('player': @player, 'threshold': 2), @event) {
		play_sound(ploc(), array('sound': 'ENTITY_IRONGOLEM_STEP'));
	}
	
case 'powerup':
	set_phunger(@player, 2)
	set_peffect(@player, 22, 0, 15);
	
case 'unload':
	unbind(@player.'move');
}
