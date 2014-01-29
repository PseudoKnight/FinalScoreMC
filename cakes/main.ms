# Clicking cakes
bind('player_interact', null, array('block': 92), @event,
	if(pworld() != 'custom'
	|| pmode() == 'CREATIVE') {
		die()
	}
	@cakes = get_value('cakes')
	@id = array_index(@cakes, array(integer(@event['location'][0]), integer(@event['location'][1]), integer(@event['location'][2]), @event['location'][3]))
	if(!@id, die())
	cancel()
	@cakedata = get_value('cakeinfo.'.@id)
	if(!@cakedata, die('The cake is a lie.'))
	set_phunger(20)
	set_psaturation(5.0)
	if(array_index_exists(@cakedata['players'], player())) {
		die('You\'ve already got this cake.')
	}
	@allcakes = get_values('cakeinfo')
	@count = 1
	@total = 0
	foreach(@allcakes, @cake,
		if(@cake['type'] == @cakedata['type']) {
			@total = @total + 1
			if(array_index_exists(@cake['players'], player())) {
				@count = @count + 1
			}
		}
	)
	@cakedata['players'][player()] = time()
	msg(color('green').'You got the '.to_upper(@id).' '.@cakedata['type'].' cake! ('.@count.'/'.@total.')')
	if(!array_contains_ic(pgroup(), 'builders')) {
		_acc_add(player(), @cakedata['coins'])
		msg(color('gold').'+ '.@cakedata['coins'].' coins')
		console(player().' got '.@cakedata['coins'].' coins at '.@id)
	}
	store_value('cakeinfo.'.@id, @cakedata)
	make_effect(@event['location'], 'ENDER_SIGNAL')
	make_effect(@event['location'], 'RECORD_PLAY:2263')
	if(get_block_at(@event['location']) != '92:0', set_block_at(@event['location'], '92:0'))
)

# COIN SHOPS!
bind('player_interact', null, array('block': 68), @event,
	@signtext = get_sign_text(@event['location'])
	if(length(@signtext[3]) > 8 && substr(@signtext[3], 0, 3) == color('yellow').'-') { #Coin reward signs
		@cost = reg_match('.*\\-(\\d{1,3})\\sCoins', @signtext[3])
		@chestloc = _relative(@event['location'], 'down')
		@count = _get_inventory_count(@chestloc, 'all')
		if(@event['action'] == 'left_click_block') {
			msg(color('yellow').'[Coin Shop] '.color(r).@count.if(@count == 1, ' item', ' items').' left. Your coins: '.if(_acc_balance(player()) < @cost[1], color('red'), color('green')).round(_acc_balance(player())))
		} else { #right_click_block
			if(@count < 1, die(color('yellow').'[Coin Shop] '.color('r').'There are no items left.'))
			if(_acc_balance(player()) < @cost[1], die(color('yellow').'[Coin Shop] '.color(r).'You only have '.color('red').round(_acc_balance(player())).color('r').' left.'))
			for(@i = 0, @i < get_inventory_size(@chestloc), @i++,
				if(get_inventory_item(@chestloc, @i) != null) {
					if(_pgive_item(player(), get_inventory_item(@chestloc, @i)) == true) {
						set_inventory_item(@chestloc, @i, null)
						_acc_subtract(player(), @cost[1])
						msg(color('yellow').'[Coin Shop] '.color('r').'Transaction successful. Your coins: '.round(_acc_balance(player())).' (-'.@cost[1].')')
						break()
					} else {
						msg(color('yellow').'[Coin Shop] '.color('r').'You have no room in your inventory.')
					}
				}
			)
		}
	}
)