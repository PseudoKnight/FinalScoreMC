#Warms up a tp with effects and configurable timer
proc _warmuptp(@player, @loc, @cleareffects = false, @force = false) {
	@length = 3.7;
	if(!_is_survival_world(pworld(@player))) {
		@length = 0.1;
	} else {
		set_peffect(@player, 'NAUSEA', 1, 7, true, false);
		play_sound(puuid(@player), array('sound': 'BLOCK_PORTAL_TRIGGER', 'category': 'PLAYERS', 'volume': 1, 'pitch': 1));
	}
	set_timeout(integer(@length * 1000), closure(){
		if(!ponline(@player)) {
			die();
		}
		@ploc = ploc(@player);
		set_ploc(@player, @loc);
		if(@force) { // Teleporting crossworlds can be innaccurate, this forces an accurate location
			set_ploc(@player, @loc);
		}
		if(@cleareffects) {
			clear_peffects(@player);
		}
		set_peffect(@player, 'LEVITATION', -1, 0.05, true, false); // do not sink into ground on tp
		set_peffect(@player, 'GLOWING', 0, 1, true, false);
		set_peffect(@player, 'BLINDNESS', 1, 2, true, false); // expanding fog
		@particle = array('particle': 'CLOUD', 'count': 25, 'speed': 0.05, 'xoffset': 0.34, 'yoffset': 0, 'zoffset': 0.34);
		spawn_particle(location_shift(@ploc, 'up', 1.9), @particle);
		spawn_particle(location_shift(@loc, 'up', 2.7), @particle);
		@sound = array('sound': 'ENTITY_GHAST_SHOOT', 'category': 'PLAYERS', 'volume': 2);
		play_sound(@ploc, @sound);
		play_sound(@loc, @sound);
	});
}

/*
	Returns true if the location is (mostly) safe for a player
*/
proc _is_safe_location(@loc) {
	if(get_block_info(location_shift(@loc, 'up', 2), 'occluding')
	&& get_block_info(location_shift(@loc, 'up'), 'occluding')) {
		return(false);
	}
	if(!get_block_info(@loc, 'solid') && get_block(@loc) != 'WATER') {
		if(!get_block_info(location_shift(@loc, 'down'), 'solid')) {
			return(false);
		}
	}
	return(true);
}
