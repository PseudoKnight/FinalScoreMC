proc _add_player(@player, @pvp) {
	@pvp['players'][player()] = associative_array()
}

proc _remove_player(@player, @pvp) {
	if(array_index_exists(@pvp['players'][player()], 'class')) {
		_class('unload', player(), @pvp['players'][player()]['class'], @pvp)
	}
	array_remove(@pvp['players'], player());
	dm_set_pvisible(@player, true);

	# Delay spectator mode so that health amount is updated.
	# Health can be above zero when pkill() or set_phealth() are used.
	queue_push(closure(){
		_set_spectator(player(), @pvp);
	});
}

proc _pvp_initialize_players(@id, @players) {
	@pvp = import('pvp'.@id);
	@c = array(0, 0); # for selecting initial spawn locations
	@loc = array();
	foreach(@player in @players) {
		if(!ponline(@player) || !get_collides_with_entities(@player) || pworld(@player) !== 'custom') {
			array_remove(@pvp['players'], @player);
			continue();
		}
		if(array_contains(@pvp['arena']['flags'], 'build')) {
			set_pmode(@player, 'SURVIVAL');
		} else {
			set_pmode(@player, 'ADVENTURE');
		}
		set_pscoreboard(@player, @id);
		if(array_index_exists(@pvp['players'][@player], 'team')) {
			team_add_player(@pvp['arena']['team'][@pvp['players'][@player]['team']]['name'], @player, @id);
			@pvp['players'][@player]['color'] = @pvp['arena']['team'][@pvp['players'][@player]['team']]['color'];
		} else {
			@pvp['players'][@player]['color'] = color('f');
		}
		switch(@pvp['arena']['mode']) {
			case 'koth':
				set_pscore('seconds', @player, @pvp['arena']['score'], @id);
			case 'tdm':
			case 'dm':
				if(array_index_exists(@pvp['arena'], 'lives') && @pvp['arena']['lives'] > 1) {
					set_pscore('lives', @player, @pvp['arena']['lives'], @id);
				}
		}

		if(array_contains(@pvp['arena']['flags'], 'hideplayers')) {
			dm_set_pvisible(@player, false);
		}

		if(array_index_exists(@pvp['arena'], 'lives')) {
			@pvp['players'][@player]['lives'] = @pvp['arena']['lives'];
		}

		if(array_index_exists(@pvp['arena'], 'respawntime')) {
			@pvp['players'][@player]['respawn'] = 0;
		}

		if(array_index_exists(@pvp, 'stats')) {
			@pvp['stats'][@player] = array(
				'kills': 0,
				'lastdamaged': 0,
				'lastdamager': '',
				'damager': '',
				'damaged': 0,
				'damage': 0,
				'deaths': 0,
				'pickups': 0,
			);
		}

		set_pbed_location(@player, @pvp['arena']['lobby']);

		_clear_pinv(@player);
		_clear_peffects(@player);
		if(array_index_exists(@pvp['arena'], 'classes')) {
		 	if(!array_index_exists(@pvp['players'][@player], 'class')) {
				_class_select_random(@player, @pvp);
			}
			_class('load', @player, @pvp['players'][@player]['class'], @pvp);
		}

		foreach(@p in @pvp['spectators']) {
			raw_set_pvanish(@p, true, @player);
		}

		set_phunger(@player, 20);
		set_psaturation(@player, 5);
		set_phealth(@player, 20);
		_pvp_equip(@id, @player);

		# Select spawn location
		if(array_index_exists(@pvp, 'team')) {
			@loc = @pvp['arena']['spawn'][@pvp['players'][@player]['team']][@c[@pvp['players'][@player]['team']]];
			if(@c[@pvp['players'][@player]['team']] == array_size(@pvp['arena']['spawn'][@pvp['players'][@player]['team']]) - 1) {
				@c[@pvp['players'][@player]['team']] = 0;
			} else {
				@c[@pvp['players'][@player]['team']]++;
			}
		} else {
			@loc = @pvp['arena']['spawn'][0][@c[0]];
			if(@c[0] == array_size(@pvp['arena']['spawn'][0]) - 1) {
				@c[0] = 0;
			} else {
				@c[0]++;
			}
		}

		# Teleport to spawn location
		# Teleporting players one at a time helps prevent client-side invisible players
		queue_push(closure(){
			try {
				set_entity_fall_distance(puuid(@player), 0);
				set_ploc(@player, @loc);
				play_sound(@loc, array('sound': 'FIREWORK_BLAST'), @player);
			} catch(Exception @ex) {
				// Something went wrong.
				// They should die next pvp interval for being outside of the arena and then get respawned.
			}
		}, @id);
	}
}

proc _pvp_equip(@id, @player) {
	if(pworld(@player) !== 'custom') {
		return();
	}
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], @player)) {
		return();
	}
	if(array_index_exists(@pvp['players'][@player], 'inv')) {
		set_pinv(@player, @pvp['players'][@player]['inv']);
	} else {
		if(array_index_exists(@pvp['arena'], 'kit')) {
			if(array_index_exists(@pvp, 'team')) {
				set_pinv(@player, @pvp['arena']['kit'][@pvp['players'][@player]['team']]);
			} else {
				set_pinv(@player, @pvp['arena']['kit'][0]);
			}
		}
		if(array_index_exists(@pvp['players'][@player], 'class')) {
			_class('equip', @player, @pvp['players'][@player]['class'], @pvp);
		}
	}
	if(array_index_exists(@pvp['arena'], 'effect')) {
		foreach(@effect: @data in @pvp['arena']['effect'][0]) {
			set_peffect(@player, @effect, @data['strength'], @data['length'], true);
		}
		if(array_index_exists(@pvp, 'team')) {
			foreach(@effect: @data in @pvp['arena']['effect'][@pvp['players'][@player]['team'] + 1]) {
				set_peffect(@player, @effect, @data['strength'], @data['length'], true);
			}
		}
	}
	if(array_contains(@pvp['arena']['flags'], 'heartdisplay')) {
		set_pscore('health', @player, integer(pinfo(player(), 5)), @id);
	}
}

proc _assign_team(@player, @pvp) {
	if(array_size(@pvp['team'][0]['players']) * @pvp['arena']['teamratio'][1] <= array_size(@pvp['team'][1]['players']) * @pvp['arena']['teamratio'][0]) {
		@pvp['players'][@player]['team'] = 0;
		if(!array_contains(@pvp['team'][0]['players'], @player)) {
			@pvp['team'][0]['players'][] = @player;
		}
		array_remove_values(@pvp['team'][1]['players'], @player)
	} else {
		@pvp['players'][@player]['team'] = 1;
		if(!array_contains(@pvp['team'][1]['players'], @player)) {
			@pvp['team'][1]['players'][] = @player;
		}
		array_remove_values(@pvp['team'][0]['players'], @player);
	}
}
