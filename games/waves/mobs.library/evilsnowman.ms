proc _load_mob(@waves) {
	@waves['binds'][] = bind('entity_damage_player', null, array(damager: 'SNOWBALL'), @event, @waves) {
		@player = @event['player'];
		@damager = @event['data'];
		if(!array_contains(@waves['players'], @player)) {
			die();
		}
		@loc = location_shift(ploc(@player), 'up', 2);
		spawn_particle(@loc, array(particle: 'SNOWBALL', count: 20, xoffset: 0.5, yoffset: 1, zoffset: 0.5));
		play_sound(@loc, array(sound: 'BLOCK_SNOW_BREAK', pitch: 0.5));
		play_sound(@loc, array(sound: 'BLOCK_SNOW_BREAK', pitch: 1));
		play_sound(@loc, array(sound: 'BLOCK_SNOW_BREAK', pitch: 2));
		damage_entity(puuid(@player), 2);
	}
}

proc _unload_mob(@waves) {}
