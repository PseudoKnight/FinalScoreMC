<! 
	author: PseudoKnight,rivergod
>
proc _fw_start_task(@secs) {
	_fw_msg('Hug the leader!');
	@leader = _fw_leader();
	@explosives = associative_array();
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p) && @p != @leader) {
			@tnt = spawn_entity('PRIMED_TNT', 1, location_shift(ploc(@p), 'up'))[0];
			@explosives[@tnt] = @p;
			set_entity_rider(puuid(@p), @tnt);
			set_entity_spec(@tnt, array(fuseticks: 20 * (@secs - 1))); // explode one second before round ends
		}
	}
	bind('entity_damage', array(id: 'fwtask'), array(type: 'PLAYER', world: 'custom', cause: 'ENTITY_EXPLOSION'), @e, @leader, @explosives) {
		if(_fw_player(@e['player'])) {
			@damager = @e['damager'];
			@player = @e['player'];
			if(@player == @leader && array_index_exists(@explosives, @damager)) {
				@attacker = @explosives[@damager];
				if(_fw_change_team(@attacker, 'winners')) {
					play_sound(ploc(@attacker), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), @attacker);
				}
				if(_fw_change_team(@leader, 'losers')) {
					play_sound(ploc(@leader), array(sound: 'ENTITY_ZOMBIE_VILLAGER_CONVERTED'), @leader);
				}
			}
		}
	}
	_fw_change_team(@leader, 'winners');
}

proc _fw_end_task(@secs) {
	
}