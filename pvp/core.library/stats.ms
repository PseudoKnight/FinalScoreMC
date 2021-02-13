proc _stats_damage(@damager, @player, @amount, @pvp) {
	if(array_index_exists(@pvp, 'stats')
	&& array_index_exists(@pvp['stats'], @damager)
	&& @damager != @player) {
		@pvp['stats'][@damager]['damage'] += @amount;
		
		if(@pvp['stats'][@player]['damager'] !== ''
		&& @pvp['stats'][@player]['damager'] != @damager) {
			@pvp['stats'][@player]['lastdamager'] = @pvp['stats'][@player]['damager'];
			@pvp['stats'][@player]['lastdamaged'] = @pvp['stats'][@player]['damaged'];
		}
		@pvp['stats'][@player]['damager'] = @damager;
		@pvp['stats'][@player]['damaged'] = time();
	}
}

proc _stat_pad(@amount, @length) {
	@length -= length(@amount);
	if(@length <= 0, return(@amount));
	@pad = '';
	while(@length > 0) {
		@pad .= '0';
		@length--;
	}
	return(color(8).@pad.color('r').@amount);
}

proc _stats_table() {
	return(array(
		array('kills', 2, '-------'),
		array('deaths', 2, '---------'),
		array('pickups', 2, '--------'),
		array('damage', 3, '------')
	));
}

proc _store_stats(@winners, @pvp) {
	if(array_size(@pvp['stats']) < 2) {
		return();
	}
	foreach(@player: @stats in @pvp['stats']) {
		@uuid = puuid(@player, true);
		@pstats = get_value('pvp', @uuid);
		if(!@pstats) {
			@pstats = associative_array(
				'kills': 0,
				'deaths': 0,
				'games': 0,
				'wins': 0,
				'losses': 0,
				'since': time(),
			);
		}
		@pstats['games']++;
		@pstats['kills'] += @stats['kills'];
		@pstats['deaths'] += @stats['deaths'];
		if(array_contains(@winners, @player)) {
			@pstats['wins']++;
		} else {
			@pstats['losses']++;
		}
		store_value('pvp', @uuid, @pstats);
	}
}
