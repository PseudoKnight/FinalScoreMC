array_push(@pvp['binds'], @id.'spawner')
bind(player_interact, array('id': @player.'spawner'), array('button': 'right', 'item': 383), @e, @id = @id) {
	@pvp = import('pvp'.@id);
	if(!array_index_exists(@pvp['players'], player()), die());
	
	if(@e['action'] == 'right_click_block') {
		cancel()
		@item = pinv(player(), null)
		if(is_null(@item['meta'])
		|| is_null(@item['meta']['display'])) {
			die()
		}
		
		@loc = _relative(@e['location'], @e['facing']);
		@loc['x'] += 0.5;
		@loc['z'] += 0.5;
		
		@mob = to_lower(@item['meta']['display'])
		if(!is_null(@item['meta']['lore'])
		&& @item['meta']['lore'][0] == 'Target Near') {
			foreach(@player in players_in_radius(@loc, 20)) {
				if(@player == player(), continue())
				_spawn_mob(@mob, 1, @loc, @player)
			}
		} else {
			_spawn_mob(@mob, 1, @loc, player())
		}
		play_sound(@loc, array('sound': 'ZOMBIE_INFECT', 'pitch': 1.5))
		play_effect(@loc, 'cloud', array('speed': 0, 'particleCount': 10, 'offsetX': 0.4, 'offsetZ': 0.4, 'offsetY': 0.4))

		@item['qty'] -= 1
		if(@item['qty'] > 0) {
			@slot = pinfo(player(), 15)
			@newitem = array('type': 361, 'qty': @item['qty'])
			set_pinv(array('null': @newitem))
			queue_clear(player().'spawner');
			queue_delay(2000, player().'spawner');
			queue_push(closure(){
				@newitem = pinv(player(), @slot)
				if(!is_null(@newitem) && @newitem['type'] == 361) {
					@inv = array()
					@inv[@slot] = @item
					set_pinv(@inv)
				}
			}, player().'spawner')
		} else {
			set_pinv(array('null': null))
		}
	}
}