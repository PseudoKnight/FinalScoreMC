@pvp['binds'][] = bind('entity_damage_player', null, null, @event, @pvp) {
	if(array_index_exists(@pvp['players'], player())) {
		@health = phealth();
		@v = get_vector(ploc(@event['id']));
		@sprint = false;
		if(psprinting(@event['id'])) {
			@sprint = true;
		}
		set_timeout(10, closure(){
			if(pmode() == 'SPECTATOR') {
				return();
			}
			@modifier = (entity_attribute_base(puuid(), 'GENERIC_MAX_HEALTH') + 5 - @health) / 10;
			@sprint = false;
			if(@sprint) {
				@modifier *= 2.5;
			}
			@v['x'] *= @modifier;
			@v['y'] *= @modifier;
			@v['z'] *= @modifier;
			@crit = false;
			if(@event['finalamount'] > 1) {
				play_sound(@event['location'], array(sound: 'ENTITY_PIG_DEATH'));
				@v['x'] = 0;
				@v['y'] = 1;
				@v['z'] = 0;
				@crit = true;
			} else {
				@v['y'] += 0.3;
			}
			set_pvelocity(@v);
			if(@sprint || @crit) {
				play_sound(@event['location'], array(sound: 'BLOCK_NOTE_BLOCK_BASEDRUM'));
				play_sound(@event['location'], array(sound: 'ENTITY_ENDER_DRAGON_SHOOT'));
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