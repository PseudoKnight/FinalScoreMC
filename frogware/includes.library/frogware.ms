proc('_fw_startgame', @pts,
	_fw_startround()
	bind('entity_damage', array('id': 'fwdamage'), array('type': 'PLAYER', 'world': 'custom'), @e,
		if(_fw_player(@e['player'])) {
			modify_event('amount', 0)
		}
	)
	_fw_msg('Game started. First to '.@pts.' points wins!')
	set_pscore('score', 'GOAL', @pts, 'fw')
)

proc('_fw_endgame', @winners,
	unbind('fwdamage')
	_fw_msg('Best frog'.if(array_size(@winners) > 1, 's').' in the house: '.array_implode(@winners, ' & '))
	@warp = get_value('warp.frogpark')
	foreach(@winners, @p,
		@coins = _fw_totalplayers()
		_acc_add(@p, @coins)
		tmsg(@p, color('6').'+'.@coins.' coins')
	)
	foreach(all_players('custom'), @p,
		if(_fw_player(@p)) {
			set_pscoreboard(@p)
			set_ploc(@p, @warp['loc'])
		}
	)
	if(array_contains(get_scoreboards(), 'fw')) { remove_scoreboard('fw') }
)

proc('_fw_startround', @secs = 9,
	if(pworld() != 'custom') {
		_fw_endgame(array())
		_fw_msg('Host left the game.')
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
					if(get_pscore('score', @p, 'fw') == get_pscore('score', 'GOAL', 'fw'), array_push(@winners, @p))
				} else {
					set_pscoreboard(@p)
					reset_all_pscores(@p, 'fw')
					_clear_pinv(@p)
				}
			}
		)
		if(array_size(@winners) > 0 || @total == 0) {
			_fw_endgame(@winners)
		} else {
			if((@total <= 2 && @count == @total)
			|| (@total > 2 && @count >= (@total - 1))) {
				@secs--
			} else if(@count == 0 || (@total > 2 && @count <= 1)) {
				@secs++
			}
			@tasks = array('climb', 'keepaway', 'harvest', 'koth', 'cake', 'fall', 'cluck', 'frogegg', 'lavafall', 'shepherd')
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
	set_objective_display('score', color(10).color('l').@c, 'fw')
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

proc('_2d_distance', @arr1, @arr2,
	return(floor(sqrt(((@arr2[0] - @arr1[0]) ** 2) + ((@arr2[2] - @arr1[2]) ** 2))))
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
		foreach(all_players('custom'), @p) {
			if(get_pscoreboard(@p) == 'fw'
			&& _2d_distance(ploc(@p), @loc) < 6) {
				@return = 0
				break()
			}
		}
	}
	if(@return == 1) {
		return(@loc)
	} else {
		return(null)
	}
)

proc('_fw_mobs',
	@mobs = array('creeper', 'zombie', 'silverfish', 'slime', 'magmacube', 'pigzombie:400', 'enderman', 'wolf:angry', 'giant')
	@mob = @mobs[rand(array_size(@mobs))]
	@num = rand(25, 50)
	@entities = array()
	for(@i = 0, @i < @num, @i++,
		if(@loc = _fw_loc(0, true), array_push(@entities, spawn_mob(@mob, 1, @loc)[0]))
	)
	if(!rand(4)) {
		set_timeout(50, closure(
			foreach(@entities, @entity,
				set_mob_effect(@entity, 1, rand(2), 15, true)
			)
		))
	}
)

proc('_fw_player', @player,
	if(ponline(@player)
	&& pworld(@player) == 'custom'
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
		'speed': array(1, 17),
		'jump': array(8, 12),
		'invis': array(14, 1),
		'blind': array(15, 1)
	)
	@potion = array_rand(@potentials, 1, false)
	foreach(all_players('custom'), @p,
		if(_fw_player(@p),
			set_peffect(@p, @potions[@potion[0]][0], @potions[@potion[0]][1], @secs))
	)
)

proc('_fw_msg', @msg,
	_regionmsg('frogware', color('green').'[FROGWARE] '.color('r').@msg)
)

proc('_fw_task', @task, @state, @secs,
	switch(@task
	, 'climb',
		switch(@state
		, 'start',
			_fw_msg('Climb.')
			if(!rand(6)) {
				_fw_randompotion(array('speed', 'jump', 'blind'))
			}
			if(!rand(6)) {
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
					_clear_peffects(@p)
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
		
	, 'keepaway',
		switch(@state
		, 'start',
			_fw_msg('Look out!')
			if(!rand(6)) {
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
					_clear_peffects(@p)
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
			_fw_msg('Bring in the harvest!')
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
			_remove_region_entities('frogware', array('DROPPED_ITEM'))
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
			_fw_msg('King of the Hill')
			if(!rand(6)) {
				_fw_randompotion(array('speed', 'jump'))
			}
			if(!rand(6)) {
				_fw_mobs()
			}
			if(!rand(6)) {
				foreach(all_players('custom'), @p,
					if(_fw_player(@p)) {
						set_pinv(@p, array(
							0: array('type': 40, 'enchants': array(array('etype': 'KNOCKBACK', 'elevel': 10)))
						))
					}
				)
			}
			proc('_set_base', @x, @y, @z,
				if(get_block_at(array(@x, @y, @z, 'custom')) == '0:0') {
					set_block_at(array(@x, @y, @z, 'custom'), '155:0')
				}
			)
			proc('_set_hill', @x, @y, @z,
				if(get_block_at(array(@x, @y, @z, 'custom')) == '0:0') {
					set_block_at(array(@x, @y, @z, 'custom'), '133:0')
				}
			)
			@loc = _fw_loc()
			_iterate_cuboid(array(@loc[0] + 2, @loc[1], @loc[2] + 2, 'custom'),
			array(@loc[0] - 2, @loc[1], @loc[2] - 2, 'custom'),
			'_set_base')
			_iterate_cuboid(array(@loc[0] + 1, @loc[1] + 1, @loc[2] + 1, 'custom'),
			array(@loc[0] - 1, @loc[1] + 1, @loc[2] - 1, 'custom'),
			'_set_hill')
			
		, 'end',
			foreach(all_players('custom'), @p,
				if(_fw_player(@p)) {
					_clear_peffects(@p)
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
				_iterate_cuboid(array(@region[0][0], @region[1][1], @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 1, @region[1][2], 'custom'),
				'_set_air')
			), 'fw3')
			queue_push(closure(
				_fw_startround(@secs)
			), 'fw3')
		
		)
	
	, 'cake',
		switch(@state
		, 'start',
			_fw_msg('Let there be cake!')
			if(!rand(6)) {
				_fw_randompotion(array('speed'))
			}
			for(@i = 0, @i < max(1, floor(_fw_totalplayers() / 2)), @i++,
				set_block_at(_fw_loc(), '92:0')
			)
			bind('player_interact', array('id': 'fwcake'), array('block': 92), @e,
				if(_fw_player(player())
				&& _fw_changeteam(player(), 'winners')) {
					play_sound(ploc(), array('sound': 'zombie_metal'), player())
				}
			)
		
		, 'end',
			foreach(all_players('custom'), @p,
				if(_fw_player(@p)) {
					_clear_peffects(@p)
				}
			)
			unbind('fwcake')
			_fw_startround(@secs)
		)
	
	, 'fall',
		switch(@state
		, 'start',
			_fw_msg('Alls well that falls well.')
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
			if(!rand(6), @mob = 'BAT', @mob = 'CHICKEN')
			_fw_msg('Shoot '.if(@mob == 'BAT', '1', '3').'!')
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
				&& ponline(@e['cause']['shooter'])
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
			_fw_msg('Pop the frog egg!')
			@loc = _fw_loc()
			set_block_at(@loc, '122:0')
			if(!rand(6)) {
				_fw_mobs()
			}
			if(!rand(4)) {
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
			_fw_msg('Last hit.')
			_fw_randompotion(array('speed', 'jump', 'blind', 'invis'))
			if(!rand(4)) {
				@enchants = array(
					array('etype': 'KNOCKBACK', 'elevel': 10)
				)
			} else {
				@enchants = array()
			}
			foreach(all_players('custom'), @p,
				if(_fw_player(@p)) {
					set_pinv(@p, array(
						0: array('type': 267, 'enchants': @enchants)
					))
				}
			)
			bind('entity_damage', array('id': 'fwdamage2'), array('type': 'PLAYER', 'cause': 'ENTITY_ATTACK', 'world': 'custom'), @e,
				if(_fw_player(@e['player'])
				&& _fw_player(@e['damager'])) {
					if(_fw_changeteam(@e['damager'], 'winners')) {
						play_sound(ploc(), array('sound': 'zombie_metal'), player())
					}
					_fw_changeteam(@e['player'], 'losers')
					play_sound(ploc(@e['player']), array('sound': 'zombie_unfect'), @e['player'])
					
				}
			)
			
		, 'end',
			foreach(all_players('custom'), @p,
				if(_fw_player(@p)) {
					_clear_peffects(@p)
					_clear_pinv(@p)
				}
			)
			unbind('fwdamage2')
			_fw_startround(@secs)
		
		)
	
	, 'lavafall',
		switch(@state
		, 'start',
			_fw_msg('The lava is lava')
			if(!rand(5)) {
				_fw_randompotion(array('speed', 'blind'))
			}
			if(!rand(5)) {
				_fw_mobs()
			}
			proc('_set_lava', @x, @y, @z,
				if(rand(100) < 3) {
					set_block_at(array(@x, @y, @z, 'custom'), '10:0')
				}
			)
			@region = sk_region_info('frogware', 'custom')[0]
			_iterate_cuboid(array(@region[0][0], @region[1][1] + 2, @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 2, @region[1][2], 'custom'),
				'_set_lava')
			bind('entity_damage', array('id': 'fwdamage2'), array('type': 'PLAYER', 'cause': 'LAVA', 'world': 'custom'), @e,
				if(_fw_player(@e['player'])) {
					_fw_changeteam(@e['player'], 'losers')
					play_sound(ploc(@e['player']), array('sound': 'zombie_unfect'), @e['player'])
				}
			)
			foreach(all_players('custom'), @p,
				if(_fw_player(@p)) {
					_fw_changeteam(@p, 'winners')
				}
			)
			
		, 'end',
			_remove_region_entities('frogware')
			foreach(all_players('custom'), @p,
				if(_fw_player(@p)) {
					_clear_peffects(@p)
					if(array_contains(get_teams('fw')[1]['players'], @p)) {
						play_sound(ploc(@p), array('sound': 'zombie_metal'), @p)
					}
				}
			)
			proc('_set_air', @x, @y, @z,
				if(get_block_at(array(@x, @y, @z, 'custom')) != '0:0') {
					set_block_at(array(@x, @y, @z, 'custom'), '0:0')
				}
			)
			@region = sk_region_info('frogware', 'custom')[0]
			_iterate_cuboid(array(@region[0][0], @region[1][1], @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 2, @region[1][2], 'custom'),
				'_set_air')
				
			unbind('fwdamage2')
			_fw_startround(@secs)
		)
		
	, 'shepherd',
		switch(@state
		, 'start',
			@colors = array('WHITE', 'ORANGE', 'MAGENTA', 'LIGHT_BLUE', 'YELLOW', 'LIME', 'PINK', 'GRAY', 'SILVER', 'CYAN', 'PURPLE', 'BLUE', 'BROWN', 'GREEN', 'RED', 'BLACK')
			@colorindex = rand(array_size(@colors))
			_fw_msg(@colors[@colorindex].color('r').' is the new black')
			@count = min(_fw_totalplayers() * 30, 200)
			@region = sk_region_info('frogware', 'custom')[0]
			for(@i = 0, @i < @count, @i++) {
				spawn_mob('SHEEP:'.@colors[rand(16)], 1, _fw_loc())
			}
			bind('item_pickup', array('id': 'fwpickup'), array('item': 35), @e, @data = @colors[@colorindex]) {
				if(_fw_player(@e['player'])) {
					@xp = pexp(@e['player'])
					if(@xp < 99) {
						@xp = min(@xp + (33 * @e['item']['qty']), 99)
						set_pexp(@e['player'], @xp)
						if(@xp >= 99) {
							if(_fw_changeteam(player(), 'winners')) {
								play_sound(ploc(), array('sound': 'zombie_metal'), player())
							}
						}
					}
				}
			}
			foreach(all_players('custom'), @p) {
				if(_fw_player(@p)) {
					set_pinv(@p, array(
						0: array('type': 359)
					))
				}
			}
			
		
		, 'end',
			foreach(all_players('custom'), @p) {
				if(_fw_player(@p)) {
					_clear_pinv(@p)
				}
			}
			_remove_region_entities('frogware')
			unbind('fwpickup')
			_fw_startround(@secs)
		)
	
	)
)