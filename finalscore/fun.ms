bind(player_interact, null, array('item': 401, 'button': 'right'), @event) {
	if(pworld() != 'custom'
	|| !array_contains(pgroup(), 'supporters')) {
		die()
	}
	cancel()
	if(@event['action'] == 'right_click_block') {
		@loc = _relative(@event['location'], @event['facing'])
	} else {
		@loc = ploc()
	}
	@loc['x'] += 0.5
	@loc['z'] += 0.5
	
	@numcolors = rand(3)
	@colors = array()
	for(@i = 0, @i <= @numcolors, @i++) {
		@colors[] = array(rand(256), rand(256), rand(256))
	}
	@numcolors = rand(3)
	@fadecolors = array()
	for(@i = 0, @i <= @numcolors, @i++) {
		@fadecolors[] = array(rand(256), rand(256), rand(256))
	}
	launch_firework(@loc, array(
		'strength': rand(4),
		'flicker': rand(2),
		'trail': rand(2),
		'colors': @colors,
		'fade': @fadecolors,
		'type': array_rand(array('BALL', 'BALL_LARGE', 'STAR', 'BURST', 'CREEPER'), 1, false)[0],
	))
	
	@slot = pinfo(player(), 15)
	@item = pinv(player(), @slot)
	@item['type'] = 402
	@item['name'] = 'FIREWORK_CHARGE'
	set_pinv(player(), array(null: @item))
	set_timeout(2000, closure(){
		try(
			@item = pinv(player(), @slot)
			if(@item && @item['type'] == 402) {
				@item['type'] = 401
				@item['name'] = 'FIREWORK'
				@inv = array()
				@inv[@slot] = @item
				set_pinv(player(), @inv)
			}
		)
	})
}