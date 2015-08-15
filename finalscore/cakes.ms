# Clicking cakes
bind(player_interact, null, array('block': 92), @event) {
	if(phas_flight() || pworld() != 'custom') {
		die()
	}
	if(@event['location']['x'] == -510 && @event['location']['z'] == 162) {
		set_block_at(array(-485, 62, 162, 'custom'), '152:0')
		die()
	}
	@cakes = get_value('cakes')
	@id = ''
	foreach(@key: @loc in @cakes) {
		if(@loc[0] == @event['location'][0]
		&& @loc[1] == @event['location'][1]
		&& @loc[2] == @event['location'][2]) {
			@id = @key
			break()
		}
	}
	if(!@id, die())
	cancel()
	@cakeinfo = get_value('cakeinfo')
	if(!array_index_exists(@cakeinfo, @id), die('The cake is a lie.'))
	set_phunger(20)
	set_psaturation(5.0)
	@uuid = puuid(player(), true);
	if(array_index_exists(@cakeinfo[@id]['players'], @uuid)) {
		die('You\'ve already got this cake.')
	}
	@count = 1
	@total = 0
	foreach(@cake in @cakeinfo) {
		if(@cake['type'] == @cakeinfo[@id]['type']) {
			@total += 1
			if(array_index_exists(@cake['players'], @uuid)) {
				@count += 1
			}
		}
	}
	@cakeinfo[@id]['players'][@uuid] = time()
	msg(color('green').'You got the '.to_upper(@id).' '.@cakeinfo[@id]['type'].' cake! ('.@count.'/'.@total.')')
	if(!array_contains_ic(pgroup(), 'builders')) {
		_acc_add(player(), @cakeinfo[@id]['coins'])
		msg(color('gold').'+ '.@cakeinfo[@id]['coins'].' coins')
		console(player().' got '.@cakeinfo[@id]['coins'].' coins at '.@id)
	}
	store_value('cakeinfo', @cakeinfo)
	make_effect(@event['location'], 'ENDER_SIGNAL')
	make_effect(@event['location'], 'RECORD_PLAY:2263')
	if(split(':', get_block_at(@event['location']))[1] > 0) {
		set_block_at(@event['location'], '92:0')
	}
}

# COIN SHOPS!
bind(player_interact, null, array('block': 68), @event) {
	@signtext = get_sign_text(@event['location'])
	if(@cost = reg_match('(?:\\u00a7[0-9a-o])+\\-(\\d{1,3})\\sCoins', @signtext[3])) {
		@chestloc = _relative(@event['location'], 'down')
		@count = _get_inventory_count(@chestloc, 'all')
		@coins = _acc_balance(player())
		if(@event['action'] == 'left_click_block') {
			msg(color('yellow').'[Coin Shop] '.color(r).@count.if(@count == 1, ' item', ' items').' left. '
			.'Your coins: '.if(@coins < @cost[1], color('red'), color('green')).round(@coins))
		} else { #right_click_block
			if(@count < 1) {
				die(color('yellow').'[Coin Shop] '.color('r').'There are no items left.')
			}
			if(@coins < @cost[1], die(color('yellow').'[Coin Shop] '.color(r).'You only have '.color('red').round(@coins).color('r').' left.'))
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
							@newinv = array();
							@newinv[@p] = @chest[@c];
							set_pinv(player(), @newinv);
							set_inventory_item(@chestloc, @c, null);
							_acc_subtract(player(), @cost[1]);
							msg(color('yellow').'[Coin Shop] '.color('r').'Transaction successful. Your coins: '.round(@coins - @cost[1]).' (-'.@cost[1].')');
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