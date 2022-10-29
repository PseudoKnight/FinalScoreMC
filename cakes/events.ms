# Clicking cakes
bind('player_interact', null, array('block': 'CAKE', 'button': 'right', 'hand': 'main_hand'), @event) {
	if(phas_flight() || pworld() !== 'custom') {
		die();
	}
	@location = @event['location'];

	// fake cake special case
	if(@location['x'] == -510 && @location['z'] == 162) {
		set_block(array(-485, 62, 162, 'custom'), 'REDSTONE_BLOCK');
		die();
	}

	@cakes = get_value('cakes');
	@id = null;
	foreach(@key: @l in @cakes) {
		if(@l[0] == @location[0]
		&& @l[1] == @location[1]
		&& @l[2] == @location[2]) {
			@id = @key;
			break();
		}
	}
	if(is_null(@id)) {
		die();
	}
	cancel();

	@cakeinfo = get_value('cakeinfo');
	if(!array_index_exists(@cakeinfo, @id)) {
		// this shouldn't happen
		die('The cake is a lie.');
	}
	@thiscake = @cakeinfo[@id];

	set_phunger(20);
	set_psaturation(5.0);

	@tutorial = 'Secret cakes like this can be found all over the park.\n'
			.'Find enough of them and get a '.color('gold').'trophy'.color('r').' next to your name!\n'
			.'Track your progress for all cakes with '.color('a').'/cake list';

	// always print tutorial message for welcome cake 
	if(@id == 'welcome') {
		msg(@tutorial);
	}

	@uuid = puuid(player(), true);
	if(array_index_exists(@thiscake['players'], @uuid)) {
		die('You\'ve already got the '.to_upper(@id).' cake.');
	}
	@thiscake['players'][@uuid] = time();
	store_value('cakeinfo', @cakeinfo);

	set_timeout(50, closure(){
		@count = 0;
		@total = 0;
		foreach(@cake in @cakeinfo) {
			if(@cake['type'] == @thiscake['type']) {
				@total += 1;
				if(array_index_exists(@cake['players'], @uuid)) {
					@count += 1;
				}
			}
		}

		_broadcast(display_name().color('r').if(@thiscake['type'] == 'secret', ' found ', ' achieved ')
				.color('a').'['.to_upper(@id).'] '.color('r').@thiscake['type'].' cake! '.color('a').@count.'/'.@total);

		// Tips when getting a certain number of cakes
		if(@thiscake['type'] == 'secret') {
			if(@count == 1) {
				msg(@tutorial);
			}
		} else if(@thiscake['type'] == 'challenge') {
			if(@count == 1) {
				msg("Run the command '/times top' to see the best times for this course.");
			} else if(@count == @total) {
				msg(color('green').color('bold')."Congratulations for completing all @total challenge courses!\n"
					.color('gray')."/times top all".color('reset')." : See overall parkour rankings\n"
					.color('gray')."/times worst".color('reset')." : List courses with the most points you can earn\n"
					.color('gray')."/times best".color('reset')." : List courses you're best at"
					."Top 20 times in courses earn points towards overall ranking.\n");
			}
		}

		// Cake achieved effects
		psend_block_change(@event['location'], 'magenta_candle_cake[lit=true]');
		make_effect(@event['location'], 'ENDER_SIGNAL');
		play_sound(@event['location'], array('sound': 'MUSIC_DISC_STAL'));
		@loc = @event['location'][];
		@loc['x'] += 0.5;
		@loc['y'] += 0.5;
		@loc['z'] += 0.5;
		@cloud = spawn_entity('AREA_EFFECT_CLOUD', 1, @loc)[0];
		set_entity_spec(@cloud, array(particle: 'NOTE', radius: 1, duration: 160));
		set_timeout(8800, closure(){
			// turn off music
			foreach(@p in players_in_radius(@event['location'], 32)) {
				stop_sound(@p, 'MUSIC_DISC_STAL');
			}
		});
	});
}

# COIN SHOPS!
bind('player_interact', null, array('block': 'OAK_WALL_SIGN'), @event) {
	@signtext = get_sign_text(@event['location']);
	if(@cost = reg_match('(?:\\u00a7[0-9a-o])+\\-(\\d{1,3})\\sCoins', @signtext[3])) {
		@chestLoc = location_shift(@event['location'], 'down')
		@count = 0;
		foreach(@item in get_inventory(@chestLoc)) {
			if(@item) {
				@count++;
			}
		}
		@coins = _acc_balance(player())
		if(@event['action'] === 'left_click_block') {
			msg(color('yellow').'[Coin Shop] '.color('r').@count.if(@count == 1, ' item', ' items').' left. '
			.'Your coins: '.if(@coins < @cost[1], color('red'), color('green')).floor(@coins))
		} else { #right_click_block
			if(@count < 1) {
				die(color('yellow').'[Coin Shop] '.color('r').'There are no items left.')
			}
			if(@coins < @cost[1]) {
				die(color('yellow').'[Coin Shop] '.color('r').'You only have '.color('red').floor(@coins).color('r').' left.');
			}
			@chest = get_inventory(@chestLoc);
			foreach(@c in 0..27) {
				if(!is_null(@chest[@c])) {
					@pinv = pinv();
					foreach(@p in 0..35) {
						if(is_null(@pinv[@p])
						|| (@pinv[@p]['name'] == @chest[@c]['name']
						&& @pinv[@p]['qty'] + @chest[@c]['qty'] <= max_stack_size(@pinv[@p]))) {
							if(!is_null(@pinv[@p])) {
								@chest[@c]['qty'] += @pinv[@p]['qty'];
							}
							set_pinv(player(), @p, @chest[@c]);
							set_inventory_item(@chestLoc, @c, null);
							_acc_subtract(player(), @cost[1]);
							die(color('yellow').'[Coin Shop] '.color('r').'Transaction successful. Your coins: '
									.floor(@coins - @cost[1]).' (-'.@cost[1].')');
						}
					}
					die(color('yellow').'[Coin Shop] '.color('r').'You have no room in your inventory.');
				}
			}
		}
	}
}

# Calculate trophies
bind('player_join', null, null, @event) {
	queue_push(closure(){
		@uuid = null;
		try {
			@uuid = puuid(player(), true);
		} catch(PlayerOfflineException @ex) {
			return();
		}
		@cakeinfo = get_value('cakeinfo');
		@count = associative_array(challenge: 0, coop: 0, secret: 0);
		@total = associative_array(challenge: 0, coop: 0, secret: 0);
		foreach(@cake in @cakeinfo) {
			@type = @cake['type'];
			@total[@type]++;
			if(array_index_exists(@cake['players'], @uuid)) {
				@count[@type]++;
			}
		}
		@percent = associative_array(
			challenge: @count['challenge'] / @total['challenge'],
			coop: @count['coop'] / @total['coop'],
			secret: @count['secret'] / @total['secret'],
		);

		@session = _psession(player());
		if(@percent['challenge'] > 0.5) {
			if(!array_index_exists(@session, 'trophies')) {
				@session['trophies'] = array();
			}
			@pct = integer(@percent['challenge'] * 100);
			@session['trophies'][] = if(@pct == '100', color('yellow'), color('gray')).@pct.'% Parkour Cakes';
		}
		if(@percent['secret'] > 0.5) {
			if(!array_index_exists(@session, 'trophies')) {
				@session['trophies'] = array();
			}
			@pct = integer(@percent['secret'] * 100);
			@session['trophies'][] = if(@pct == '100', color('yellow'), color('gray')).@pct.'% Secret Cakes';
		}
		if(@percent['coop'] > 0.5) {
			if(!array_index_exists(@session, 'trophies')) {
				@session['trophies'] = array();
			}
			@pct = integer(@percent['coop'] * 100);
			@session['trophies'][] = if(@pct == '100', color('red'), color('gray')).'\u2764 '.@pct.'% Coop Cakes';
		}
	}, 'trophies');
}
