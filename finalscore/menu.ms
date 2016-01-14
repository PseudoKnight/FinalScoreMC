if(extension_exists('chvirtualchests')) {
queue_push(closure(){
	@main = array(
		'id': 'main',
		'title': 'Frog Park Directory',
		'size': 54,
		45: array(
			'type': 267,
			'meta': array(
				'display': color('green').'PVP Arenas',
				'lore': array(color('dark_gray').'Open: pvp'),
			),
		),
		46: array(
			'type': 42,
			'meta': array(
				'display': color('green').'Obstacle Courses / Parkour',
				'lore': array(color('dark_gray').'Open: courses'),
			),
		),
	);
	create_virtualchest(@main);

	queue_push(closure(){
		@color = associative_array(
			'easy': 'green',
			'easy-medium': 'yellow',
			'medium': 'gold',
			'medium-hard': 'red',
			'hard': 'dark_red',
			'very-hard': 'dark_purple',
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
					@lore[] = color(@color[@cake['difficulty']]).color('l').to_upper(@cake['difficulty']);
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
					@avgtime = round((@total / (array_size(@times) - 1)) * 1000);
					if(@avgtime >= 60) {
						@avgtime = simple_date('m\u0027m\u0027s\u0027s\u0027', @avgtime);
					} else {
						@avgtime = simple_date('s\u0027s\u0027', @avgtime);
					}
					@lore[] = color('green').'Average best time: ' . @avgtime;
				}
				@lore[] = color('dark_gray').'Run: /warp '.@name;
				@difficulties[@difficulty][] = array(
					'type': 351,
					'data': 8,
					'meta': array(
						'display': color('green').to_upper(@name),
						'lore': @lore,
					),
				);
			}
		}
		@slot = 0;
		foreach(@difficulty in @difficultyorder) {
			foreach(@item in @difficulties[@difficulty]) {
				if(@slot > 44, break());
				@courses[@slot] = @item;
				@slot++;
			}
		}
		@courses[46]['type'] = 57;
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
		foreach(@name: @arena in @arenas) {
			if(@slot > 44, break());
			if(array_index_exists(@arena, 'parent'), continue());
			@name = split('.', @name)[1];
			@lore = array();
			if(array_index_exists(@arena, 'description')) {
				@lore[] = @arena['description'];
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
			@pvp[@slot] = array(
				'type': 351,
				'data': 8,
				'meta': array(
					'display': color('green').to_upper(@name),
					'lore': @lore,
				),
			);
			@slot++;
		}
		@pvp[45]['type'] = 276;
		create_virtualchest(@pvp);
		@arenas = null;
		@pvp = null;
	});

	bind(player_interact, null, array('item': 340, 'button': 'right'), @event) {
		if(pworld() === 'custom') {
			@item = pinv(player(), null);
			if(!is_null(@item) # sometimes an earlier event handler will remove the item
			&& !is_null(@item['meta'])
			&& @item['meta']['display'] === 'Park Directory') {
				cancel();
				popen_virtualchest('main');
				play_sound(ploc(), array('sound': 'STEP_WOOL', 'pitch': 1.2), player());
			}
		}
	}

	bind(inventory_click, null, null, @e) {
		if(is_null(pget_virtualchest())) {
			die();
		}
		cancel();
		@lore = _item_meta(@e['slotitem'], 'lore');
		if(@lore) {
			@action = split(': ', to_lower(strip_colors(@lore[-1])));
			switch(@action[0]) {
			case 'open':
				popen_virtualchest(@action[1]);
				play_sound(ploc(), array('sound': 'CLICK', 'pitch': 1.2), player());
			case 'run':
				run_cmd(@action[1]);
				close_pinv();
			}
		}
	}

	bind(inventory_drag, null, null, @e) {
		if(!is_null(pget_virtualchest())) {
			cancel();
		}
	}
});
}
