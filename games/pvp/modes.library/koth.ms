proc _interval(@pvp, @id) {
	@arena = @pvp['arena'];
	if(!array_index_exists(@pvp, 'kothregion')) {
		if(is_array(@pvp['arena']['kothregion'])) {
			@pvp['kothregion'] = array_get_rand(@arena['kothregion']);
		} else {
			@pvp['kothregion'] = @arena['kothregion'];
		}
		if(!array_index_exists(@pvp['arena'], 'kothbeacon')) {
			@coords = sk_region_info(@pvp['kothregion'], @pvp['arena']['world'], 0);
			@pvp['kothdisplay'] = spawn_entity('BLOCK_DISPLAY', 1, location_shift(@coords[1], 'down', 0.0625), closure(@e) {
				set_entity_saves_on_unload(@e, false);
				set_entity_spec(@e, array(blockdata: 'WHITE_STAINED_GLASS'));
				set_display_entity(@e, array(
					brightness: 0,
					transformation: array(
						scale: array(x: @coords[0][0] - @coords[1][0] + 1, y: 0, z: @coords[0][2] - @coords[1][2] + 1))));
				set_entity_glowing(@e, true);
			})[0];
		}
	}

	// let new players walk into the King of the Hill game
	foreach(@p in all_players(@arena['world'])) {
		if(!array_index_exists(@pvp['players'], @p)
		&& !array_contains(@pvp['spectators'], @p)
		&& array_contains(sk_current_regions(@p), @arena['region'])) {
			@pvp['players'][@p] = associative_array();
			if(array_index_exists(@arena, 'team')) {
				_player_assign_team(@p, @pvp);
			}
			_pvp_initialize_players(@id, array(@p));
		}
	}
	
	if(array_index_exists(@pvp, 'team')) {
		@kingteam = -1; // none
		@count = 0;
		@players = array();
		foreach(@p: @player in @pvp['players']) {
			if(pmode(@p) !== 'SPECTATOR' && array_contains(sk_current_regions(@p), @pvp['kothregion'])) {
				if(@kingteam > -1 && @kingteam != @player['team']) {
					@kingteam = -2; // contested
					break();
				} else {
					@kingteam = @player['team'];
					@players[] = @p;
					@count++;
				}
			}
		}
		
		if(@kingteam > -1) { // not contested or none
			@team = @arena['team'][@kingteam]['name'];
			@score = get_pscore('seconds', @team, @id) + @count;
			set_pscore('seconds', @team, @score, @id);
			foreach(@p in @players) {
				@pvp['stats'][@p]['seconds']++;
			}
			if(array_index_exists(@arena, 'kothbeacon')) {
				set_block(@arena['kothbeacon'], if(@kingteam, 'BLUE', 'RED').'_STAINED_GLASS');
			} else if(array_index_exists(@pvp, 'kothdisplay')) {
				set_display_entity(@pvp['kothdisplay'], array(
					glowcolor: if(@kingteam, array(r: 60, g: 68, b: 170), array(r: 176, g: 46, b: 38))));
			}
			if(@score >= -10) {
				play_sound(ploc(@players[0]), array(sound: 'BLOCK_NOTE_BLOCK_PLING', volume: 5));
				if(@score < -9) {
					if(is_array(@pvp['arena']['kothregion'])) {
						if(array_index_exists(@pvp, 'kothdisplay')) {
							try(entity_remove(@pvp['kothdisplay']))
						}
						array_remove(@pvp, 'kothregion'); // get new region
					}
				} else if(@score >= 0) {
					_pvp_end_match(@id, @pvp['team'][@kingteam]['players']);
				}
			}
		} else if(array_index_exists(@arena, 'kothbeacon')) {
			if(@kingteam == -2) { // contested
				set_block(@arena['kothbeacon'], 'BEDROCK');
			} else {
				set_block(@arena['kothbeacon'], 'WHITE_STAINED_GLASS');
			}
		} else if(array_index_exists(@pvp, 'kothdisplay')) {
			set_display_entity(@pvp['kothdisplay'], array(
				glowcolor: array(r: 255, g: 255, b: 255)));
		}
		
	} else {
		@hillcount = 0;
		@king = '';
		foreach(@player in array_keys(@pvp['players'])) {
			if(pmode(@player) !== 'SPECTATOR' && array_contains(sk_current_regions(@player), @pvp['kothregion'])) {
				@king = @player;
				@hillcount++;
			}
		}
		
		@team = get_teams(@id)['king'];
		if(@hillcount == 1) {
			@score = get_pscore('seconds', @king, @id) + 1;
			set_pscore('seconds', @king, @score, @id);
			@pvp['stats'][@king]['seconds']++;
			if(!array_contains(@team['players'], @king)) {
				if(@team['size'] == 1) {
					team_remove_player('king', @team['players'][0], @id);
				}
				team_add_player('king', @king, @id);
			}

			if(array_index_exists(@arena, 'kothbeacon')) {
				@colors = array('ORANGE', 'MAGENTA', 'LIGHT_BLUE', 'YELLOW', 'LIME', 'PINK',
						'CYAN', 'PURPLE', 'BLUE', 'BROWN', 'GREEN', 'RED');
				@color = @colors[array_index(array_keys(@pvp['players']), @king)];
				set_block(@arena['kothbeacon'], @color.'_STAINED_GLASS');
			} else if(array_index_exists(@pvp, 'kothdisplay')) {
				@colors = array(
					array(r: 249, g: 128, b: 29),
					array(r: 199, g: 78, b: 189),
					array(r: 58, g: 179, b: 218),
					array(r: 254, g: 216, b: 61),
					array(r: 128, g: 199, b: 31),
					array(r: 243, g: 139, b: 170),
					array(r: 22, g: 156, b: 156),
					array(r: 137, g: 50, b: 184),
					array(r: 60, g: 68, b: 170),
					array(r: 131, g: 84, b: 50),
					array(r: 94, g: 124, b: 22),
					array(r: 176, g: 46, b: 38),
				);
				@color = @colors[array_index(array_keys(@pvp['players']), @king)];
				set_display_entity(@pvp['kothdisplay'], array(
					glowcolor: @color));
			}
			if(@score >= -10) {
				play_sound(ploc(@king), array(sound: 'BLOCK_NOTE_BLOCK_PLING', volume: 5));
				if(@score < -9) {
					if(is_array(@pvp['arena']['kothregion'])) {
						if(array_index_exists(@pvp, 'kothdisplay')) {
							try(entity_remove(@pvp['kothdisplay']))
						}
						array_remove(@pvp, 'kothregion'); // get new region
					}
				} else if(@score >= 0) {
					_pvp_end_match(@id, array(@king));
				}
			}
		} else {
			if(@team['size'] == 1) {
				team_remove_player('king', @team['players'][0], @id);
			}
			if(array_index_exists(@arena, 'kothbeacon')) {
				if(@hillcount > 1) {
					set_block(@arena['kothbeacon'], 'WHITE_STAINED_GLASS');
				} else {
					set_block(@arena['kothbeacon'], 'BEDROCK');
				}
			} else if(array_index_exists(@pvp, 'kothdisplay')) {
				set_display_entity(@pvp['kothdisplay'], array(
					glowcolor: array(r: 255, g: 255, b: 255)));
			}
		}
	}
}

// Override
proc _stats_table(){
	return(array(
		array('kills', 2, '-------'),
		array('deaths', 2, '--------'),
		array('seconds', 3, '--------'),
		array('pickups', 3, '------')
	));
}
