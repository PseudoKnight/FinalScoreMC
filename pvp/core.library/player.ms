proc _add_player(@player, @pvp) {
	@pvp['players'][player()] = array()
}

proc _remove_player(@player, @pvp) {
	array_remove(@pvp['players'], @player)
}

proc _pvp_initialize_players(@id, @players) {
	@c = array(0, 0) # for selecting initial spawn locations
	foreach(@player in @players) {
		@pvp = import('pvp'.@id)
		if(!ponline(@player) || !get_collides_with_entities(@player)) {
			array_remove(@pvp['players'], @player)
			continue()
		}
		if(pmode(@player) == 'CREATIVE', 
			set_pmode(@player, 'SURVIVAL'))
		if(has_permission(@player, 'vanish.standard'), 
			scriptas(@player, run('/v off')))
		set_pscoreboard(@player, @id)
		if(array_index_exists(@pvp['players'][@player], 'team')) {
			team_add_player(@pvp['arena']['team'][@pvp['players'][@player]['team']]['name'], @player, @id)
			@pvp['players'][@player]['color'] = @pvp['arena']['team'][@pvp['players'][@player]['team']]['color']
		} else {
			@pvp['players'][@player]['color'] = color('f')
		}
		switch(@pvp['arena']['mode']) {
			case 'koth':
				set_pscore('seconds', @player, @pvp['arena']['score'], @id)
			case 'tdm':
			case 'dm':
				if(array_index_exists(@pvp['arena'], 'lives') && @pvp['arena']['lives'] > 1) {
					set_pscore('lives', @player, @pvp['arena']['lives'], @id)
				}
		}
		
		if(array_index_exists(@pvp['arena'], 'lives')) {
			@pvp['players'][@player]['lives'] = @pvp['arena']['lives']
		}
		
		if(array_index_exists(@pvp['arena'], 'respawntime')) {
			@pvp['players'][@player]['respawn'] = 0
		}
		
		@pvp['stats'][@player] = array(
			'kills': 0, 
			'damagetaken': array(), 
			'damage': 0, 
			'deaths': 0, 
			'assists': 0,
		);
		
		queue_push(closure(){
			if(array_index_exists(@pvp, 'team')) {
				@loc = @pvp['arena']['spawn'][@pvp['players'][@player]['team']][@c[@pvp['players'][@player]['team']]];
				if(@c[@pvp['players'][@player]['team']] == array_size(@pvp['arena']['spawn'][@pvp['players'][@player]['team']]) - 1) {
					@c[@pvp['players'][@player]['team']] = 0
				} else {
					@c[@pvp['players'][@player]['team']]++
				}
			} else {
				@loc = @pvp['arena']['spawn'][0][@c[0]];
				if(@c[0] == array_size(@pvp['arena']['spawn'][0]) - 1) {
					@c[0] = 0
				} else {
					@c[0]++
				}
			}
			set_entity_fall_distance(pinfo(@player, 13), 0);
			set_ploc(@player, @loc);
			play_sound(@loc, array('sound': 'FIREWORK_BLAST'), @player);
		}, @id)
		queue_delay(50, @id) # this is to help prevent invisible players
		
		set_pbed_location(@player, @pvp['arena']['lobby'])

		_clear_pinv(@player)
		_clear_peffects(@player)
		if(array_index_exists(@pvp['arena'], 'classes') && !array_index_exists(@pvp['players'][@player], 'class')) {
			@rand = array_rand(@pvp['arena']['classes'], array_size(@pvp['arena']['classes']))
			foreach(@r in @rand) {
				if(!array_index_exists(@pvp['arena']['classes'][@r], 'team')
				|| @pvp['players'][@player]['team'] == @pvp['arena']['classes'][@r]['team']) {
					@pvp['players'][@player]['class'] = @r
					break()
				}
			}
			if(array_index_exists(@pvp['players'][@player], 'class')) {
				_class('load', @player, @pvp['players'][@player]['class'], @pvp)
			}
		}
		
		foreach(@p in @pvp['spectators']) {
			raw_set_pvanish(@p, true, @player)
		}
		
		set_phunger(@player, 20)
		set_psaturation(@player, 5)
		set_phealth(@player, 20)
		_pvp_equip(@id, @player)

	}

}

proc _pvp_equip(@id, @player) {
	@pvp = import('pvp'.@id)
	if(array_index_exists(@pvp['players'][@player], 'inv')) {
		set_pinv(@player, @pvp['players'][@player]['inv'])
	} else {
		if(array_index_exists(@pvp['arena'], 'kit')) {
			if(array_index_exists(@pvp, 'team')) {
				set_pinv(@player, @pvp['arena']['kit'][@pvp['players'][@player]['team']])
			} else {
				set_pinv(@player, @pvp['arena']['kit'][0])
			}
		}
		if(array_index_exists(@pvp['players'][@player], 'class')) {
			_class('equip', @player, @pvp['players'][@player]['class'], @pvp)
		}
	}
	if(array_index_exists(@pvp['arena'], 'effect')) {
		foreach(@effect: @data in @pvp['arena']['effect'][0]) {
			set_peffect(@player, @effect, @data['strength'], @data['length'], true)
		}
		if(array_index_exists(@pvp, 'team')) {
			foreach(@effect: @data in @pvp['arena']['effect'][@pvp['players'][@player]['team'] + 1]) {
				set_peffect(@player, @effect, @data['strength'], @data['length'], true)
			}
		}
	}
}

proc _assign_team(@player, @pvp) {
	if(array_size(@pvp[team][0][players]) * @pvp[arena][teamratio][1] <= array_size(@pvp[team][1][players]) * @pvp[arena][teamratio][0]) {
		@pvp[players][@player][team] = 0
		if(!array_contains(@pvp[team][0][players], @player)) {
			array_push(@pvp[team][0][players], @player)
		}
		array_remove_values(@pvp[team][1][players], @player)
	} else {
		@pvp[players][@player][team] = 1
		if(!array_contains(@pvp[team][1][players], @player)) {
			array_push(@pvp[team][1][players], @player)
		}
		array_remove_values(@pvp[team][0][players], @player)
	}
}