@blockedworlds = array('outworld', 'outworld_nether', 'outworld_the_end', 'lastmanstanding');

#Warms up a tp with effects and configurable timer
proc _warmuptp(@player, @loc, @cleareffects = false) {
	@length = 3.7;
	if(pmode(@player) == 'CREATIVE') {
		@length = 0.1;
	} else {
		set_peffect(@player, 9, 1, 7, true, false);
		play_sound(ploc(@player), array('sound': 'PORTAL_TRIGGER', 'volume': 1, 'pitch': 1));
	}
	set_timeout(round(@length * 1000), closure(){
		if(!ponline(@player)) {
			die();
		}
		@ploc = ploc(@player);
		set_peffect(@player, 15, 1, 2, true, false);
		set_ploc(@player, @loc);
		set_peffect(@player, 15, 1, 2, true, false);
		play_effect(_relative(@ploc, 'up', 2), 'CLOUD', array('particleCount': 25, 'speed': 0.01, 'offsetX': 0.3, 'offsetY': 0.6, 'offsetZ': 0.3));
		play_effect(_relative(@loc, 'up', 2), 'CLOUD', array('particleCount': 25, 'speed': 0.01, 'offsetX': 0.3, 'offsetY': 0.6, 'offsetZ': 0.3));
		play_sound(@ploc, array('sound': 'GHAST_FIREBALL', 'volume': 2));
		play_sound(@loc, array('sound': 'GHAST_FIREBALL', 'volume': 2));
		if(@cleareffects) {
			_clear_peffects(@player);
		}
	})
}

/*
	Returns true if the location is (mostly) safe for a player
*/
proc _is_safe_location(@loc) {
	if(get_block_info(_relative(@loc, 'up', 2), 'occluding')) {
		return(false);
	}
	if(!get_block_info(@loc, 'solid')) {
		if(get_block_info(_relative(@loc, 'up'), 'occluding')) {
			return(false);
		}
		if(!get_block_info(_relative(@loc, 'down'), 'solid')) {
			return(false);
		}
	}
	return(true);
}
