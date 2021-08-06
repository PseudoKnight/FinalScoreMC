@pvp['binds'][] = bind('entity_damage_player', null, null, @event, @pvp) {
	if(array_index_exists(@pvp['players'], player())) {
		@health = phealth();
		set_timeout(10, closure(){
			@modifier = (entity_attribute_base(puuid(), 'GENERIC_MAX_HEALTH') + 5 - @health) / 5;
			@v = pvelocity();
			@v['x'] *= @modifier;
			@v['y'] *= @modifier;
			@v['z'] *= @modifier;
			set_pvelocity(@v);
			if(@v['y'] > 0.1 && @modifier > 3) {
				@particle = array(
					particle: 'FLAME',
					count: 5,
					speed: 0.03,
					xoffset: 0.7,
					yoffset: 0.7,
					zoffset: 0.7,
				);
				@count = 8;
				while(@count-- > 0) {
					queue_push(closure(){
						spawn_particle(entity_loc(puuid()), @particle);
					}, player().'knockbackeffects');
				}
			}
		});
	}
}

@pvp['binds'][] = bind('entity_damage', null, array(cause: 'FALL', type: 'PLAYER'), @event, @pvp) {
	if(array_index_exists(@pvp['players'], player(@event['id']))) {
		modify_event('amount', 0);
	}
}