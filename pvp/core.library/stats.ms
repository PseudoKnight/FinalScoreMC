proc _stats_add_player(@player, @pvp) {
	@pvp['stats'][@player] = array(
		kills: 0,
		lastdamaged: 0,
		lastdamager: '',
		damager: '',
		damaged: 0,
		damage: 0,
		deaths: 0,
		pickups: 0,
		seconds: 0,
		scores: 0,
	);
}

proc _stats_damage(@damager, @player, @amount, @pvp) {
	if(array_index_exists(@pvp, 'stats', @damager)
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

proc _stats_print(@winners, @pvp) {
	@table = _stats_table();
	@a = @table[0];
	@b = @table[1];
	@c = @table[2];
	@d = @table[3];
	_pvp_msg(@pvp, colorize('&7&m|------------------------------&7&l[ &f&lTHE FINAL SCORE&7&l ]&7&m--|'));
	_pvp_msg(@pvp, colorize(replace('--&7'.to_upper(@a[0]).' &8:&7 '.to_upper(@b[0]).' &8:&7 '.to_upper(@c[0]).' &8:&7 '.to_upper(@d[0]), '-', ' ')));
	_pvp_msg(@pvp, colorize('&7&m|----------------------------------------------------|'));
	foreach(@player: @stats in @pvp['stats']) {
		_pvp_msg(@pvp, replace('----'
			._stat_pad(@stats[@a[0]], @a[1]).@a[2]
			._stat_pad(@stats[@b[0]], @b[1]).@b[2]
			._stat_pad(@stats[@c[0]], @c[1]).@c[2]
			._stat_pad(integer(@stats[@d[0]]), @d[1]).@d[2]
			.if(array_contains(@winners, @player),
				color('gold').color('bold').@player.if(@pvp['coins'] > 0, ' +'.@pvp['coins']),
				@player)
			.'-', '-', ' '));
	}
	_pvp_msg(@pvp, colorize('&7&m|----------------------------------------------------|'));
}

proc _stats_store(@winners, @pvp) {
	if(array_size(@pvp['stats']) < 2) {
		return();
	}
	foreach(@player: @stats in @pvp['stats']) {
		@uuid = puuid(@player, true);
		@pstats = get_value('pvp', @uuid);
		if(!@pstats) {
			@pstats = associative_array(
				kills: 0,
				deaths: 0,
				games: 0,
				wins: 0,
				losses: 0,
				since: time(),
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
