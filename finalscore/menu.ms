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

		@courses = @main[];
		@courses['id'] = 'courses';
		@courses['title'] = 'Obstacle Courses / Parkour';
		@cakes = get_value('cakeinfo');
		@slot = 0;
		foreach(@name: @cake in @cakes) {
			if(@slot > 44, break());
			if(@cake['type'] === 'challenge') {
				@lore = array();
				if(array_index_exists(@cake, 'difficulty')) {
					@lore[] = color(@color[@cake['difficulty']]).color('l').to_upper(@cake['difficulty']);
				}
				@lore[] = color('gold').@cake['coins'].' coins';
				@lore[] = color('green').'Achieved by '.array_size(@cake['players']).' players';
				if(@times = get_value('times', @name)) {
					@lore[] = color('green').'Best Time: '.@times['top'][0][1].'s ('.@times['top'][0][0].')';
				}
				@lore[] = color('dark_gray').'Run: /warp '.@name;
				@courses[@slot] = array(
					'type': 351,
					'data': 8,
					'meta': array(
						'display': color('green').to_upper(@name),
						'lore': @lore,
					),
				);
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
