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

/*
	An array defining the columns and formatting for the stats display at the end of a match.
	Each element in the array is a column. 
	Each column array contains the elements for column key, value width, character padding, and abbreviation.
 */
proc _stats_table() {
	return(array(
		array('kills', 2, '-------', 'K'),
		array('deaths', 2, '--------', 'D'),
		array('damage', 3, '--------', 'DMG'),
		array('pickups', 2, '-------', 'PKS')
	));
}

proc _stats_print(@winners, @pvp) {
	if(array_size(@pvp['stats']) < 2) {
		return();
	}

	@title = '';
	@subtitle = '';
	if(array_index_exists(@pvp, 'team') && @winners) {
		@leader = null;
		foreach(@p in @winners) {
			if(array_index_exists(@pvp['players'], @p)) {
				@leader = @p;
				break();
			}
		}
		@team = @pvp['players'][@leader]['team'];
		@title = @pvp['players'][@leader]['color'].color('bold')
				.@pvp['arena']['team'][@team]['name'].' win '.@pvp['title'].'!';
		@subtitle = @pvp['players'][@leader]['color'].array_implode(@winners, ' ');
	} else if(@winners) {
		@title = array_implode(@winners, ' and ').' win'.if(array_size(@winners) == 1, 's ', ' ').@pvp['title'].'!';
	} else {
		@title = 'No one won '.@pvp['title'].'.';
	}

	@table = _stats_table();
	@a = @table[0];
	@b = @table[1];
	@c = @table[2];
	@d = @table[3];

	@embed = array(
		author: array(
			name: strip_colors(@title),
		),
		fields: array()
	);
	if(array_size(@winners) == 1) {
		@embed['author']['icon_url'] = 'https://crafatar.com/avatars/'.puuid(@winners[0], true).'?overlay';
	}
	@embed['fields'][] = array(name: @a[3].' : '.@b[3], value: '', inline: true);
	@embed['fields'][] = array(name: @c[3].' : '.@d[3], value: '', inline: true);
	@embed['fields'][] = array(name: '', value: '', inline: true); // player names

	_pvp_msg(@pvp, colorize('&7&m|------------------------------&7&l[ &f&lTHE FINAL SCORE&7&l ]&7&m--|'));
	_pvp_msg(@pvp, colorize(replace('--&7'.to_upper(@a[0]).' &8:&7 '.to_upper(@b[0]).' &8:&7 '.to_upper(@c[0]).' &8:&7 '.to_upper(@d[0]), '-', ' ')));
	_pvp_msg(@pvp, colorize('&7&m|----------------------------------------------------|'));

	@firstline = true;
	foreach(@player: @stats in @pvp['stats']) {
		_pvp_msg(@pvp, replace('----'
			._stat_pad(integer(@stats[@a[0]]), @a[1]).@a[2]
			._stat_pad(integer(@stats[@b[0]]), @b[1]).@b[2]
			._stat_pad(integer(@stats[@c[0]]), @c[1]).@c[2]
			._stat_pad(integer(@stats[@d[0]]), @d[1]).@d[2]
			.if(array_contains(@winners, @player),
				color('gold').color('bold').@player.if(@pvp['coins'] > 0, ' +'.@pvp['coins']),
				@player)
			.'-', '-', ' '));
		
		@embed['fields'][0]['value'] .= if(!@firstline, '\n').integer(@stats[@a[0]]).' : '.integer(@stats[@b[0]]);
		@embed['fields'][1]['value'] .= if(!@firstline, '\n').integer(@stats[@c[0]]).' : '.integer(@stats[@d[0]]);
		@embed['fields'][2]['value'] .= if(!@firstline, '\n').if(array_contains(@winners, @player), '**'.@player.'**', @player);

		@firstline = false;
	}

	_pvp_msg(@pvp, colorize('&7&m|----------------------------------------------------|'));
	foreach(@p in array_keys(@pvp['players'])) {
		title(@p, @title, @subtitle, 20, 60, 20);
	}

	discord_broadcast('minecraft_chat', array(embed: @embed));
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
