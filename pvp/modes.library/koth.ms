proc _interval(@pvp) {
    @hillcount = 0;
    @king = '';
    foreach(@player in array_keys(@pvp['players'])) {
        if(pinfo(@player, 5) > 0 && array_contains(sk_current_regions(@player), @arena['kothregion'])) {
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
		if(array_index_exists(@arena, 'kothbeacon')) {
			set_block_at(@arena['kothbeacon'], '95:'.array_index(array_keys(@pvp['players']), @king) + 1);
		}
        return(true);
	} else {
		if(@team['size'] == 1) {
			team_remove_player('king', @team['players'][0], @id);
		}
		if(array_index_exists(@arena, 'kothbeacon')) {
			set_block_at(@arena['kothbeacon'], 7);
		}
        return(false);
	}
}
