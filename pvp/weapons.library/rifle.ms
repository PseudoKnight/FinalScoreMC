proc _reload_rifle() {
	@item = pinv(player(), null);
	if(@item['qty'] == 1) {
		play_sound(ploc(), array('sound': 'CLICK', 'pitch': 2));
		die();
	}
	@item['qty']--;
	@item['data'] = 131;
	set_pinv(player(), array(0: @item));
	play_sound(ploc(), array('sound': 'DOOR_OPEN', 'pitch': 2));
	set_timeout(2400, closure(){
		if(ponline(player()) && pinfo(player(), 5) > 0) {
			@newitem = pinv(player(), 0);
			if(is_null(@newitem) || @newitem['type'] != 291 || @newitem['qty'] != @item['qty'] - 1) {
				die();
			}
			@item['data'] = 10;
			set_pinv(player(), array(0: @item));
			play_sound(ploc(), array('sound': 'DOOR_CLOSE', 'pitch': 2));
		}
	});
}

array_push(@pvp['binds'], @id.'rifle');
bind(player_interact, array('id': @id.'rifle'), array('item': 291), @event, @pvp) {
	if(!array_index_exists(@pvp['players'], player()) || pinfo(player(), 6) != @event['item']){
		die();
	}
	@item = pinv(player(), 0);
	if(!@item['meta'] || @item['meta']['display'] != 'Rifle') {
		die();
	}
	
	if(@event['button'] == 'left') {
		_reload_rifle();
		die();
	} else if(@item['data'] >= 130) {
		die();
	}
	@item['data'] += 8;
	set_pinv(player(), array(0: @item));
	
	_hit_scan(player(), 64, 2, 'VOID_FOG', 'LARGE_SMOKE', @pvp);
	play_sound(ploc(), array('sound': 'FIREWORK_BLAST', 'pitch': 0.7, 'volume': 3));
	set_timeout(50, closure(){
		_hit_scan(player(), 64, 2, 'VOID_FOG', 'LARGE_SMOKE', @pvp);
		play_sound(ploc(), array('sound': 'FIREWORK_BLAST', 'pitch': 0.7, 'volume': 3));
	});
}
