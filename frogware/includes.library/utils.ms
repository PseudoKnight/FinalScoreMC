proc _fw_countdown(@c) {
	set_objective_display('score', color(10).color('l').@c, 'fw')
	if(@c < 4 && @c > 0) {
		foreach(@p in all_players('custom')) {
			if(_fw_player(@p)) {
				play_sound(ploc(@p), array('sound': 'click', 'pitch': 2), @p)
			}
		}
	} else if(@c == 0) {
		foreach(@p in all_players('custom')) {
			if(_fw_player(@p)) {
				play_sound(ploc(@p), array('sound': 'orb_pickup'), @p)
			}
		}
	}
}

proc _2d_distance(@arr1, @arr2) {
	return(floor(sqrt(((@arr2[0] - @arr1[0]) ** 2) + ((@arr2[2] - @arr1[2]) ** 2))))
}

proc _fw_loc(@height = 0, @minrange = false) {
	@region = sk_region_info('frogware', 'custom')[0]
	@return = 1
	@loc = array(
		@region[0][0] - rand(sqrt((@region[0][0] - @region[1][0]) ** 2)) + 0.5, 
		@region[1][1] + @height, 
		@region[0][2] - rand(sqrt((@region[0][2] - @region[1][2]) ** 2)) + 0.5,
		'custom'
	)
	if(@minrange) {
		foreach(@p in all_players('custom')) {
			if(!ponline(@p), continue())
			if(get_pscoreboard(@p) === 'fw'
			&& _2d_distance(ploc(@p), @loc) < 6) {
				@return = 0
				break()
			}
		}
	}
	if(@return == 1) {
		return(@loc)
	}
}

proc _fw_mobs(@mob = 'random', @num = 'random') {
	if(@mob == 'random') {
		@mobs = array('creeper', 'zombie', 'silverfish', 'slime', 'magmacube', 'pigzombie:400', 'enderman', 'wolf:angry', 'giant')
		@mob = @mobs[rand(array_size(@mobs))]
	}
	if(@num == 'random') {
		@num = rand(25, 50)
	}
	@entities = array()
	for(@i = 0, @i < @num, @i++) {
		if(@loc = _fw_loc(0, true)) {
			@m = spawn_mob(@mob, 1, @loc)[0];
			array_push(@entities, @m);
			if(@mob == 'wolf:angry') {
				set_mob_target(@m, puuid(_fw_leader()));
			}
		}
	}
	if(!rand(4)) {
		queue_push(closure(){
			foreach(@entity in @entities) {
				set_mob_effect(@entity, 1, rand(2), 15, true)
			}
		})
	}
}

proc _fw_leader() {
	@top = 0;
	@leader = '';
	foreach(@p in all_players('custom')) {
		if(get_pscoreboard(@p) == 'fw') {
			@score = get_pscore('score', @p, 'fw')
			if(@score > @top) {
				@leader = @p;
				@top = @score;
			}
		}
	}
	return(@leader);
}

proc _fw_items(@item, @num) {
	for(@i = 0, @i < @num, @i++) {
		if(@loc = _fw_loc()) {
			drop_item(@loc, @item);
		}
	}
}

proc _fw_player(@player) {
	if(ponline(@player)
	&& pworld(@player) === 'custom'
	&& get_pscoreboard(@player) === 'fw') {
		return(true)
	} else {
		return(false)
	}
}

proc _fw_totalplayers() {
	@count = 0
	foreach(@p in all_players('custom')) {
		if(!ponline(@p), continue())
		if(get_pscoreboard(@p) === 'fw') {
			@count++
		}
	}
	return(@count)
}

proc _fw_changeteam(@player, @team) {
	switch(@team) {
	case 'losers':
		if(team_remove_player('winners', @player, 'fw')) {
			team_add_player('losers', @player, 'fw')
			return(true)
		} else {
			return(false)
		}
	case 'winners':
		if(team_remove_player('losers', @player, 'fw')) {
			team_add_player('winners', @player, 'fw')
			return(true)
		} else {
			return(false)
		}
	}
}

proc _fw_set_winners() {
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			_fw_changeteam(@p, 'winners')
		}
	}
}

proc _fw_randompotion(@potentials, @secs = 20) {
	@potions = array(
		'speed': array(1, 17),
		'jump': array(8, 12),
		'invis': array(14, 1),
		'blind': array(15, 1)
	)
	@potion = array_rand(@potentials, 1, false)
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			set_peffect(@p, @potions[@potion[0]][0], @potions[@potion[0]][1], @secs)
		}
	}
}

proc _fw_msg(@msg) {
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			title_msg(@p, null, @msg, 0, 40, 20);
		}
	}
}

#Given two blocks, iterates through all the blocks inside the cuboid, and calls the 
#user defined function on them. The used defined procedure should accept 3 parameters,
#the x, y, and z coordinates of the block.
proc _iterate_cuboid(@b1, @b2, @block, @percent) {
	@blocks = import('frogware.blocks');
	if(is_null(@blocks)) {
		@blocks = array();
	}
	for(@x = min(@b1[0], @b2[0]), @x <= max(@b1[0], @b2[0]), @x++) {
		for(@y = min(@b1[1], @b2[1]), @y <= max(@b1[1], @b2[1]), @y++) {
			for(@z = min(@b1[2], @b2[2]), @z <= max(@b1[2], @b2[2]), @z++) {
				if(rand(100) < @percent) {
					set_block_at(@x, @y, @z, @block, 'custom');
					@blocks[] = array(@x, @y, @z, 'custom');
				}
			}
		}
	}
	export('frogware.blocks', @blocks);
}

proc _fw_clear_blocks(@height = 1) {
	@region = sk_region_info('frogware', 'custom')[0];
	_iterate_cuboid(array(@region[0][0], @region[1][1], @region[0][2], 'custom'),
		array(@region[1][0], @region[1][1] + @height - 1, @region[1][2], 'custom'),
		0, 100);
}