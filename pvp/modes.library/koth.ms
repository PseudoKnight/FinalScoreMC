proc _interval(@pvp, @id) {
    if(array_index_exists(@pvp, 'team')) {
        @kingteam = -1;
        foreach(@p: @player in @pvp['players']) {
            if(pinfo(@p, 5) > 0 && array_contains(sk_current_regions(@p), @pvp['arena']['kothregion'])) {
                if(@kingteam > -1 && @kingteam != @player['team']) {
                    // contested
                    @kingteam = -2;
                    break();
                } else {
                    @kingteam = @player['team'];
                }
            }
        }
        
    	@teams = get_teams(@id);
    	if(@kingteam > -1) {
            @team = @pvp['arena']['team'][@kingteam]['name'];
    		@score = get_pscore('seconds', @team, @id);
    		set_pscore('seconds', @team, @score + 1, @id);
    		if(array_index_exists(@pvp['arena'], 'kothbeacon')) {
    			set_block_at(@pvp['arena']['kothbeacon'], '95:'.if(@kingteam, '11', '14'));
    		}
            if(@score >= -1) {
                _pvp_end_match(@id, @pvp['team'][@kingteam]['players']);
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
            if(pinfo(@player, 5) > 0 && array_contains(sk_current_regions(@player), @pvp['arena']['kothregion'])) {
                @king = @player;
                @hillcount++;
            }
        }
        
    	@team = get_teams(@id)[0];
    	if(@hillcount == 1) {
    		@score = get_pscore('seconds', @king, @id);
    		set_pscore('seconds', @king, @score + 1, @id);
    		if(!array_contains(@team['players'], @king)) {
    			if(@team['size'] == 1) {
    				team_remove_player('king', @team['players'][0], @id);
    			}
    			team_add_player('king', @king, @id);
    		}
    		if(array_index_exists(@pvp['arena'], 'kothbeacon')) {
    			set_block_at(@pvp['arena']['kothbeacon'], '95:'.(array_index(array_keys(@pvp['players']), @king) + 1));
    		}
            if(@score >= -1) {
                _pvp_end_match(@id, array(@king));
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
