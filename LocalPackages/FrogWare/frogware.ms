proc('_fw_startgame',
	_fw_startround()
	bind('entity_damage', array('id': 'fwdamage'), array('type': 'PLAYER'), @e,
		if(get_pscoreboard(@e['player']) == 'fw') {
			modify_event('amount', 0)
		}
	)
)

proc('_fw_endgame', @winners,
	unbind('fwdamage')
	_regionmsg('frogware', color('green').'[FROGWARE] '.color('r').'Best frog'.if(array_size(@winners) > 1, 's').' in the house: '.array_implode(@winners, ' & '))
	@warp = get_value('warp.park')
	foreach(get_teams('fw')[0]['players'], @p,
		if(get_pscoreboard(@p) == 'fw') {
			_warmuptp(3.7, @p, @warp['loc'], @warp['yaw'], @warp['pitch'])
		}
	)
	foreach(@winners, @p,
		acc_add(@p, get_teams('fw')[0]['size'])
		tmsg(@p, color('6').'+'.get_teams('fw')[0]['size'].' coins')
	)
	remove_scoreboard('fw')
)

proc('_fw_startround', @secs = 9,
	@winners = array()
	@count = 0
	foreach(get_teams('fw')[0]['players'], @p,
		if(get_pscoreboard(@p) == 'fw'
		&& array_contains(sk_current_regions(@p), 'frogware')) {
			if(pexp(@p) > 90,
				set_pscore('score', @p, get_pscore('score', @p, 'fw') + 1, 'fw')
				set_pexp(@p, 0)
				@count++
			)
			if(get_pscore('score', @p, 'fw') == 20, array_push(@winners, @p))
		} else {
			team_remove_player('players', @p, 'fw')
		}
	)
	if(@winners) {
		_fw_endgame(@winners)
		return()
	}
	if(@count == get_teams('fw')[0]['size']) {
		@secs--
	} else if(@count == 0) {
		@secs++
	}
	@tasks = array('climb', 'keepaway', 'harvest', 'koth', 'cake')
	@task = @tasks[rand(array_size(@tasks))]
	queue_delay(1000, 'fw')
	queue_push(closure(
		_fw_task(@task, 'start', @secs)
	), 'fw')
	for(@i = @secs, @i >= 0, @i--,
		if(@i > 0) {
			queue_push(closure(
				_fw_countdown(@i)
			), 'fw')
			queue_delay(1000, 'fw')
		} else {
			queue_push(closure(
				_fw_countdown(@i)
				_fw_task(@task, 'end', @secs)
			), 'fw')
		}
	)
)

proc('_fw_countdown', @c,
	set_objective_display('score', color('a').color('l').@c, 'fw')
	if(@c < 4 && @c > 0) {
		foreach(get_teams('fw')[0]['players'], @p,
			play_sound(ploc(@p), array('sound': 'click', 'pitch': 2), @p)
		)
	} else if(@c == 0) {
		foreach(get_teams('fw')[0]['players'], @p,
			play_sound(ploc(@p), array('sound': 'orb_pickup'), @p)
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

proc('_fw_sound', @event, @loc,
	switch(@event
	, 'success',
		play_sound(@loc, array('sound': 'zombie_metal'))
	, 'fail',
		play_sound(@loc, array('sound': 'irongolem_death', 'pitch': 2))
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
				_iterate_cuboid(array(@region[0][0], @region[1][1], @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1], @region[1][2], 'custom'),
				'_set_green')
			), 'fw2')
			queue_push(closure(
				_iterate_cuboid(array(@region[0][0], @region[1][1] + 1, @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 1, @region[1][2], 'custom'),
				'_set_blue')
			), 'fw2')
			queue_push(closure(
				_iterate_cuboid(array(@region[0][0], @region[1][1] + 2, @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 2, @region[1][2], 'custom'),
				'_set_red')
			), 'fw2')
				
		, 'end',
			foreach(get_teams('fw')[0]['players'], @p,
				if(get_pscoreboard(@p) == 'fw'
				&& get_block_at(ploc(@p)) == '35:14') {
					set_pexp(@p, 99)
					_fw_sound('success', ploc(@p))
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
			), 'fw2')
			queue_push(closure(
				_fw_startround(@secs)
			), 'fw2')
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
				if(get_pscoreboard(player()) == 'fw') {
					modify_event('message', color('green').'[FROGWARE] '.color('r').@e['message'])
					if(to_lower(@e['message']) == to_lower(@quote)) {
						set_pexp(player(), 99)
						_fw_sound('success', ploc())
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
				&& get_pscoreboard(@e['player']) == 'fw'
				&& is_numeric(@e['damager'])
				&& pexp(@e['player']) > 90) {
					set_pexp(@e['player'], 0)
					_fw_sound('fail', ploc(@e['player']))
				}
			)
			foreach(get_teams('fw')[0]['players'], @p,
				if(get_pscoreboard(@p) == 'fw') {
					set_pexp(@p, 99)
				}
			)
			
		, 'end',
			foreach(get_teams('fw')[0]['players'], @p,
				if(get_pscoreboard(@p) == 'fw'
				&& pexp(@p) > 90) {
					_fw_sound('success', ploc(@p))
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
			foreach(get_teams('fw')[0]['players'], @p,
				if(get_pscoreboard(@p) == 'fw') {
					set_pinv(@p, array(
						0: array('type': 291),
						1: array('type': 352),
						2: array('type': 295)
					))
				}
			)
			bind('item_pickup', array('id': 'fwpickup'), array('item': 296), @e,
				if(get_pscoreboard(player()) == 'fw'
				&& pexp(player()) < 90) {
					set_pexp(player(), 99)
					_fw_sound('success', ploc())
				}
			)
			
		, 'end',
			unbind('fwpickup')
			foreach(get_teams('fw')[0]['players'], @p,
				if(get_pscoreboard(@p) == 'fw') {
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
			), 'fw2')
			queue_push(closure(
				_fw_startround(@secs)
			), 'fw2')
			
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
					set_block_at(array(@x, @y, @z, 'custom'), '35:14')
				}
			)
			@loc = _fw_loc()
			_iterate_cuboid(array(@loc[0] + 1, @loc[1], @loc[2] + 1, 'custom'),
			array(@loc[0] - 1, @loc[1], @loc[2] - 1, 'custom'),
			'_set_hill')
			
		, 'end',
			foreach(get_teams('fw')[0]['players'], @p,
				if(get_pscoreboard(@p) == 'fw'
				&& get_block_at(ploc(@p)) == '152:0') {
					set_pexp(@p, 99)
					_fw_sound('success', ploc(@p))
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
			), 'fw2')
			queue_push(closure(
				_fw_startround(@secs)
			), 'fw2')
		
		)
	
	, 'cake',
		switch(@state
		, 'start',
			_regionmsg('frogware', color('green').'[FROGWARE] '.color('r').'Let there be cake!')
			for(@i = 0, @i < ceil(get_teams('fw')[0]['size'] / 2), @i++,
				set_block_at(_fw_loc(), '92:0')
			)
			bind('player_interact', array('id': 'fwcake'), array('block': 92, 'button': 'right'), @e,
				if(get_pscoreboard(player()) == 'fw'
				&& pexp(player()) < 90) {
					set_pexp(player(), 99)
					_fw_sound('success', ploc())
				}
			)
		
		, 'end',
			unbind('fwcake')
			_fw_startround(@secs)
			
		)
	
	)
)