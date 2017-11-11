@pvp['binds'][] = @id.'riflereload';
bind(player_interact, array('id': @id.'riflereload'), array('item': 265), @event, @pvp) {
	if(!array_index_exists(@pvp['players'], player()) || pinfo(player(), 6) != @event['item']){
		die();
	}
	@ammo = pinv(player(), null);
	@ammo['qty']--;
	set_pinv(player(), null, null);
	@ammoslot = pheld_slot();
	play_sound(ploc(), array('sound': 'DOOR_OPEN', 'pitch': 2));
	foreach(@weaponslot: @weapon in pinv()) {
		if(@weapon && @weapon['type'] == 291) {
			// Found weaponslot
			set_pcooldown(@weapon['name'], 2000 / 50);
			break();
		}
	}
	set_timeout(2000, closure(){
		if(ponline(@event['player']) && phealth()) {
			@inv = pinv();
			if(!is_null(@inv[@ammoslot]) && @inv[@ammoslot]['type'] == 265) {
				@inv[@ammoslot]['qty'] += @ammo['qty'];
			} else {
				@inv[@ammoslot] = @ammo;
			}
			@weapon['data'] = 10;
			@inv[@weaponslot] = @weapon;
			set_pinv(player(), @inv);
			play_sound(ploc(), array('sound': 'DOOR_CLOSE', 'pitch': 2))
		}
	});
}

@pvp['binds'][] = @id.'rifle';
bind(player_interact, array('id': @id.'rifle'), array('item': 291), @event, @pvp) {
	if(!array_index_exists(@pvp['players'], player()) || pinfo(player(), 6) != @event['item']){
		die();
	}
	@item = pinv(player(), null);
	if(!@item['meta'] || @item['meta']['display'] != 'Rifle' || @item['data'] >= 130 || pcooldown(@item['name'])) {
		die();
	}
	
	@item['data'] += 8;
	set_pinv(player(), null, @item);
	
	_hit_scan(player(), 64, 1.9, 'VOID_FOG', 'LARGE_SMOKE', @pvp);
	play_sound(ploc(), array('sound': 'FIREWORK_BLAST', 'pitch': 0.7, 'volume': 3));
	set_timeout(50, closure(){
		_hit_scan(player(), 64, 1.9, 'VOID_FOG', 'LARGE_SMOKE', @pvp);
		play_sound(ploc(), array('sound': 'FIREWORK_BLAST', 'pitch': 0.7, 'volume': 3));
	});
}
