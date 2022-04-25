proc _load_mob(@waves) {
	bind('entity_damage_player', array(id: 'waves'.@waves['region'].'evilsnowman'), array(damager: 'SNOWBALL'), @e, @waves) {
		@player = @e['player'];
		@damager = @e['data'];
		if(!array_contains(@waves['players'], @player)) {
			die();
		}
		@loc = location_shift(ploc(@player), 'up', 2);
		spawn_particle(@loc, array(particle: 'SNOWBALL', count: 20, xoffset: 0.5, yoffset: 1, zoffset: 0.5));
		play_sound(@loc, array(sound: 'ENTITY_LLAMA_SPIT', pitch: 0.5));
		damage_entity(puuid(@player), 2);
	}
}

proc _unload_mob(@waves) {
	unbind('waves'.@waves['region'].'evilsnowman');
}
