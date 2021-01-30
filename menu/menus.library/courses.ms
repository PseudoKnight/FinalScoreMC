@tiers = array(
	array(
		'name': 'easy',
		'chatcolor': color('aqua'),
		'dyecolor': 'LIGHT_BLUE',
	),
	array(
		'name': 'easy-medium',
		'chatcolor': color('green'),
		'dyecolor': 'LIME',
	),
	array(
		'name': 'medium',
		'chatcolor':color('yellow'),
		'dyecolor': 'YELLOW',
	),
	array(
		'name': 'medium-hard',
		'chatcolor': color('gold'),
		'dyecolor': 'ORANGE',
	),
	array(
		'name': 'hard',
		'chatcolor': color('dark_red'),
		'dyecolor': 'RED',
	),
	array(
		'name': 'very-hard',
		'chatcolor': color('dark_purple'),
		'dyecolor': 'PURPLE',
	),
	array(
		'name': 'other',
		'chatcolor': color('white'),
		'dyecolor': 'WHITE',
	),
);
foreach(@tier in @tiers) {
	@tier['coop'] = array();
	@tier['parkour'] = array();
}

@solo1 = @main[];
@solo1[@rows * 9 + 2]['name'] = 'LIGHT_BLUE_WOOL';

@solo2 = @main[];
@solo2[@rows * 9 + 3]['name'] = 'PURPLE_WOOL';

@coop = @main[];
@coop[@rows * 9 + 4]['name'] = 'ORANGE_WOOL';

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
	'title': 'Cooperative Courses',
	'inv': associative_array(),
);

@cakes = get_value('cakeinfo');
foreach(@name: @cake in @cakes) {
	if(@cake['type'] === 'challenge' || @cake['type'] == 'coop') {
		@lore = array();
		@t = -1;
		if(array_index_exists(@cake, 'difficulty')) {
			foreach(@t: @this in @tiers) {
				if(@this['name'] == @cake['difficulty']) {
					@lore[] = @tiers[@t]['chatcolor'].color('l').to_upper(@cake['difficulty']);
					break();
				}
			}
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
				@lore[] = color('green').'Top 20 time: ' . @time;
			}
		}
		@lore[] = color('dark_gray').'Run: /warp '.@name;
		if(@cake['type'] == 'challenge') {
			@coins = @cake['coins'];
			if(array_index_exists(@tiers[@t]['parkour'], @coins)) {
				@coins++
			}
			@tiers[@t]['parkour'][@coins] = array(
				'name': @tiers[@t]['dyecolor'].'_STAINED_GLASS_PANE',
				'meta': array(
					'display': color('green').to_upper(@name),
					'lore': @lore,
				),
			);
		} else {
			@coins = @cake['coins'];
			if(array_index_exists(@tiers[@t]['coop'], @coins)) {
				@coins++
			}
			@tiers[@t]['coop'][@coins] =  array(
				'name': @tiers[@t]['dyecolor'].'_STAINED_GLASS_PANE',
				'meta': array(
					'display': color('green').to_upper(@name),
					'lore': @lore,
				),
			);
		}
	}
}
@coopSlot = 0;
foreach(@t: @tier in @tiers) {
	// solo
	@slot = @t * 9;
	if(@slot < floor(array_size(@tiers) / 2) * 9) {
		foreach(@item in @tier['parkour']) {
			@soloMenu1['inv'][@slot] = @item;
			@slot++;
		}
	} else {
		foreach(@item in @tier['parkour']) {
			@soloMenu2['inv'][@slot - floor(array_size(@tiers) / 2) * 9] = @item;
			@slot++;
		}
	}

	// coop
	foreach(@item in @tier['coop']) {
		@coopMenu['inv'][@coopSlot++] = @item;
	}
}

// Clear environment
@tiers = null;

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
	create_virtual_inventory(@player.@import['id'], 4 * 9 + 9, @import['title'], @menu);
	popen_inventory(@player, @player.@import['id']);
}
@soloMenu1['loadMenu'] = @loadMenu;
@soloMenu2['loadMenu'] = @loadMenu;
@coopMenu['loadMenu'] = @loadMenu;

export('menu.solo1', @soloMenu1);
export('menu.solo2', @soloMenu2)
export('menu.coop', @coopMenu);
