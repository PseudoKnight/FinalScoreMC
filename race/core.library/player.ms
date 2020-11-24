proc _race_add_player(@id, @player) {
	@race = import('race'.@id);
	@race['players'][@player] = array(
		'lap': 0,
		'checkpoint': 0,
		'state': 'racing',
		'place': 0,
		'loc': @race['spawn'][0],
		'horn': time(),
		'stands': array(),
	);
	set_pscoreboard(@player, @id);
	set_pscore('time', @player, 0, @id);
	team_add_player('collision', @player, @id);
}

proc _race_remove_player(@race, @player) {
	array_remove(@race['players'], @player);
	_set_pactivity(@player, null);
	if(ponline(@player) && pworld(@player) == @race['world']) {
		if(array_index_exists(@race, 'sky')) {
			set_psky(@player, 0, 0);
		}
		clear_peffects(@player);
		_equip_kit(@player);
		try {
			@vehicle1 = get_entity_vehicle(puuid(@player));
			if(@vehicle1) {
				if(entity_type(@vehicle1) != 'ARMOR_STAND') {
					@vehicle2 = get_entity_vehicle(@vehicle1);
					if(@vehicle2) {
						entity_remove(@vehicle2);
					}
				}
				entity_remove(@vehicle1);
			}
			if(array_contains(sk_current_regions(@player), @race['region'])) {
				set_entity_loc(puuid(@player), @race['lobby']);
			}
		} catch(BadEntityException @ex) {
			// player entity doesn't exist in world for some reason
		}
	}
}

proc _race_prepare_player(@race, @player) {
	clear_peffects(@player);
	_clear_pinv(@player);
	if(array_index_exists(@race, 'sky')) {
		set_psky(@player, @race['sky'][0], @race['sky'][1]);
	}
	if(array_index_exists(@race, 'effect')) {
		foreach(@id: @effect in @race['effect']) {
			set_peffect(@player, @id, @effect[0], @effect[1], true, false);
		}
	}
}

proc _race_place_player(@race, @player, @loc) {
	set_entity_loc(puuid(@player), @loc);

	@stand = spawn_entity('ARMOR_STAND', 1, @loc)[0];
	set_entity_spec(@stand, array('small': true, 'visible': false, 'gravity': false));
	@race['players'][@player]['stands'][] = @stand;

	@vehicle = null;
	switch(@race['type']) {
		case 'boat':
			@vehicle = spawn_entity('BOAT', 1, @loc)[0];
		case 'horse':
			@vehicle = spawn_entity('HORSE' 1, @loc)[0];
			set_mob_age(@vehicle, 0);
			set_mob_owner(@vehicle, @player);
			set_entity_spec(@vehicle, array('saddle': array('name': 'SADDLE', 'jump': 0.8)));
		case 'pig':
			@vehicle = spawn_entity('PIG', 1, @loc)[0];
			set_entity_spec(@vehicle, array('saddled': true));
			set_pinv(@player, 0, array('name': 'CARROT_ON_A_STICK', 'meta': array('unbreakable': true)));
		case 'elytra':
			set_pinv(@player, 102, array('name': 'ELYTRA'));
	}
	if(@vehicle) {
		set_entity_rider(@stand, @vehicle);
		set_entity_rider(@vehicle, puuid(@player));
	} else {
		set_entity_rider(@stand, puuid(@player));
	}
}

proc _race_place_players(@race) {
	@index = 0;
	foreach(@p in array_keys(@race['players'])) {
		if(!array_index_exists(@race['spawn'], @index)) {
			@index = 0;
		}
		_race_prepare_player(@race, @p);
		_race_place_player(@race, @p, @race['spawn'][@index]);
		@index++;
	}
}

proc _race_drop_player(@race, @player) {
	foreach(@stand in @race['players'][@player]['stands']) {
		try(entity_remove(@stand));
	}
	play_sound(ploc(@player), array('sound': 'ENTITY_FIREWORK_ROCKET_BLAST'), @player);
	if(array_index_exists(@race, 'health')) {
		set_phealth(@player, @race['health']);
		set_phunger(@player, 16.0);
		set_psaturation(@player, 0.0);
	}
}

proc _race_drop_players(@race) {
	foreach(@p: @v in @race['players']) {
		_race_drop_player(@race, @p);
	}
}

proc _race_remove_players(@race) {
	foreach(@p: @v in @race['players']) {
		_race_remove_player(@race, @p);
	}
}
