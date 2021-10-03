switch(@action) {
case 'load':
	bind('player_move', array(id: @player.'move'), array(player: @player, threshold: 2), @event) {
		if(entity_grounded(puuid())) {
			play_sound(ploc(), array(sound: 'ENTITY_IRON_GOLEM_STEP'));
		}
	}
	
case 'powerup':
	set_phunger(@player, 2);
	set_peffect(@player, 'ABSORPTION', 0, 15);
	
case 'unload':
	unbind(@player.'move');
}
