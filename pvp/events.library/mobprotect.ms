proc _bind(@pvp) {
	@id = @pvp['id'];

	@pvp['binds'][] = bind('entity_death', null, null, @e, @pvp, @id) {
		foreach(@team: @data in @pvp['arena']['mobprotect']) {
			if(@pvp['team'][@team]['mobprotect'] == @e['id']) {
				if(@team == 0) {
					_pvp_end_match(@id, @pvp['team'][1]['players']);
				} else {
					_pvp_end_match(@id, @pvp['team'][0]['players']);
				}
			}
		}
	}

	@pvp['binds'][] = bind('entity_damage', null, null, @e, @pvp, @id) {
		if(!array_index_exists(@pvp['arena'], 'mobprotect')) {
			// still initializing game
			die();
		}
		foreach(@team: @data in @pvp['arena']['mobprotect']) {
			if(array_get(@pvp['team'][@team], 'mobprotect', null) == @e['id']) {
				@health = get_entity_health(@e['id']);
				set_mob_effect(@e['id'], 'GLOWING', 1, 8);
				set_pscore('mobhealth', @pvp['arena']['team'][@team]['name'], ceil(@health), @id);
				foreach(@p: @player in @pvp['players']) {
					if(@player['team'] == @team) {
						play_sound(ploc(@p), array(sound: 'BLOCK_NOTE_BLOCK_PLING', pitch: 0.5 + (1.5 * (@health / 100))), @p);
					}
				}
			}
		}
	}
}