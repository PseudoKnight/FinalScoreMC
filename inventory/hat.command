register_command('hat', array(
	'description': 'Puts the item in your hand onto your head.',
	'usage': '/hat',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!is_null(pinv(player(), 103))) {
			die(color('gold').'You already have something on your head.');
		}
		@item = pinv(player(), null);
		if(is_null(@item)) {
			die(color('gold').'You need to hold something before you can put it on your head.');
		}
		@excluded = array();
		if(array_contains(@excluded, @item['name'])) {
			die(color('gold').'That item cannot be put on your head without losing data tags.');
		}
		if(@item['qty'] == 1) {
			set_pinv(player(), array(null: null, 103: @item));
		} else {
			@item['qty'] -= 1;
			@hat = @item[];
			@hat['qty'] = 1;
			set_pinv(player(), array(null: @item, 103: @hat));
		}
		@loc = ploc();
		play_sound(@loc, array('sound': 'ENTITY_CHICKEN_EGG', 'category': 'PLAYERS'));
		spawn_particle(location_shift(@loc, 'up', 2.7), array(
			'particle': 'CLOUD',
			'count': 10,
			'xoffset': 0.5,
			'yoffset': 0.5,
			'zoffset': 0.5,
			'speed': 0,
		));
		@messages = array('Fancy!', 'Stylin\'!', 'Groovy!', 'Lookin\' good!', 'Tasteful!', 'Awesome!', 'Rad!', 'Cool!');
		title('', color(6).array_get_rand(@messages), 10, 40, 10);
	}
));
