@color = array(
	'easy': array('chat': 'aqua', 'data': 3),
	'easy-medium': array('chat': 'green', 'data': 5),
	'medium': array('chat': 'yellow', 'data': 4),
	'medium-hard': array('chat': 'gold', 'data': 1),
	'hard': array('chat': 'dark_red', 'data': 14),
	'very-hard': array('chat': 'dark_purple', 'data': 10),
	'other': array('chat': 'white', 'data': 0),
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

@solo = @main[];
@solo[59]['name'] = 'WOOL';

@coop = @main[];
@coop[60]['name'] = 'WOOL';

@soloMenu = array(
	'menu': @solo,
	'id': 'solo',
	'title': 'Solo Courses / Parkour',
	'inv': associative_array(),
);
@coopMenu = array(
	'menu': @coop,
	'id': 'coop',
	'title': 'Coop Courses / Parkour',
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
				if(@time >= 60) {
					@time = simple_date('m\u0027m\u0027 s.S', integer(@time * 1000));
				} else {
					@time = simple_date('s.S', integer(@time * 1000));
				}
				@time = substr(@time, 0, length(@time) - 2).'s';
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
				'name': 'STAINED_GLASS_PANE',
				'data': @color[@difficulty]['data'],
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
				'name': 'STAINED_GLASS_PANE',
				'data': @color[@difficulty]['data'],
				'meta': array(
					'display': color('green').to_upper(@name),
					'lore': @lore,
				),
			);
		}
	}
}
foreach(@i: @difficulty in @difficultyorder) {
	// solo
	@slot = @i * 9;
	foreach(@item in @difficulties[@difficulty]) {
		@soloMenu['inv'][@slot] = @item;
		@slot++;
	}
	// coop
	@slot = @i * 9;
	foreach(@item in @coopdifficulties[@difficulty]) {
		@coopMenu['inv'][@slot] = @item;
		@slot++;
	}
}

// Clear environment
@color = null;
@difficultyorder = null;
@difficulties = null;
@coopdifficulties = null;

@loadMenu = closure(@player, @import){
	@uuid = puuid(@player, true);
	@cakes = get_value('cakeinfo');
	@menu = @import['menu'][];
	foreach(@slot: @item in @import['inv']) {
		@name = to_lower(substr(@item['meta']['display'], 2));
		if(array_index_exists(@cakes[@name]['players'], @uuid)) {
			@item = @item[];
			@item['data'] = 0;
		}
		@menu[@slot] = @item;
	}
	delete_virtual_inventory(@import['id']);
	create_virtual_inventory(@import['id'], 63, @import['title'], @menu);
}
@soloMenu['loadMenu'] = @loadMenu;
@coopMenu['loadMenu'] = @loadMenu;

export('menu.solo', @soloMenu);
export('menu.coop', @coopMenu);
