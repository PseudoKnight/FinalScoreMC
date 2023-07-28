@tiers = array(
	array(
		name: 'easy',
		chatcolor: color('aqua'),
		dyecolor: 'LIGHT_BLUE',
	),
	array(
		name: 'easy-medium',
		chatcolor: color('green'),
		dyecolor: 'LIME',
	),
	array(
		name: 'medium',
		chatcolor: color('yellow'),
		dyecolor: 'YELLOW',
	),
	array(
		name: 'medium-hard',
		chatcolor: color('gold'),
		dyecolor: 'ORANGE',
	),
	array(
		name: 'hard',
		chatcolor: color('dark_red'),
		dyecolor: 'RED',
	),
	array(
		name: 'very-hard',
		chatcolor: color('dark_purple'),
		dyecolor: 'PURPLE',
	),
	array(
		name: 'other',
		chatcolor: color('white'),
		dyecolor: 'WHITE',
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
	menu: @solo1,
	id: 'easy-courses',
	title: 'Easier Solo Courses',
	inv: associative_array(),
);
@soloMenu2 = array(
	menu: @solo2,
	id: 'hard-courses',
	title: 'Harder Solo Courses',
	inv: associative_array(),
);
@coopMenu = array(
	menu: @coop,
	id: 'coop-courses',
	title: 'Cooperative Courses',
	inv: associative_array(),
);

@cakes = get_value('cakeinfo');
foreach(@name: @cake in @cakes) {
	if(@cake['type'] === 'challenge' || @cake['type'] == 'coop') {
		@lore = array();
		@t = -1;
		if(array_index_exists(@cake, 'difficulty')) {
			foreach(@t: @this in @tiers) {
				if(@this['name'] == @cake['difficulty']) {
					@lore[] = @tiers[@t]['chatcolor'].color('bold').to_upper(@cake['difficulty'])
							.' '.color('gold').'('.@cake['coins'].' coins)';
					break();
				}
			}
		}
		@lore[] = color('gray').'Achieved by '.array_size(@cake['players']).' players';
		if(@cake['type'] == 'challenge') {
			@times = get_value('times', @name);
			if(@times) {
				@playerName = _pdata_by_uuid(@times[0][0])['name'];
				@time = @times[0][2];
				if(@time > 3600) {
					@time = '1 hour';
				} else if(@time >= 60) {
					@time = simple_date('m\u0027m\u0027 s.S', integer(@time * 1000));
					@time = substr(@time, 0, length(@time) - 2).'s';
				} else {
					@time = simple_date('s.S', integer(@time * 1000));
					@time = substr(@time, 0, length(@time) - 2).'s';
				}
				@lore[] = color('gray').'Best time: ' . @time . ' by '.@playerName;
			}
		}
		if(@cake['type'] == 'challenge') {
			@coins = @cake['coins'];
			if(array_index_exists(@tiers[@t]['parkour'], @coins)) {
				@coins++
			}
			@tiers[@t]['parkour'][@coins] = array(
				name: @tiers[@t]['dyecolor'].'_STAINED_GLASS',
				meta: array(
					display: @tiers[@t]['chatcolor'].to_upper(@name),
					lore: @lore,
				),
			);
		} else {
			@coins = @cake['coins'];
			if(array_index_exists(@tiers[@t]['coop'], @coins)) {
				@coins++
			}
			@tiers[@t]['coop'][@coins] =  array(
				name: @tiers[@t]['dyecolor'].'_STAINED_GLASS',
				meta: array(
					display: @tiers[@t]['chatcolor'].to_upper(@name),
					lore: @lore,
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
	if(!has_inventory(@player.@import['id'])) {
		@uuid = puuid(@player, true);
		@cakes = get_value('cakeinfo');
		@menu = @import['menu'][];
		foreach(@slot: @item in @import['inv']) {
			@name = to_lower(substr(@item['meta']['display'], 2));
			if(array_index_exists(@cakes[@name]['players'], @uuid)) {
				@item = @item[];
				@item['name'] = replace(@item['name'], '_STAINED_GLASS', '_CONCRETE');
				@times = get_value('times', @name);
				if(@times) {
					@tied = 0;
					@previousTime = 0.0;
					foreach(@i: @time in @times) {
						if(@previousTime == @time[2]) {
							@tied++;
						} else {
							@previousTime = @time[2];
							@tied = 0;
						}
						if(@time[0] == @uuid) {
							@item['qty'] = @i + 1 - @tied;
							break();
						} else if(@i == 126) {
							break();
						}
					}
				}
				@item['meta']['lore'][] = color('dark_gray').'Run: /warp '.@name;
			}
			@menu[@slot] = @item;
		}
		create_virtual_inventory(@player.@import['id'], 4 * 9 + 9, @import['title'], @menu);
	}
	popen_inventory(@player, @player.@import['id']);
}
@soloMenu1['loadMenu'] = @loadMenu;
@soloMenu2['loadMenu'] = @loadMenu;
@coopMenu['loadMenu'] = @loadMenu;

export('menu.easy-courses', @soloMenu1);
export('menu.hard-courses', @soloMenu2)
export('menu.coop-courses', @coopMenu);
