proc _repopulate_menu(){
	@main = associative_array(
		'id': 'main',
		'title': 'Frog Park Directory',
		'size': 45,
		36: associative_array(
			'name': 'IRON_SWORD',
			'meta': associative_array(
				'display': color('green').'PVP Arenas',
				'lore': array(color('dark_gray').'Open: pvp'),
				'flags': array('HIDE_ATTRIBUTES'),
			),
		),
		37: associative_array(
			'name': 'IRON_BLOCK',
			'meta': associative_array(
				'display': color('green').'Obstacle Courses / Parkour',
				'lore': array(color('dark_gray').'Open: courses'),
			),
		),
		38: associative_array(
			'name': 'IRON_SPADE',
			'meta': associative_array(
				'display': color('green').'Other Games',
				'lore': array(color('dark_gray').'Open: other'),
				'flags': array('HIDE_ATTRIBUTES'),
			),
		)
	);
	create_virtualchest(@main);

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
		@courses['title'] = 'Obstacle Courses / Parkour';
		@cakes = get_value('cakeinfo');
		foreach(@name: @cake in @cakes) {
			if(@cake['type'] === 'challenge') {
				@lore = array();
				@difficulty = 'other';
				if(array_index_exists(@cake, 'difficulty')) {
					@lore[] = color(@chatcolor[@cake['difficulty']]).color('l').to_upper(@cake['difficulty']);
					@difficulty = @cake['difficulty'];
				}
				@lore[] = color('gold').@cake['coins'].' coins';
				@lore[] = color('green').'Achieved by '.array_size(@cake['players']).' players';
				@times = get_values('times', @name);
				if(@times) {
					@total = 0.0;
					foreach(@time in @times) {
						if(is_array(@time)) {
							continue();
						}
						@total += @time;
					}
					@avgtime = integer(round((@total / (array_size(@times) - 1)) * 1000));
					if(@avgtime >= 60) {
						@avgtime = simple_date('m\u0027m\u0027s\u0027s\u0027', @avgtime);
					} else {
						@avgtime = simple_date('s\u0027s\u0027', @avgtime);
					}
					@lore[] = color('green').'Average best time: ' . @avgtime;
				}
				@lore[] = color('dark_gray').'Run: /warp '.@name;
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
			}
		}
		@slot = 0;
		foreach(@difficulty in @difficultyorder) {
			foreach(@coins in @difficulties[@difficulty]) {
				foreach(@item in @coins) {
					if(@slot > 44, break());
					@courses[@slot] = @item;
					@slot++;
				}
			}
		}
		@courses[37]['name'] = 'DIAMOND_BLOCK';
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
				@lore[] = color('green').if(array_index_exists(@arena, 'min'), @arena['min'], 2)
						.if(array_index_exists(@arena, 'max'), '-'.@arena['max'], '+').' players';
				@lore[] = color('dark_gray').'Run: /warp '.@name;
				@pvp[@slot] = associative_array(
					'type': 351,
					'data': 8,
					'meta': associative_array(
						'display': color('green').to_upper(@name),
						'lore': @lore,
					),
				);
				@slot++;
			}
			@pvp[36]['name'] = 'DIAMOND_SWORD';
			create_virtualchest(@pvp);
			@arenas = null;
			@pvp = null;
		});
	});

	queue_push(closure(){
		@other = @main[];
		@other['id'] = 'other';
		@other['title'] = 'Other Games';
		@other[0] = associative_array(
			'name': 'SNOW_BLOCK',
			'meta': associative_array(
				'display': color('green').'Spleef',
				'lore': array(
					'Last man standing (2+ players)',
					color('dark_gray').'Run: /warp spleef',
				),
			),
		);
		@other[1] = associative_array(
			'name': 'STAINED_CLAY',
			'data': 2,
			'meta': associative_array(
				'display': color('gold').'Cube'.color('red').'Climber',
				'lore': array(
					'Race to the top (2+ players)',
					color('dark_gray').'Run: /warp cubeclimber',
				),
			),
		);
		@other[2] = associative_array(
			'name': 'EMERALD_ORE',
			'meta': associative_array(
				'display': color('green').'Seven Seconds to Live',
				'lore': array(
					'Last man not blown up (2+ players)',
					color('dark_gray').'Run: /warp 7',
				),
			),
		);
		@other[3] = associative_array(
			'name': 'EMERALD_BLOCK',
			'meta': associative_array(
				'display': color('green').'FrogWare',
				'lore': array(
					'First to 25 points (1+ players)',
					color('dark_gray').'Run: /warp frogware',
				),
			),
		);
		@other[4] = associative_array(
			'name': 'SLIME_BLOCK',
			'meta': associative_array(
				'display': color('green').'Slimey Golf',
				'lore': array(
					'Lowest stroke count wins (1+ players)',
					color('dark_gray').'Run: /warp slimeygolf',
				),
			),
		);
		@other[5] = associative_array(
			'type': 168,
			'meta': associative_array(
				'display': color('green').'Sunken City Golf',
				'lore': array(
					'Lowest stroke count wins (1+ players)',
					color('dark_gray').'Run: /warp sunkencitygolf',
				),
			),
		);
		@other[6] = associative_array(
			'name': 'SEA_LANTERN',
			'meta': associative_array(
				'display': color('green').'SNAKE',
				'lore': array(
					'Last snake slithering (1+ players)',
					color('dark_gray').'Run: /warp snake',
				),
			),
		);
		@other[38]['name'] = 'DIAMOND_SPADE';
		create_virtualchest(@other);
	});
}
