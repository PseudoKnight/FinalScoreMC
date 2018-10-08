proc _interval(@pvp, @id) {
	// let new players walk into the King of the Hill game
	foreach(@p in all_players(@pvp['arena']['lobby'][3])) {
		if(!array_index_exists(@pvp['players'], @p)
		&& !array_contains(@pvp['spectators'], @p)
		&& array_contains(sk_current_regions(@p), @pvp['arena']['region'])) {
			@pvp['players'][@p] = associative_array();
			if(array_index_exists(@pvp['arena'], 'team')) {
				_player_assign_team(@p, @pvp);
			}
			_pvp_initialize_players(@id, array(@p));
		}
	}
	
	if(array_index_exists(@pvp, 'team')) {
		@kingteam = -1;
		@count = 0;
		@players = array();
		foreach(@p: @player in @pvp['players']) {
			if(pmode(@p) != 'SPECTATOR' && array_contains(sk_current_regions(@p), @pvp['arena']['kothregion'])) {
				if(@kingteam > -1 && @kingteam != @player['team']) {
					// contested
					@kingteam = -2;
					break();
				} else {
					@kingteam = @player['team'];
					@players[] = @p;
					@count++;
				}
			}
		}
		
		if(@kingteam > -1) {
			@team = @pvp['arena']['team'][@kingteam]['name'];
			@score = get_pscore('seconds', @team, @id);
			set_pscore('seconds', @team, @score + @count, @id);
			foreach(@p in @players) {
				@pvp['stats'][@p]['seconds']++;
			}
			if(array_index_exists(@pvp['arena'], 'kothbeacon')) {
				set_block(@pvp['arena']['kothbeacon'], if(@kingteam, 'BLUE', 'RED').'_STAINED_GLASS');
			}
			if(@score >= -11) {
				play_sound(@pvp['arena']['kothbeacon'], array('sound': 'BLOCK_NOTE_BLOCK_PLING', 'volume': 5));
				if(@score >= -1) {
					_pvp_end_match(@id, @pvp['team'][@kingteam]['players']);
				}
			}
		} else if(array_index_exists(@pvp['arena'], 'kothbeacon')) {
			if(@kingteam == -2) {
				set_block(@pvp['arena']['kothbeacon'], 'BEDROCK');
			} else {
				set_block(@pvp['arena']['kothbeacon'], 'WHITE_STAINED_GLASS');
			}
		}
		
	} else {
		@hillcount = 0;
		@king = '';
		foreach(@player in array_keys(@pvp['players'])) {
			if(pmode(@player) != 'SPECTATOR' && array_contains(sk_current_regions(@player), @pvp['arena']['kothregion'])) {
				@king = @player;
				@hillcount++;
			}
		}
		
		@team = get_teams(@id)['king'];
		if(@hillcount == 1) {
			@score = get_pscore('seconds', @king, @id);
			set_pscore('seconds', @king, @score + 1, @id);
			@pvp['stats'][@king]['seconds']++;
			if(!array_contains(@team['players'], @king)) {
				if(@team['size'] == 1) {
					team_remove_player('king', @team['players'][0], @id);
				}
				team_add_player('king', @king, @id);
			}

			if(array_index_exists(@pvp['arena'], 'kothbeacon')) {
				@colors = array('ORANGE', 'MAGENTA', 'LIGHT_BLUE', 'YELLOW', 'LIME', 'PINK',
						'CYAN', 'PURPLE', 'BLUE', 'BROWN', 'GREEN', 'RED');
				@color = @colors[array_index(array_keys(@pvp['players']), @king)];
				set_block(@pvp['arena']['kothbeacon'], @color.'_STAINED_GLASS');
			}
			if(@score >= -11) {
				play_sound(@pvp['arena']['kothbeacon'], array('sound': 'BLOCK_NOTE_BLOCK_PLING', 'volume': 5));
				if(@score >= -1) {
					_pvp_end_match(@id, array(@king));
				}
			}
		} else {
			if(@team['size'] == 1) {
				team_remove_player('king', @team['players'][0], @id);
			}
			if(array_index_exists(@pvp['arena'], 'kothbeacon')) {
				if(@hillcount > 1) {
					set_block(@pvp['arena']['kothbeacon'], 'WHITE_STAINED_GLASS');
				} else {
					set_block(@pvp['arena']['kothbeacon'], 'BEDROCK');
				}
			}
		}
	}
}

proc _stats_table(){
	return(array(
		array('kills', 2, '-------'),
		array('deaths', 2, '--------'),
		array('seconds', 3, '--------'),
		array('pickups', 3, '-------')
	));
}
