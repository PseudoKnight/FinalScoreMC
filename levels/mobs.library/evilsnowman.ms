proc _load_mob(@level) {
	bind('entity_damage_player', array('id': 'level'.@level['region'].'evilsnowman'), array('damager': 'SNOWBALL'), @e, @level) {
		@player = @e['player'];
		@damager = @e['data'];
		if(!array_contains(@level['players'], @player)) {
			die();
		}
		@loc = location_shift(ploc(@player), 'up', 2);
		spawn_particle(@loc, array('particle': 'SNOWBALL', 'count': 20, 'xoffset': 0.5, 'yoffset': 1, 'zoffset': 0.5));
		play_sound(@loc, array('sound': 'ENTITY_LLAMA_SPIT', 'pitch': 0.5));
		damage_entity(puuid(@player), 2);
	}
}

proc _unload_mob(@level) {
	unbind('level'.@level['region'].'evilsnowman');
}
