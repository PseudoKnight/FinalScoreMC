<!
	author: PseudoKnight,gothem8
>
proc _fw_start_task(@secs) {
	_fw_msg('Musical chairs!');
	@total = _fw_total_players();
	@total = max(1, @total - rand(1, @total + 1));
	for(@i = 0, @i < @total, @i++) {
		@loc = _fw_loc(32);
		if(@loc) {
			spawn_entity('MINECART', 1, @loc);
		}
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