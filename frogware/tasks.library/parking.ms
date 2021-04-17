proc _fw_start_task(@secs) {
	_fw_msg('Push your minecart into a dispenser');
	@blocks = import('frogware.blocks');
	if(is_null(@blocks)) {
		@blocks = array();
		export('frogware.blocks', @blocks);
	}
	for(@i = 0, @i < 40, @i++) {
		@loc = _fw_loc();
		if(@loc) {
			@blocks[] = @loc;
			if(rand(2)) {
				set_blockdata(@loc, array(block: 'RAIL', shape: if(rand(2), 'north_south', 'east_west')));
			} else {
				set_block(@loc, 'DISPENSER');
			}
		}
	}
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			pgive_item(@p, array(name: 'MINECART'));
		}
	}
	bind('player_interact', array(id: 'fwtask'), array(hand: 'main_hand', itemname: 'MINECART', button: 'right', block: 'RAIL'), @e) {
		if(_fw_player(player())) {
			cancel();
			set_pinv(player(), null, null);
			@loc = @e['location'];
			@loc['x'] += 0.5;
			@loc['y'] += 0.125;
			@loc['z'] += 0.5;
			@minecart = spawn_entity('MINECART', 1, @loc)[0];
			set_metadata(@minecart, 'player', player());
			_fw_changeteam(player(), 'winners');
		}
	}
	bind('vehicle_destroy', array(id: 'fw_vehicle_destroy'), array(vehicletype: 'MINECART'), @e) {
		if(get_metadata(@e['vehicle'], 'player', 'CommandHelper')) {
			cancel();
		}
	}
}

proc _fw_end_task(@secs) {
	unbind('fw_vehicle_destroy');
	foreach(@e in all_entities('custom')) {
		if(entity_type(@e) == 'MINECART') {
			@player = get_metadata(@e, 'player', 'CommandHelper');
			if(@player && _fw_changeteam(@player, 'losers')) {
				play_sound(ploc(@player), array(sound: 'ENTITY_ZOMBIE_VILLAGER_CONVERTED'), @player);
				spawn_particle(entity_loc(@e), 'SMOKE_LARGE');
				entity_remove(@e);
			}
		}
	}
}