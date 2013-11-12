proc('_fw_startgame',
	_fw_startround()
	bind('entity_damage', array('id': 'fwdamage'), array('type': 'PLAYER', 'world': 'custom'), @e,
		if(_fw_player(@e['player'])) {
			modify_event('amount', 0)
		}
	)
	_regionmsg('frogware', color('green').'[FROGWARE] '.color('r').'Game started. First to 25 points wins!')
)

proc('_fw_endgame', @winners,
	unbind('fwdamage')
	_regionmsg('frogware', color('green').'[FROGWARE] '.color('r').'Best frog'.if(array_size(@winners) > 1, 's').' in the house: '.array_implode(@winners, ' & '))
	@warp = get_value('warp.frogpark')
	foreach(all_players('custom'), @p,
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
	if(pworld() != 'custom') {
		_fw_endgame(array())
		_regionmsg('frogware', color('green').'[FROGWARE] '.color('r').'Host left the game.')
	}
	queue_delay(1000, 'fw')
	queue_push(closure(
		@winners = array()
		@count = 0
		@total = 0
		foreach(all_players('custom'), @p,
			if(_fw_player(@p)) {
				@total++
				if(array_contains(sk_current_regions(@p), 'frogware')) {
					foreach(get_teams('fw'), @team,
						if(@team['name'] == 'winners' 
						&& array_contains(@team['players'], @p)) {
							set_pscore('score', @p, get_pscore('score', @p, 'fw') + 1, 'fw')
							_fw_changeteam(@p, 'losers')
							@count++
						}
					)
					if(get_pscore('score', @p, 'fw') == 25, array_push(@winners, @p))
				} else {
					try(set_pscoreboard(@p, 'main'))
				}
			}
		)
		if(array_size(@winners) > 0 || @total == 0) {
			_fw_endgame(@winners)
		} else {
			if(((@total <= 2 && @count == @total)
			|| (@total > 2 && @count >= (@total - 1)))
			&& @secs > 5) {
				@secs--
			} else if(@count == 0 || (@total > 2 && @count <= 1)) {
				@secs++
			}
			@tasks = array('climb', 'keepaway', 'harvest', 'koth', 'cake', 'fall', 'cluck', 'frogegg', 'pvp')
			@task = @tasks[rand(array_size(@tasks))]
			if(@total == 1 && @task == 'pvp', @task = @tasks[rand(array_size(@tasks))])
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
		foreach(all_players('custom'), @p,
			if(_fw_player(@p)) {
				play_sound(ploc(@p), array('sound': 'click', 'pitch': 2), @p)
			}
		)
	} else if(@c == 0) {
		foreach(all_players('custom'), @p,
			if(_fw_player(@p)) {
				play_sound(ploc(@p), array('sound': 'orb_pickup'), @p)
			}
		)
	}
)

proc('_fw_loc', @height = 0, @minrange = false, @region = sk_region_info('frogware', 'custom')[0],
	@return = 1
	@loc = array(
		@region[0][0] - rand(sqrt((@region[0][0] - @region[1][0]) ** 2)) + 0.5, 
		@region[1][1] + @height, 
		@region[0][2] - rand(sqrt((@region[0][2] - @region[1][2]) ** 2)) + 0.5,
		'custom'
	)
	if(@minrange) {
			foreach(all_players('custom'), @p,
			if(get_pscoreboard(@p) == 'fw'
			&& _2d_distance(ploc(@p), @loc) < 6) {
				@return = 0
				break()
			}
		)
	}
	if(@return == 1) {
		return(@loc)
	} else {
		return(null)
	}
)

proc('_fw_mobs',
	@mobs = array('creeper', 'zombie', 'silverfish', 'slime', 'magmacube')
	@mob = @mobs[rand(array_size(@mobs))]
	@num = rand(25, 50)
	for(@i = 0, @i < @num, @i++,
		if(@loc = _fw_loc(0, true), spawn_mob(@mob, 1, @loc))
	)
)

proc('_fw_player', @player,
	if(pworld(@player) == 'custom'
	&& get_pscoreboard(@player) == 'fw') {
		return(true)
	} else {
		return(false)
	}
)

proc('_fw_totalplayers',
	@count = 0
	foreach(all_players('custom'), @p,
		if(get_pscoreboard(@p) == 'fw') {
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

proc('_fw_randompotion', @potentials, @secs = 20,
	@potions = array(
		'speed': array(1, 20),
		'jump': array(8, 15),
		'invis': array(14, 1),
		'blind': array(15, 1)
	)
	@potion = array_rand(@potentials, 1, false)
	foreach(all_players('custom'), @p,
		if(_fw_player(@p),
			set_peffect(@p, @potions[@potion[0]][0], @potions[@potion[0]][1], @secs))
	)
)

proc('_fw_task', @task, @state, @secs,
	switch(@task
	, 'climb',
		switch(@state
		, 'start',
			_regionmsg('frogware', color('green').'[FROGWARE] '.color('r').'Climb.')
			if(rand(7) < 1) {
				_fw_randompotion(array('speed', 'jump', 'blind'))
			}
			if(rand(7) < 1) {
				_fw_mobs()
			}
			proc('_set_emerald', @x, @y, @z,
				if(rand(100) < 3, set_block_at(array(@x, @y, @z, 'custom'), '133:0'))
			)
			proc('_set_diamond', @x, @y, @z,
				if(rand(100) < 4, set_block_at(array(@x, @y, @z, 'custom'), '57:0'))
			)
			proc('_set_gold', @x, @y, @z,
				if(rand(100) < 5, set_block_at(array(@x, @y, @z, 'custom'), '41:0'))
			)
			@region = sk_region_info('frogware', 'custom')[0]
			queue_push(closure(
				_iterate_cuboid(array(@region[0][0], @region[1][1], @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1], @region[1][2], 'custom'),
				'_set_gold')
			), 'fw3')
			queue_delay(500, 'fw3')
			queue_push(closure(
				_iterate_cuboid(array(@region[0][0], @region[1][1] + 1, @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 1, @region[1][2], 'custom'),
				'_set_diamond')
			), 'fw3')
			queue_delay(500, 'fw3')
			queue_push(closure(
				_iterate_cuboid(array(@region[0][0], @region[1][1] + 2, @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 2, @region[1][2], 'custom'),
				'_set_emerald')
			), 'fw3')
				
		, 'end',
			foreach(all_players('custom'), @p,
				if(_fw_player(@p)) {
					_remove_peffects(@p)
					if(get_block_at(ploc(@p)) == '133:0'
					&& _fw_changeteam(@p, 'winners')) {
						play_sound(ploc(@p), array('sound': 'zombie_metal'), @p)
					}
				}
			)
			_remove_region_entities('frogware')
			proc('_set_air', @x, @y, @z,
				if(get_block_at(array(@x, @y, @z, 'custom')) != '0:0') {
					set_block_at(array(@x, @y, @z, 'custom'), '0:0')
				}
			)
			@region = sk_region_info('frogware', 'custom')[0]
			queue_push(closure(
				_iterate_cuboid(array(@region[0][0], @region[1][1] + 2, @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 2, @region[1][2], 'custom'),
				'_set_air')
			), 'fw3')
			queue_delay(100, 'fw3')
			queue_push(closure(
				_iterate_cuboid(array(@region[0][0], @region[1][1] + 1, @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 1, @region[1][2], 'custom'),
				'_set_air')
			), 'fw3')
			queue_delay(100, 'fw3')
			queue_push(closure(
				_iterate_cuboid(array(@region[0][0], @region[1][1], @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1], @region[1][2], 'custom'),
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
					modify_event('recipients', all_players('custom'))
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
			if(rand(7) < 1) {
				_fw_randompotion(array('speed', 'jump', 'blind'))
			}
			_fw_mobs()
			bind('entity_damage', array('id': 'fwtaskdamage'), array('type': 'PLAYER', 'world': 'custom'), @e,
				if((@e['cause'] == 'ENTITY_ATTACK' || @e['cause'] == 'ENTITY_EXPLOSION')
				&& _fw_player(@e['player'])
				&& is_numeric(@e['damager'])) {
					_fw_changeteam(@e['player'], 'losers')
				}
			)
			foreach(all_players('custom'), @p,
				if(_fw_player(@p)) {
					_fw_changeteam(@p, 'winners')
				}
			)
			
		, 'end',
			foreach(all_players('custom'), @p,
				if(_fw_player(@p)) {
					_remove_peffects(@p)
					if(array_contains(get_teams('fw')[1]['players'], @p)) {
						play_sound(ploc(@p), array('sound': 'zombie_metal'), @p)
					}
				}
			)
			_remove_region_entities('frogware')
			unbind('fwtaskdamage')
			_fw_startround(@secs)
			
		)
		
	, 'harvest',
		switch(@state
		, 'start',
			_regionmsg('frogware', color('green').'[FROGWARE] '.color('r').'Bring in the harvest!')
			proc('_set_dirt', @x, @y, @z,
				if(rand(100) < 2) {
					set_block_at(array(@x, @y, @z, 'custom'), '3:0')
				} else if(rand(100) < 5) {
					drop_item(array(@x, @y, @z, 'custom'), array('type': 351, 'data': 15, 'qty': 1))
				}
			)
			@region = sk_region_info('frogware', 'custom')[0]
			_iterate_cuboid(array(@region[0][0], @region[1][1], @region[0][2], 'custom'),
			array(@region[1][0], @region[1][1], @region[1][2], 'custom'),
			'_set_dirt')
			foreach(all_players('custom'), @p,
				if(_fw_player(@p)) {
					set_pinv(@p, array(
						0: array('type': 291),
						1: array('type': 295)
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
			foreach(all_players('custom'), @p,
				if(_fw_player(@p)) {
					_clear_pinv(@p)
				}
			)
			_remove_region_items('frogware')
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
			if(rand(7) < 1) {
				_fw_randompotion(array('speed', 'jump'))
			}
			if(rand(7) < 1) {
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
			foreach(all_players('custom'), @p,
				if(_fw_player(@p)) {
					_remove_peffects(@p)
					if(get_block_at(ploc(@p)) == '35:5'
					&& _fw_changeteam(@p, 'winners')) {
						play_sound(ploc(@p), array('sound': 'zombie_metal'), @p)
					}
				}
			)
			_remove_region_entities('frogware')
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
			if(rand(7) < 1) {
				_fw_randompotion(array('speed'))
			}
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
			foreach(all_players('custom'), @p,
				if(_fw_player(@p)) {
					_remove_peffects(@p)
				}
			)
			unbind('fwcake')
			_fw_startround(@secs)
		)
	
	, 'fall',
		switch(@state
		, 'start',
			_regionmsg('frogware', color('green').'[FROGWARE] '.color('r').'Look out below!')
			foreach(all_players('custom'), @p,
				if(_fw_player(@p)) {
					set_pvelocity(@p, 0, 3, 0)
					play_sound(ploc(@p), array('sound': 'ghast_fireball'), @p)
				}
			)
			proc('_set_green', @x, @y, @z,
				if(rand(100) < 3, set_block_at(array(@x, @y, @z, 'custom'), '133:0'))
			)
			@region = sk_region_info('frogware', 'custom')[0]
			queue_delay(600, 'fw3')
			queue_push(closure(
				_iterate_cuboid(array(@region[0][0], @region[1][1] + 3, @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 3, @region[1][2], 'custom'),
				'_set_green')
			), 'fw3')
		
		, 'end',
			foreach(all_players('custom'), @p,
				if(_fw_player(@p)
				&& get_block_at(ploc(@p)) == '133:0'
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
				_iterate_cuboid(array(@region[0][0], @region[1][1] + 3, @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 3, @region[1][2], 'custom'),
				'_set_air')
			), 'fw3')
			queue_push(closure(
				_fw_startround(@secs)
			), 'fw3')
		
		)
		
	, 'cluck',
		switch(@state
		, 'start',
			if(rand(7) < 1, @mob = 'BAT', @mob = 'CHICKEN')
			_regionmsg('frogware', color('green').'[FROGWARE] '.color('r').'Shoot '.if(@mob == 'BAT', '1', '3').'!')
			foreach(all_players('custom'), @p,
				if(_fw_player(@p)) {
					set_pinv(@p, array(
						0: array('type': 261, 'enchants': array(array('elevel': 3, 'etype': 'ARROW_DAMAGE'))),
						1: array('type': 262, 'qty': 6)
					))
					play_sound(ploc(@p), array('sound': if(@mob == 'BAT', 'BAT_LOOP', 'chicken_idle')), @p)
				}
			)

			for(@i = 0, @i < (_fw_totalplayers() * 4), @i++,
				spawn_mob(@mob, 1, if(@mob == 'BAT', _fw_loc(8), _fw_loc(18)))
			)
			bind('entity_death', array('id': 'fwcluck'), array('type': @mob), @e, @mob = @mob,
				if(array_index_exists(@e['cause'], 'shooter')
				&& !is_numeric(@e['cause']['shooter']) 
				&& _fw_player(@e['cause']['shooter'])) {
					modify_event('xp', 0)
					if(@e['type'] == 'BAT') {
						set_pexp(@e['cause']['shooter'], 99)
					} else {
						set_pexp(@e['cause']['shooter'], pexp(@e['cause']['shooter']) + 33)
					}
					if(pexp(@e['cause']['shooter']) > 90
					&& _fw_changeteam(@e['cause']['shooter'], 'winners')) {
						play_sound(ploc(@e['cause']['shooter']), array('sound': 'zombie_metal'), @e['cause']['shooter'])
					}
				}
			)
		
		, 'end',
			unbind('fwcluck')
			foreach(all_players('custom'), @p,
				if(_fw_player(@p)) {
					set_pexp(@p, 0)
				}
			)
			_fw_startround(@secs)
		
		)
		
	, 'frogegg',
		switch(@state
		, 'start',
			_regionmsg('frogware', color('green').'[FROGWARE] '.color('r').'Click the frog egg!')
			@loc = _fw_loc()
			set_block_at(@loc, '122:0')
			if(rand(7) < 1) {
				_fw_mobs()
			}
			if(rand(7) < 1) {
				for(@i = 0, @i < 16, @i++,
					set_block_at(_fw_loc(), '49:0')
				)
			}
			play_sound(@loc, array('sound': 'CHICKEN_EGG_POP', 'volume': 3))
			bind('player_interact', array('id': 'fwegg', 'priority': 'high'), array('block': 122), @e,
				if(_fw_player(player())) {
					play_sound(@e['location'], array('sound': 'CHICKEN_EGG_POP', 'volume': 3))
					consume()
					if(_fw_changeteam(player(), 'winners')) {
						play_sound(ploc(), array('sound': 'zombie_metal'), player())
					}
				}
			)
			
		, 'end',
			unbind('fwegg')
			_remove_region_entities('frogware')
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
		
	, 'pvp',
		switch(@state
		, 'start',
			_regionmsg('frogware', color('green').'[FROGWARE] '.color('r').'Hit but don\'t be hit!')
			_fw_randompotion(array('speed', 'jump', 'blind', 'invis'))
			bind('entity_damage', array('id': 'fwdamage2'), array('type': 'PLAYER', 'cause': 'ENTITY_ATTACK', 'world': 'custom'), @e,
				if(_fw_player(@e['player'])
				&& _fw_player(@e['damager'])) {
					if(_fw_changeteam(@e['damager'], 'winners')) {
						play_sound(ploc(), array('sound': 'zombie_metal'), player())
					}
					_fw_changeteam(@e['player'], 'losers')
				}
			)
			
		, 'end',
			foreach(all_players('custom'), @p,
				if(_fw_player(@p)) {
					_remove_peffects(@p)
				}
			)
			unbind('fwdamage2')
			_fw_startround(@secs)
		
		)
		
	)
)