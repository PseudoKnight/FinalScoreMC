@color = array(
	'easy': array('chat': 'aqua', 'dye': 'LIGHT_BLUE'),
	'easy-medium': array('chat': 'green', 'dye': 'LIME'),
	'medium': array('chat': 'yellow', 'dye': 'YELLOW'),
	'medium-hard': array('chat': 'gold', 'dye': 'ORANGE'),
	'hard': array('chat': 'dark_red', 'dye': 'RED'),
	'very-hard': array('chat': 'dark_purple', 'dye': 'PURPLE'),
	'other': array('chat': 'white', 'dye': 'WHITE'),
);
@difficultyorder = array('easy', 'easy-medium', 'medium', 'medium-hard', 'hard', 'very-hard', 'other');
@difficulties = array(
	'easy': array(),
	'easy-medium': array(),
	'medium': array(),
	'medium-hard': array(),
	'hard': array(),
	'very-hard': array(),
	'other': array(),
);
@coopdifficulties = array(
	'easy': array(),
	'easy-medium': array(),
	'medium': array(),
	'medium-hard': array(),
	'hard': array(),
	'very-hard': array(),
	'other': array(),
);

@solo1 = @main[];
@solo1[29]['name'] = 'LIGHT_BLUE_WOOL';

@solo2 = @main[];
@solo2[30]['name'] = 'PURPLE_WOOL';

@coop = @main[];
@coop[31]['name'] = 'ORANGE_WOOL';

@soloMenu1 = array(
	'menu': @solo1,
	'id': 'solo1',
	'title': 'Easier Solo Courses',
	'inv': associative_array(),
);
@soloMenu2 = array(
	'menu': @solo2,
	'id': 'solo2',
	'title': 'Harder Solo Courses',
	'inv': associative_array(),
);
@coopMenu = array(
	'menu': @coop,
	'id': 'coop',
	'title': 'Coop Courses',
	'inv': associative_array(),
);

@cakes = get_value('cakeinfo');
foreach(@name: @cake in @cakes) {
	if(@cake['type'] === 'challenge' || @cake['type'] == 'coop') {
		@lore = array();
		@difficulty = 'other';
		if(array_index_exists(@cake, 'difficulty')) {
			@difficulty = @cake['difficulty'];
			@lore[] = color(@color[@difficulty]['chat']).color('l').to_upper(@cake['difficulty']);
		}
		@lore[] = color('gold').@cake['coins'].' coins';
		@lore[] = color('green').'Achieved by '.array_size(@cake['players']).' players';
		if(@cake['type'] == 'challenge') {
			@times = get_value('times', @name);
			if(@times) {
				@time = @times[-1][2];
				if(@time > 3600) {
					@time = '1 hour';
				} else if(@time >= 60) {
					@time = simple_date('m\u0027m\u0027 s.S', integer(@time * 1000));
					@time = substr(@time, 0, length(@time) - 2).'s';
				} else {
					@time = simple_date('s.S', integer(@time * 1000));
					@time = substr(@time, 0, length(@time) - 2).'s';
				}
				@lore[] = color('green').'Time to beat: ' . @time;
			}
		}
		@lore[] = color('dark_gray').'Run: /warp '.@name;
		if(@cake['type'] == 'challenge') {
			@coins = @cake['coins'];
			if(array_index_exists(@difficulties[@difficulty], @coins)) {
				@coins++
			}
			@difficulties[@difficulty][@coins] = array(
				'name': @color[@difficulty]['dye'].'_STAINED_GLASS_PANE',
				'meta': array(
					'display': color('green').to_upper(@name),
					'lore': @lore,
				),
			);
		} else {
			@coins = @cake['coins'];
			if(array_index_exists(@coopdifficulties[@difficulty], @coins)) {
				@coins++
			}
			@coopdifficulties[@difficulty][@coins] =  array(
				'name': @color[@difficulty]['dye'].'_STAINED_GLASS_PANE',
				'meta': array(
					'display': color('green').to_upper(@name),
					'lore': @lore,
				),
			);
		}
	}
}
@coopSlot = 0;
foreach(@i: @difficulty in @difficultyorder) {
	// solo
	@slot = @i * 9;
	if(@slot < 27) {
		foreach(@item in @difficulties[@difficulty]) {
			@soloMenu1['inv'][@slot] = @item;
			@slot++;
		}
	} else {
		foreach(@item in @difficulties[@difficulty]) {
			@soloMenu2['inv'][@slot - 27] = @item;
			@slot++;
		}
	}

	// coop
	foreach(@item in @coopdifficulties[@difficulty]) {
		@coopMenu['inv'][@coopSlot++] = @item;
	}
}

// Clear environment
@color = null;
@difficultyorder = null;
@difficulties = null;
@coopdifficulties = null;

@loadMenu = iclosure(@player, @import){
	@uuid = puuid(@player, true);
	@cakes = get_value('cakeinfo');
	@menu = @import['menu'][];
	foreach(@slot: @item in @import['inv']) {
		@name = to_lower(substr(@item['meta']['display'], 2));
		if(array_index_exists(@cakes[@name]['players'], @uuid)) {
			@item = @item[];
			@item['name'] = 'WHITE_STAINED_GLASS_PANE';
		}
		@menu[@slot] = @item;
	}
	delete_virtual_inventory(@player.@import['id']);
	create_virtual_inventory(@player.@import['id'], 36, @import['title'], @menu);
	popen_inventory(@player, @player.@import['id']);
}
@soloMenu1['loadMenu'] = @loadMenu;
@soloMenu2['loadMenu'] = @loadMenu;
@coopMenu['loadMenu'] = @loadMenu;

export('menu.solo1', @soloMenu1);
export('menu.solo2', @soloMenu2)
export('menu.coop', @coopMenu);
