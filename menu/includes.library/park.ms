proc _create_park_menu(){
	@main = associative_array(
		'id': 'main',
		'title': 'Frog Park Directory',
		'size': 63,
		57: associative_array(
			'name': 'IRON_SWORD',
			'meta': associative_array(
				'display': color('green').'PVP Arenas',
				'lore': array(color('dark_gray').'Open: pvp'),
				'flags': array('HIDE_ATTRIBUTES'),
			),
		),
		58: associative_array(
			'name': 'IRON_BLOCK',
			'meta': associative_array(
				'display': color('green').'Solo Courses / Parkour',
				'lore': array(color('dark_gray').'Open: courses'),
			),
		),
		59: associative_array(
			'name': 'IRON_LEGGINGS',
			'meta': associative_array(
				'display': color('green').'Other Games',
				'lore': array(color('dark_gray').'Open: other'),
				'flags': array('HIDE_ATTRIBUTES'),
			),
		)
	);
	create_virtualchest(@main);
	
	@other = @main[];
	@other['id'] = 'other';
	@other['title'] = 'Other Games';

	queue_push(closure(){
		@chatcolor = associative_array(
			'easy': 'aqua',
			'easy-medium': 'green',
			'medium': 'yellow',
			'medium-hard': 'gold',
			'hard': 'dark_red',
			'very-hard': 'dark_purple',
			'other': 'white',
		);
		@datacolor = associative_array(
			'easy': 3,
			'easy-medium': 5,
			'medium': 4,
			'medium-hard': 1,
			'hard': 14,
			'very-hard': 10,
			'other': 0,
		);
		@difficultyorder = array('easy', 'easy-medium', 'medium', 'medium-hard', 'hard', 'very-hard', 'other');
		@difficulties = associative_array(
			'easy': array(),
			'easy-medium': array(),
			'medium': array(),
			'medium-hard': array(),
			'hard': array(),
			'very-hard': array(),
			'other': array(),
		);

		@courses = @main[];
		@courses['id'] = 'courses';
		@courses['title'] = 'Solo Courses / Parkour';
		@cakes = get_value('cakeinfo');
		foreach(@name: @cake in @cakes) {
			if(@cake['type'] === 'challenge' || @cake['type'] == 'coop') {
				@lore = array();
				@difficulty = 'other';
				if(array_index_exists(@cake, 'difficulty')) {
					@lore[] = color(@chatcolor[@cake['difficulty']]).color('l').to_upper(@cake['difficulty']);
					@difficulty = @cake['difficulty'];
				}
				@lore[] = color('gold').@cake['coins'].' coins';
				@lore[] = color('green').'Achieved by '.array_size(@cake['players']).' players';
				if(@cake['type'] == 'challenge') {
					@times = get_value('times', @name);
					if(@times) {
						@time = @times['top'][-1][1];
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
					if(!array_index_exists(@difficulties[@difficulty], @cake['coins'])) {
						@difficulties[@difficulty][@cake['coins']] = array();
					}
					@difficulties[@difficulty][@cake['coins']][] = associative_array(
						'name': 'STAINED_GLASS_PANE',
						'data': @datacolor[@difficulty],
						'meta': associative_array(
							'display': color('green').to_upper(@name),
							'lore': @lore,
						),
					);
				} else {
					@other[array_size(@other) - 6] =  associative_array(
						'name': 'STAINED_GLASS',
						'data': @datacolor[@difficulty],
						'meta': associative_array(
							'display': color(7).'Coop: '.color('green').to_upper(@name),
							'lore': @lore,
						),
					);
				}
			}
		}
		foreach(@i: @difficulty in @difficultyorder) {
			@slot = @i * 9;
			foreach(@coins in @difficulties[@difficulty]) {
				foreach(@item in @coins) {
					@courses[@slot] = @item;
					@slot++;
				}
			}
		}
		@courses[58]['name'] = 'DIAMOND_BLOCK';
		create_virtualchest(@courses);
		@cakes = null;
		@courses = null;
	});

	queue_push(closure(){
		@pvp = @main[];
		@pvp['id'] = 'pvp';
		@pvp['title'] = 'PVP Arenas';
		@arenas = get_values('arena');
		@slot = 0;
		queue_push(closure(){
			foreach(@name: @arena in @arenas) {
				if(@slot > 35, break());
				if(array_index_exists(@arena, 'parent'), continue());
				@name = split('.', @name)[1];
				@lore = array();
				if(array_index_exists(@arena, 'description')) {
					foreach(@line in @arena['description']) {
						@lore[] = @line;
					}
				} else if(array_index_exists(@arena, 'mode')) {
					if(@arena['mode'] == 'koth') {
						@lore[] = color('green').'King of the Hill';
					} else if(@arena['mode'] == 'ctf') {
						@lore[] = color('green').'Capture the Flag';
					}
				}
				@min = if(array_index_exists(@arena, 'min'), @arena['min'], 2);
				@lore[] = color('green').@min
						.if(array_index_exists(@arena, 'max'), '-'.@arena['max'], '+').' players';
				@lore[] = color('dark_gray').'Run: /warp '.@name;
				@pvp[@slot] = associative_array(
					'type': 306,
					'qty': @min,
					'meta': associative_array(
						'display': color('green').to_upper(@name),
						'lore': @lore,
						'flags': array('HIDE_ATTRIBUTES'),
					),
				);
				@slot++;
			}
			@pvp[57]['name'] = 'DIAMOND_SWORD';
			create_virtualchest(@pvp);
			@arenas = null;
			@pvp = null;
		});
	});

	queue_push(closure(){
		@other['id'] = 'other';
		@other['title'] = 'Other Games';
		@other[9] = associative_array(
			'name': 'SNOW_BLOCK',
			'meta': associative_array(
				'display': color('yellow').'Spleef',
				'lore': array(
					color('r').'Last man standing (2+ players)',
					color('dark_gray').'Run: /warp spleef',
				),
			),
		);
		@other[10] = associative_array(
			'name': 'STAINED_CLAY',
			'data': 2,
			'meta': associative_array(
				'display': color('gold').'Cube'.color('red').'Climber',
				'lore': array(
					color('r').'Race to the top (2+ players)',
					color('dark_gray').'Run: /warp cubeclimber',
				),
			),
		);
		@other[11] = associative_array(
			'name': 'EMERALD_ORE',
			'meta': associative_array(
				'display': color('green').'Seven Seconds to Live',
				'lore': array(
					color('r').'Last man not blown up (2 - 8 players)',
					color('dark_gray').'Run: /warp 7',
				),
			),
		);
		@other[12] = associative_array(
			'name': 'EMERALD_BLOCK',
			'meta': associative_array(
				'display': color('green').'FrogWare',
				'lore': array(
					color('r').'First to 25 points (1+ players)',
					color('dark_gray').'Run: /warp frogware',
				),
			),
		);
		@other[13] = associative_array(
			'name': 'REDSTONE_BLOCK',
			'meta': associative_array(
				'display': color('red').'Snake',
				'lore': array(
					color('r').'Last snake slithering (1 - 9 players)',
					color('dark_gray').'Run: /warp snake',
				),
			),
		);
		@other[14] = associative_array(
			'name': 'PACKED_ICE',
			'meta': associative_array(
				'display': color('aqua').'Hockey',
				'lore': array(
					color('r').'Team slime hockey (4 - 8 players)',
					color('dark_gray').'Run: /warp hockey',
				),
			),
		);
		@other[18] = associative_array(
			'name': 'SLIME_BLOCK',
			'meta': associative_array(
				'display': color('green').'Slimey Golf',
				'lore': array(
					color('r').'Minigolf (1 - 4 players)',
					color('dark_gray').'Run: /warp slimeygolf',
				),
			),
		);
		@other[19] = associative_array(
			'type': 168,
			'meta': associative_array(
				'display': color('aqua').'Sunken City Golf',
				'lore': array(
					color('r').'Minigolf (1 - 4 players)',
					color('dark_gray').'Run: /warp sunkencitygolf',
				),
			),
		);
		@other[20] = associative_array(
			'name': 'LOG',
			'data': 3,
			'meta': associative_array(
				'display': color('yellow').'Island Golf',
				'lore': array(
					color('r').'Minigolf (1 - 4 players)',
					color('dark_gray').'Run: /warp islandgolf',
				),
			),
		);
		@other[27] = associative_array(
			'name': 'SMOOTH_BRICK',
			'data': 2,
			'meta': associative_array(
				'display': color('yellow').'Gladiator Arena',
				'lore': array(
					color('r').'Survive waves of mobs (1+ players)',
					color('dark_gray').'Run: /warp gladiator',
				),
			),
		);
		@other[59]['name'] = 'DIAMOND_LEGGINGS';
		create_virtualchest(@other);
	});
}
