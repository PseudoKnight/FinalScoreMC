# Clicking cakes
bind(player_interact, null, array('block': 92), @event) {
	if(phas_flight() || pworld() !== 'custom') {
		die();
	}
	@location = @event['location'];

	// fake cake special case
	if(@location['x'] == -510 && @location['z'] == 162) {
		set_block_at(array(-485, 62, 162, 'custom'), '152:0');
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

	@uuid = puuid(player(), true);
	if(array_index_exists(@thiscake['players'], @uuid)) {
		die('You\'ve already got this cake.');
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
		set_phunger(20);
		set_psaturation(5.0);

		broadcast(_colorname().player().color('r').if(@thiscake['type'] == 'secret', ' found ', ' achieved ')
				.color('a').'['.to_upper(@id).'] '.color('r').@thiscake['type'].' cake! '.color('a').@count.'/'.@total);

		if(!has_permission('group.builder')) {
			_acc_add(player(), @thiscake['coins']);
			msg(color('gold').'+ '.@thiscake['coins'].' coins');
			console(player().' got '.@thiscake['coins'].' coins at '.@id, false);
		}

		if(split(':', get_block_at(@event['location']))[1] > 0) {
			set_block_at(@event['location'], '92:0');
		}

		make_effect(@event['location'], 'ENDER_SIGNAL');
		make_effect(@event['location'], 'RECORD_PLAY:2263');
		@loc = @event['location'][];
		@loc['x'] += 0.5;
		@loc['y'] += 0.5;
		@loc['z'] += 0.5;
		@cloud = spawn_entity('AREA_EFFECT_CLOUD', 1, @loc)[0];
		set_entity_spec(@cloud, associative_array('particle': 'NOTE', 'radius': 1, 'duration': 160));
		set_timeout(8800, closure(){
			// turn off music
			make_effect(@event['location'], 'RECORD_PLAY:0');
		});
	});
}

# COIN SHOPS!
bind(player_interact, null, array('block': 68), @event) {
	@signtext = get_sign_text(@event['location'])
	if(@cost = reg_match('(?:\\u00a7[0-9a-o])+\\-(\\d{1,3})\\sCoins', @signtext[3])) {
		@chestloc = _relative(@event['location'], 'down')
		@count = _get_inventory_count(@chestloc, 'all')
		@coins = _acc_balance(player())
		if(@event['action'] === 'left_click_block') {
			msg(color('yellow').'[Coin Shop] '.color(r).@count.if(@count == 1, ' item', ' items').' left. '
			.'Your coins: '.if(@coins < @cost[1], color('red'), color('green')).floor(@coins))
		} else { #right_click_block
			if(@count < 1) {
				die(color('yellow').'[Coin Shop] '.color('r').'There are no items left.')
			}
			if(@coins < @cost[1], die(color('yellow').'[Coin Shop] '.color(r).'You only have '.color('red').floor(@coins).color('r').' left.'))
			@chest = get_inventory(@chestloc);
			foreach(@c in 0..27) {
				if(!is_null(@chest[@c])) {
					@pinv = pinv();
					foreach(@p in 0..35) {
						if(is_null(@pinv[@p])
						|| (@pinv[@p]['type'] == @chest[@c]['type']
						&& @pinv[@p]['data'] == @chest[@c]['data']
						&& @pinv[@p]['qty'] + @chest[@c]['qty'] <= max_stack_size(@pinv[@p]))) {
							if(!is_null(@pinv[@p])) {
								@chest[@c]['qty'] += @pinv[@p]['qty'];
							}
							@newinv = associative_array();
							@newinv[@p] = @chest[@c];
							set_pinv(player(), @newinv);
							set_inventory_item(@chestloc, @c, null);
							_acc_subtract(player(), @cost[1]);
							msg(color('yellow').'[Coin Shop] '.color('r').'Transaction successful. Your coins: '.floor(@coins - @cost[1]).' (-'.@cost[1].')');
							break(2);
						}
					}
					msg(color('yellow').'[Coin Shop] '.color('r').'You have no room in your inventory.');
					break();
				}
			}
		}
	}
}

# Calculate trophies
bind(player_join, null, null, @event) {
	queue_push(closure(){
		try {
			@uuid = puuid(player(), true);
		} catch(PlayerOfflineException @ex) {
			return();
		}
		@cakeinfo = get_value('cakeinfo');
		@count = associative_array('challenge': 0, 'coop': 0, 'secret': 0);
		@total = associative_array('challenge': 0, 'coop': 0, 'secret': 0);
		foreach(@cake in @cakeinfo) {
			@type = @cake['type'];
			@total[@type]++;
			if(array_index_exists(@cake['players'], @uuid)) {
				@count[@type]++;
			}
		}
		@percent = associative_array(
			'challenge': @count['challenge'] / @total['challenge'],
			'secret': @count['secret'] / @total['secret'],
		);

		@pstate = _pstate(player());
		if(@percent['challenge'] > 0.75) {
			if(!array_index_exists(@pstate, 'trophies')) {
				@pstate['trophies'] = array();
			}
			if(@percent['challenge'] == 1.0) {
				@pstate['trophies'][] = color('yellow').'100% Challenge Cakes';
			} else if(@percent['challenge'] > 0.9) {
				@pstate['trophies'][] = color('white').'>90% Challenge Cakes';
			} else {
				@pstate['trophies'][] = color('gray').'>75% Challenge Cakes';
			}
		}
		if(@percent['secret'] > 0.75) {
			if(!array_index_exists(@pstate, 'trophies')) {
				@pstate['trophies'] = array();
			}
			if(@percent['secret'] == 1.0) {
				@pstate['trophies'][] = color('yellow').'100% Secret Cakes';
			} else if(@percent['secret'] > 0.9) {
				@pstate['trophies'][] = color('white').'>90% Secret Cakes';
			} else {
				@pstate['trophies'][] = color('gray').'>75% Secret Cakes';
			}
		}
	}, 'trophies');
}