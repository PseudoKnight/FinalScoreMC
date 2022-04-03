proc _class_load(@player, @pvp) {
	bind('player_move', array(id: @player.'move'), array(player: @player, threshold: 2), @event) {
		if(entity_grounded(puuid())) {
			play_sound(ploc(), array(sound: 'ENTITY_IRON_GOLEM_STEP'));
		}
	}
}
	
proc _class_powerup(@player) {
	set_phunger(@player, 2);
	set_peffect(@player, 'ABSORPTION', 0, 15);
}

proc _class_unload(@player, @pvp) {
	unbind(@player.'move');
}
