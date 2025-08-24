proc _race_add_player(@id, @player) {
	@race = import('race'.@id);
	@race['players'][@player] = array(
		lap: 0,
		checkpoint: 0,
		state: 'racing',
		place: 0,
		checkpointLoc: @race['spawn'][0],
		kart: null,
		itemCooldown: 0,
		design: array(
 			color: string(array_get_rand(reflect_pull('enum', 'DyeColor'))),
		 	engine: array_get_rand(array('furnace', 'blast_furnace', 'smoker', 'copper_bulb', 'redstone_lamp')),
			wheels: array_get_rand(array('BLACK_CONCRETE', 'BLACK_CONCRETE_POWDER')),
		)
	);
	set_pmode(@player, 'ADVENTURE');
	set_pscoreboard(@player, @id);
	set_pscore('time', @player, 0, @id);
	team_add_player('collision', @player, @id);
}

proc _race_remove_player(@race, @player) {
	_race_remove_vehicle(@player, @race);
	array_remove(@race['players'], @player);
	if(ponline(@player)) {
		if(pworld(@player) === @race['world']) {
			clear_peffects(@player);
			_equip_kit(@player);
			if(array_contains(sk_current_regions(@player), @race['region'])) {
				set_entity_loc(puuid(@player), @race['lobby']);
			}
		}
	}
}

proc _race_prepare_player(@race, @player) {
	clear_peffects(@player);
	_clear_pinv(@player);
	if(array_index_exists(@race, 'effect')) {
		foreach(@id: @effect in @race['effect']) {
			set_peffect(@player, @id, @effect[0], @effect[1], true, false);
		}
	}
}

proc _race_place_player(@race, @player, @loc) {
	@state = @race['players'][@player]['state'];
	if(@state === 'waiting' || @state === 'finished') {
		return(false);
	}
	@race['players'][@player]['state'] = 'waiting';
	set_entity_loc(puuid(@player), @loc);

	if(@race['type'] === 'kart') {
		@loc[5] = 0;
		@checkpoint = @race['players'][@player]['checkpoint'] - 1;
		if(@checkpoint == -1) {
			@checkpoint = array_size(@race['checkpoint']) - 1;
		}
		@camdist = 4.0;
		if(array_size(@race['checkpoint'][@checkpoint]) == 3) {
			@camdist = @race['checkpoint'][@checkpoint][2];
		} else if(array_index_exists(@race, 'camdist')) {
			@camdist = @race['camdist'];
		}
		@kart = _kart_spawn(@loc, @player, @race['players'][@player]['design'], @camdist);
		@race['players'][@player]['kart'] = @kart;
		return(true);
	}

	@stand = spawn_entity('ARMOR_STAND', 1, @loc)[0];
	set_entity_saves_on_unload(@stand, false);
	add_scoreboard_tag(@stand, 'remove');
	set_entity_spec(@stand, array(small: true, visible: false, gravity: false));

	@vehicle = null;
	switch(@race['type']) {
		case 'boat':
			@vehicle = spawn_entity('OAK_BOAT', 1, @loc)[0];
		case 'horse':
			@vehicle = spawn_entity('HORSE', 1, @loc)[0];
			set_mob_age(@vehicle, 0);
			set_mob_owner(@vehicle, @player);
			set_entity_spec(@vehicle, array(saddle: array(name: 'SADDLE', jump: 0.8)));
		case 'pig':
			@vehicle = spawn_entity('PIG', 1, @loc)[0];
			set_entity_spec(@vehicle, array(saddled: true));
			set_pinv(@player, 0, array(name: 'CARROT_ON_A_STICK', meta: array('unbreakable': true)));
			set_mob_effect(@vehicle, 'SPEED', 3, 9999, true, false);
		case 'elytra':
			set_pinv(@player, 102, array(name: 'ELYTRA'));
	}
	if(@vehicle) {
		set_entity_rider(@stand, @vehicle);
		set_entity_rider(@vehicle, puuid(@player));
	} else {
		set_entity_rider(@stand, puuid(@player));
	}
	return(true);
}

proc _race_place_players(@race) {
	@index = 0;
	foreach(@p in array_keys(@race['players'])) {
		if(ponline(@p)) {
			_race_prepare_player(@race, @p);
			_race_place_player(@race, @p, @race['spawn'][@index]);
			@index = (@index + 1) % array_size(@race['spawn']);
		}
	}
}

proc _race_drop_player(@race, @player) {
	if(!array_index_exists(@race['players'], @player)) {
		return();
	}
	@race['players'][@player]['state'] = 'racing';
	if(@race['type'] === 'kart') {
		_kart_tick(@player, @race['players'][@player]['kart'], @race);
	} else {
		@vehicle = pvehicle(@player);
		while(@vehicle) {
			@nextVehicle = get_entity_vehicle(@vehicle);
			if(entity_type(@vehicle) === 'ARMOR_STAND') {
				entity_remove(@vehicle);
			}
			@vehicle = @nextVehicle;
		}
		if(array_index_exists(@race, 'health')) {
			set_phealth(@player, @race['health']);
			set_phunger(@player, 16.0);
			set_psaturation(@player, 0.0);
		}
	}
	play_sound(ploc(@player), array(sound: 'ENTITY_FIREWORK_ROCKET_BLAST'), @player);
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
