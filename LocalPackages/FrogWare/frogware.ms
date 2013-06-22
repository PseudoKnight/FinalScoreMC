proc('_fw_startgame',
	_fw_startround()
	bind('entity_damage', array('id': 'fwdamage'), array('type': 'PLAYER'), @e,
		if(_fw_player(@e['player'])) {
			modify_event('amount', 0)
		}
	)
)

proc('_fw_endgame', @winners,
	unbind('fwdamage')
	_regionmsg('frogware', color('green').'[FROGWARE] '.color('r').'Best frog'.if(array_size(@winners) > 1, 's').' in the house: '.array_implode(@winners, ' & '))
	@warp = get_value('warp.park')
	foreach(all_players(), @p,
		if(_fw_player(@p)) {
			_warmuptp(3.7, @p, @warp['loc'], @warp['yaw'], @warp['pitch'])
		}
	)
	foreach(@winners, @p,
		@coins = _fw_totalplayers()
		_acc_add(@p, @coins)
		tmsg(@p, color('6').'+'.@coins.' coins')
	)
	remove_scoreboard('fw')
)

proc('_fw_startround', @secs = 9,
	queue_delay(1000, 'fw')
	queue_push(closure(
		@winners = array()
		@count = 0
		foreach(all_players(), @p,
			if(_fw_player(@p)
			&& array_contains(sk_current_regions(@p), 'frogware')) {
				foreach(get_teams('fw'), @team,
					if(@team['name'] == 'winners' 
					&& array_contains(@team['players'], @p)) {
						set_pscore('score', @p, get_pscore('score', @p, 'fw') + 1, 'fw')
						_fw_changeteam(@p, 'losers')
						@count++
					}
				)
				if(get_pscore('score', @p, 'fw') == 20, array_push(@winners, @p))
			} else {
				try(set_pscoreboard(@p, 'main'))
			}
		)
		if(@winners) {
			_fw_endgame(@winners)
		} else {
			if(@count > (_fw_totalplayers() / 2)
			&& @secs > 6) {
				@secs--
			} else if(@count == 0
			&& @secs < 12) {
				@secs++
			}
			@tasks = array('climb', 'keepaway', 'harvest', 'koth', 'cake', 'fall', 'cluck')
			@task = @tasks[rand(array_size(@tasks))]
			queue_delay(1000, 'fw2')
			queue_push(closure(
				_fw_task(@task, 'start', @secs)
			), 'fw2')
			for(@i = @secs, @i >= 0, @i--,
				if(@i > 0) {
					queue_push(closure(
						_fw_countdown(@i)
					), 'fw2')
					queue_delay(1000, 'fw2')
				} else {
					queue_push(closure(
						_fw_countdown(@i)
						_fw_task(@task, 'end', @secs)
					), 'fw2')
				}
			)
		}
	), 'fw')

)

proc('_fw_countdown', @c,
	set_objective_display('score', color('a').color('l').@c, 'fw')
	if(@c < 4 && @c > 0) {
		foreach(all_players(), @p,
			if(_fw_player(@p)) {
				play_sound(ploc(@p), array('sound': 'click', 'pitch': 2), @p)
			}
		)
	} else if(@c == 0) {
		foreach(all_players(), @p,
			if(_fw_player(@p)) {
				play_sound(ploc(@p), array('sound': 'orb_pickup'), @p)
			}
		)
	}
)

proc('_fw_loc', @height = 0, @region = sk_region_info('frogware', 'custom')[0],
	return(array(
		@region[0][0] - rand(sqrt((@region[0][0] - @region[1][0]) ** 2)) + 0.5, 
		@region[1][1] + @height, 
		@region[0][2] - rand(sqrt((@region[0][2] - @region[1][2]) ** 2)) + 0.5,
		'custom'
	))
)

proc('_fw_mobs',
	@mobs = array('creeper', 'zombie', 'silverfish', 'slime', 'magmacube')
	@mob = @mobs[rand(array_size(@mobs))]
	@num = rand(15, 41)
	for(@i = 0, @i < @num, @i++,
		spawn_mob(@mob, 1, _fw_loc())
	)
)

proc('_fw_player', @player,
	if(ponline(@player)
	&& get_pscoreboard(@player) == 'fw') {
		return(true)
	} else {
		return(false)
	}
)

proc('_fw_totalplayers',
	@count = 0
	foreach(all_players(), @p,
		if(get_pscoreboard(@player) == 'fw') {
			@count++
		}
	)
	return(@count)
)

proc('_fw_changeteam', @player, @team,
	switch(@team
	, 'losers',
		if(team_remove_player('winners', @player, 'fw')) {
			team_add_player('losers', @player, 'fw')
			return(true)
		} else {
			return(false)
		}
	, 'winners',
		if(team_remove_player('losers', @player, 'fw')) {
			team_add_player('winners', @player, 'fw')
			return(true)
		} else {
			return(false)
		}
	)
)

proc('_fw_task', @task, @state, @secs,
	switch(@task
	, 'climb',
		switch(@state
		, 'start',
			_regionmsg('frogware', color('green').'[FROGWARE] '.color('r').'Climb.')
			if(rand(8) < 1) {
				_fw_mobs()
			}
			proc('_set_green', @x, @y, @z,
				if(rand(100) < 5, set_block_at(array(@x, @y, @z, 'custom'), '35:5'))
			)
			proc('_set_blue', @x, @y, @z,
				if(rand(100) < 4, set_block_at(array(@x, @y, @z, 'custom'), '35:11'))
			)
			proc('_set_red', @x, @y, @z,
				if(rand(100) < 3, set_block_at(array(@x, @y, @z, 'custom'), '35:14'))
			)
			@region = sk_region_info('frogware', 'custom')[0]
			queue_push(closure(
				_iterate_cuboid(array(@region[0][0], @region[1][1] + 2, @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 2, @region[1][2], 'custom'),
				'_set_green')
			), 'fw3')
			queue_push(closure(
				_iterate_cuboid(array(@region[0][0], @region[1][1] + 1, @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 1, @region[1][2], 'custom'),
				'_set_blue')
			), 'fw3')
			queue_push(closure(
				_iterate_cuboid(array(@region[0][0], @region[1][1], @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1], @region[1][2], 'custom'),
				'_set_red')
			), 'fw3')
				
		, 'end',
			foreach(all_players(), @p,
				if(_fw_player(@p)
				&& get_block_at(ploc(@p)) == '35:5'
				&& _fw_changeteam(@p, 'winners')) {
					play_sound(ploc(@p), array('sound': 'zombie_metal'), @p)
				}
			)
			_remove_region_mobs('frogware')
			proc('_set_air', @x, @y, @z,
				if(get_block_at(array(@x, @y, @z, 'custom')) != '0:0') {
					set_block_at(array(@x, @y, @z, 'custom'), '0:0')
				}
			)
			@region = sk_region_info('frogware', 'custom')[0]
			queue_push(closure(
				_iterate_cuboid(array(@region[0][0], @region[1][1], @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 2, @region[1][2], 'custom'),
				'_set_air')
			), 'fw3')
			queue_push(closure(
				_fw_startround(@secs)
			), 'fw3')
		)
		
	, 'say',
		switch(@state
		, 'start',
			@quotes = array(
				'You can eat rice!'
			)
			@quote = @quotes[rand(array_size(@quotes))]
			_regionmsg('frogware', color('green').'[FROGWARE] '.color('r').'Say: "'.@quote.'"')
			bind('player_chat', array('id': 'fwchat'), null, @e, @quote,
				if(_fw_player(player())) {
					modify_event('message', color('green').'[FROGWARE] '.color('r').@e['message'])
					modify_event('recipients', all_players())
					if(@e['message'] == @quote
					&& _fw_changeteam(@p, 'winners')) {
						play_sound(ploc(), array('sound': 'zombie_metal'), player())
					}
				}
			)
			
		, 'end',
			unbind('fwchat')
			_fw_startround(@secs)
		)
		
	, 'keepaway',
		switch(@state
		, 'start',
			_regionmsg('frogware', color('green').'[FROGWARE] '.color('r').'Look out!')
			_fw_mobs()
			bind('entity_damage', array('id': 'fwtaskdamage'), array('type': 'PLAYER'), @e,
				if((@e['cause'] == 'ENTITY_ATTACK' || @e['cause'] == 'ENTITY_EXPLOSION')
				&& _fw_player(@e['player'])
				&& is_numeric(@e['damager'])) {
					_fw_changeteam(@e['player'], 'losers')
				}
			)
			foreach(all_players(), @p,
				if(_fw_player(@p)) {
					_fw_changeteam(@p, 'winners')
				}
			)
			
		, 'end',
			foreach(all_players(), @p,
				if(_fw_player(@p)
				&& array_contains(get_teams('fw')[1]['players'], @p)) {
					play_sound(ploc(@p), array('sound': 'zombie_metal'), @p)
				}
			)
			_remove_region_mobs('frogware')
			unbind('fwtaskdamage')
			_fw_startround(@secs)
			
		)
		
	, 'harvest',
		switch(@state
		, 'start',
			_regionmsg('frogware', color('green').'[FROGWARE] '.color('r').'Bring in the harvest!')
			proc('_set_dirt', @x, @y, @z,
				if(rand(100) < 2, set_block_at(array(@x, @y, @z, 'custom'), '3:0'))
			)
			@region = sk_region_info('frogware', 'custom')[0]
			_iterate_cuboid(array(@region[0][0], @region[1][1], @region[0][2], 'custom'),
			array(@region[1][0], @region[1][1], @region[1][2], 'custom'),
			'_set_dirt')
			foreach(all_players(), @p,
				if(_fw_player(@p)) {
					set_pinv(@p, array(
						0: array('type': 291),
						1: array('type': 352),
						2: array('type': 295)
					))
				}
			)
			bind('item_pickup', array('id': 'fwpickup'), array('item': 296), @e,
				if(_fw_player(player())
				&& _fw_changeteam(player(), 'winners')) {
					play_sound(ploc(), array('sound': 'zombie_metal'), player())
				}
			)
			
		, 'end',
			unbind('fwpickup')
			foreach(all_players(), @p,
				if(_fw_player(@p)) {
					_clear_pinv(@p)
				}
			)
			proc('_set_air', @x, @y, @z,
				if(get_block_at(array(@x, @y, @z, 'custom')) != '0:0') {
					set_block_at(array(@x, @y, @z, 'custom'), '0:0')
				}
			)
			@region = sk_region_info('frogware', 'custom')[0]
			queue_push(closure(
				_iterate_cuboid(array(@region[0][0], @region[1][1], @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1], @region[1][2], 'custom'),
				'_set_air')
			), 'fw3')
			queue_push(closure(
				_fw_startround(@secs)
			), 'fw3')
			
		)
		
	, 'koth',
		switch(@state
		, 'start',
			_regionmsg('frogware', color('green').'[FROGWARE] '.color('r').'King of the Hill')
			if(rand(8) < 1) {
				_fw_mobs()
			}
			proc('_set_hill', @x, @y, @z,
				if(get_block_at(array(@x, @y, @z, 'custom')) != '35:15') {
					set_block_at(array(@x, @y, @z, 'custom'), '35:5')
				}
			)
			@loc = _fw_loc()
			_iterate_cuboid(array(@loc[0] + 1, @loc[1], @loc[2] + 1, 'custom'),
			array(@loc[0] - 1, @loc[1], @loc[2] - 1, 'custom'),
			'_set_hill')
			
		, 'end',
			foreach(all_players(), @p,
				if(_fw_player(@p)
				&& get_block_at(ploc(@p)) == '35:5'
				&& _fw_changeteam(@p, 'winners')) {
					play_sound(ploc(@p), array('sound': 'zombie_metal'), @p)
				}
			)
			_remove_region_mobs('frogware')
			proc('_set_air', @x, @y, @z,
				if(get_block_at(array(@x, @y, @z, 'custom')) != '0:0') {
					set_block_at(array(@x, @y, @z, 'custom'), '0:0')
				}
			)
			@region = sk_region_info('frogware', 'custom')[0]
			queue_push(closure(
				_iterate_cuboid(array(@region[0][0], @region[1][1], @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1], @region[1][2], 'custom'),
				'_set_air')
			), 'fw3')
			queue_push(closure(
				_fw_startround(@secs)
			), 'fw3')
		
		)
	
	, 'cake',
		switch(@state
		, 'start',
			_regionmsg('frogware', color('green').'[FROGWARE] '.color('r').'Let there be cake!')
			for(@i = 0, @i < max(1, floor(_fw_totalplayers() / 2)), @i++,
				set_block_at(_fw_loc(), '92:0')
			)
			bind('player_interact', array('id': 'fwcake'), array('block': 92, 'button': 'right'), @e,
				if(_fw_player(player())
				&& _fw_changeteam(player(), 'winners')) {
					play_sound(ploc(), array('sound': 'zombie_metal'), player())
				}
			)
		
		, 'end',
			unbind('fwcake')
			_fw_startround(@secs)
		)
	
	, 'fall',
		switch(@state
		, 'start',
			_regionmsg('frogware', color('green').'[FROGWARE] '.color('r').'Look out below!')
			foreach(all_players(), @p,
				if(_fw_player(@p)) {
					set_pvelocity(@p, 0, 3, 0)
					play_sound(ploc(@p), array('sound': 'ghast_fireball'), @p)
				}
			)
			proc('_set_green', @x, @y, @z,
				if(rand(100) < 3, set_block_at(array(@x, @y, @z, 'custom'), '35:5'))
			)
			@region = sk_region_info('frogware', 'custom')[0]
			queue_delay(500, 'fw3')
			queue_push(closure(
				_iterate_cuboid(array(@region[0][0], @region[1][1] + 2, @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 2, @region[1][2], 'custom'),
				'_set_green')
			), 'fw3')
		
		, 'end',
			foreach(all_players(), @p,
				if(_fw_player(@p)
				&& get_block_at(ploc(@p)) == '35:5'
				&& _fw_changeteam(@p, 'winners')) {
					play_sound(ploc(@p), array('sound': 'zombie_metal'), @p)
				}
			)
			proc('_set_air', @x, @y, @z,
				if(get_block_at(array(@x, @y, @z, 'custom')) != '0:0') {
					set_block_at(array(@x, @y, @z, 'custom'), '0:0')
				}
			)
			@region = sk_region_info('frogware', 'custom')[0]
			queue_push(closure(
				_iterate_cuboid(array(@region[0][0], @region[1][1]+ 2, @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 2, @region[1][2], 'custom'),
				'_set_air')
			), 'fw3')
			queue_push(closure(
				_fw_startround(@secs)
			), 'fw3')
		
		)
		
	, 'cluck',
		switch(@state
		, 'start',
			_regionmsg('frogware', color('green').'[FROGWARE] '.color('r').'Shoot 3 chickens!')
			foreach(all_players(), @p,
				if(_fw_player(@p)) {
					set_pinv(@p, array(
						0: array('type': 261, 'enchants': array(array('elevel': 3, 'etype': 'ARROW_DAMAGE'))),
						1: array('type': 262, 'qty': 8)
					))
					play_sound(ploc(@p), array('sound': 'chicken_idle'), @p)
				}
			)
			for(@i = 0, @i < (_fw_totalplayers() * 5), @i++,
				spawn_mob('chicken', 1, _fw_loc(18))
			)
			bind('entity_death', array('id': 'fwcluck'), array('type': 'CHICKEN'), @e,
				if(array_index_exists(@e['cause'], 'shooter')
				&& !is_numeric(@e['cause']['shooter']) 
				&& _fw_player(@e['cause']['shooter'])) {
					modify_event('xp', 0)
					set_pexp(@e['cause']['shooter'], pexp(@e['cause']['shooter']) + 33)
					if(pexp(@e['cause']['shooter']) > 90
					&& _fw_changeteam(@e['cause']['shooter'], 'winners')) {
						play_sound(ploc(@e['cause']['shooter']), array('sound': 'zombie_metal'), @e['cause']['shooter'])
					}
				}
			)
		
		, 'end',
			unbind('fwcluck')
			foreach(all_players(), @p,
				if(_fw_player(@p)) {
					set_pexp(@p, 0)
				}
			)
			_remove_region_mobs('frogware')
			_fw_startround(@secs)
		
		)
	
	)
)