array_push(@pvp['binds'], @id.'railgun');
bind(player_interact, array('id': @id.'railgun'), array('item': 175, 'button': 'right'), @e, @id) {
	@pvp = import('pvp'.@id);
	if(!array_index_exists(@pvp['players'], player()) || pinfo(player(), 6) != @e['item']) {
		die();
	}

	_hit_scan(112, 16, array('flame', 'crit', 'cloud'), 'lava_pop', @pvp);

	play_sound(ploc(), array('sound': 'ZOMBIE_REMEDY', 'pitch': 1.8, 'volume': 3));
	@item = pinv(player(), null);
	@item['qty'] -= 1;
	queue_clear(player().'railgun');
	if(@item['qty'] == 0) {
		set_pinv(array(null: null));
	} else {
		@item['type'] = 402;
		@item['name'] = 'FIREWORK_CHARGE';
		set_pinv(array(null: @item));
		@slot = pinfo(player(), 15);
		queue_delay(8000, player().'railgun');
		queue_push(closure(){
			if(ponline(player())) {
				@item = pinv(player(), @slot);
				if(!is_null(@item) && @item['type'] == 402) {
					play_sound(ploc(), array('sound': 'FIZZ', 'pitch': 0));
					@inv = associative_array();
					@item['type'] = 175;
					@item['name'] = 'DOUBLE_PLANT';
					@inv[@slot] = @item;
					set_pinv(@inv);
				}
			}
		}, player().'railgun');
	}
}
