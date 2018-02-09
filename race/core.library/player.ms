proc _race_add_player(@id, @player) {
	@race = import('race'.@id);
	@race['players'][@player] = array(
		'lap': 0,
		'checkpoint': 0,
		'state': 'racing',
		'place': 0,
		'loc': @race['spawn'][0],
	);
	set_pscoreboard(@player, @id);
	set_pscore('time', @player, 0, @id);
	team_add_player('collision', @player, @id);
}

proc _race_remove_player(@race, @player) {
	array_remove(@race, @player);
	if(ponline(@player) && pworld(@player) == @race['world']) {
		if(array_index_exists(@race, 'sky')) {
			runas('~console', '/skychanger 0 '.@player);
		}
		@vehicle = get_entity_vehicle(puuid(@player));
		if(@vehicle) {
			try(entity_remove(@vehicle));
		}
		set_entity_loc(puuid(@player), @race['lobby']);
		_clear_peffects(@player);
		_set_pactivity(@player, null);
		_equip_kit(@player);
	}
}

proc _race_place_player(@race, @player, @loc) {
	set_entity_loc(puuid(@player), @loc);
	
	@stand = spawn_entity('ARMOR_STAND', 1, @loc)[0];
	set_entity_spec(@stand, array('small': true, 'visible': false, 'gravity': false));
	
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
			set_pinv(@player, 0, array('name': 'CARROT_STICK', 'meta': array('unbreakable': true)));
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
	foreach(@i: @p in array_keys(@race['players'])) {
		_clear_peffects(@p);
		_clear_pinv(@p);
		_race_place_player(@race, @p, @race['spawn'][@i]);
		if(array_index_exists(@race, 'sky')) {
			runas('~console', '/skychanger '.@race['sky'].' '.@p);
		}
		if(array_index_exists(@race, 'effect')) {
			foreach(@id: @effect in @race['effect']) {
				set_peffect(@p, @id, @effect[0], @effect[1], true, false);
			}
		}
	}
}

proc _race_drop_player(@race, @player) {
	@vehicle = get_entity_vehicle(puuid(@player));
	if(@vehicle) {
		if(entity_type(@vehicle) == 'ARMOR_STAND') {
			@bind = bind(entity_dismount, array('priority': 'HIGH'), null, @event) {
				consume();
			}
			set_entity_rider(@vehicle, null);
			entity_remove(@vehicle);
			unbind(@bind);
		}
	}
	play_sound(ploc(@player), array('sound': 'ENTITY_FIREWORK_BLAST'), @player);
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
