proc _interval(@pvp, @id) {
    if(array_index_exists(@pvp, 'team')) {
        @kingteam = -1;
        @count = 0;
        @players = array();
        foreach(@p: @player in @pvp['players']) {
            if(phealth(@p) > 0 && array_contains(sk_current_regions(@p), @pvp['arena']['kothregion'])) {
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
    			set_block_at(@pvp['arena']['kothbeacon'], '95:'.if(@kingteam, '11', '14'));
    		}
            if(@score >= -11) {
                play_sound(@pvp['arena']['kothbeacon'], array('sound': 'NOTE_PLING', 'volume': 5));
                if(@score >= -1) {
                    _pvp_end_match(@id, @pvp['team'][@kingteam]['players']);
                }
            }
    	} else if(array_index_exists(@pvp['arena'], 'kothbeacon')) {
            if(@kingteam == -2) {
    			set_block_at(@pvp['arena']['kothbeacon'], 7);
            } else {
                set_block_at(@pvp['arena']['kothbeacon'], '95:0');
            }
    	}
        
    } else {
        @hillcount = 0;
        @king = '';
        foreach(@player in array_keys(@pvp['players'])) {
            if(phealth(@player) > 0 && array_contains(sk_current_regions(@player), @pvp['arena']['kothregion'])) {
                @king = @player;
                @hillcount++;
            }
        }
        
    	@team = get_teams(@id)[0];
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
    			set_block_at(@pvp['arena']['kothbeacon'], '95:'.(array_index(array_keys(@pvp['players']), @king) + 1));
    		}
            if(@score >= -11) {
                play_sound(@pvp['arena']['kothbeacon'], array('sound': 'NOTE_PLING', 'volume': 5));
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
                    set_block_at(@pvp['arena']['kothbeacon'], '95:0');
                } else {
    			    set_block_at(@pvp['arena']['kothbeacon'], 7);
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
