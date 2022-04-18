<!
	author: PseudoKnight,gothem8
>
proc _fw_start_task(@secs) {
	_fw_msg('Musical chairs!');
	@total = _fw_total_players();
	@total = max(1, @total - rand(1, @total + 1));
	@carts = array();
	for(@i = 0, @i < @total, @i++) {
		@loc = _fw_loc(32);
		if(@loc) {
			@minecart = spawn_entity('MINECART', 1, @loc)[0];
			set_metadata(@minecart, 'chair', true);
			@carts[] = @minecart;
		}
	}
	bind('vehicle_destroy', array(id: 'fwtask'), array(vehicletype: 'MINECART'), @e) {
		if(get_metadata(@e['vehicle'], 'chair', 'CommandHelper')) {
			cancel();
		}
	}
	if(!rand(5)) {
		set_timeout(3000, closure(){
			foreach(@cart in @carts) {
				@velocity = array(rand(), rand(), rand());
				play_sound(entity_loc(@cart), array(sound: 'entity_witch_ambient', volume: 4, pitch: 1.2));
				set_entity_velocity(@cart, @velocity);
			}
		});
	}
}

proc _fw_end_task(@secs) {
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p) && pvehicle(@p) && _fw_change_team(@p, 'winners')) {
			play_sound(ploc(@p), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), @p);
			try(entity_remove(pvehicle(@p)));
		}
	}
}