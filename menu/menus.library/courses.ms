proc _prepare_menu(@template) {
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

	@menu = @template[];
	@menu['id'] = 'courses';
	@menu['title'] = 'Solo Courses / Parkour';
	@menu[58]['name'] = 'DIAMOND_BLOCK';
	
	@other = get_virtualchest('other');
	@otherSlot = 0;
	
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
				@other[@otherSlot++] =  associative_array(
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
				@menu[@slot] = @item;
				@slot++;
			}
		}
	}
	
	create_virtualchest(@menu);
	create_virtualchest(@other);
}
