array_push(@pvp['binds'], @id.'railgun');
bind('player_interact', array('id': @id.'railgun'), array('itemname': 'SUNFLOWER', 'button': 'right'), @e, @id) {
	@pvp = import('pvp'.@id);
	if(!array_index_exists(@pvp['players'], player()) || pinfo(player(), 6) != @e['item']['name']) {
		die();
	}

	_weapon_hit_scan(player(), 112, 16, array('tracerparticle': 'CRIT', 'hitparticle': 'LAVA_POP'), @pvp);

	play_sound(ploc(), array('sound': 'ENTITY_ZOMBIE_VILLAGER_CURE', 'pitch': 1.8, 'volume': 3));
	@item = pinv(player(), null);
	@item['qty'] -= 1;
	queue_clear(player().'railgun');
	if(@item['qty'] == 0) {
		set_pinv(player(), null, null);
	} else {
		@item['name'] = 'FIREWORK_STAR';
		set_pinv(player(), null, @item);
		@slot = pheld_slot();
		set_pcooldown('FIREWORK_STAR', 8000 / 50);
		queue_delay(8000, player().'railgun');
		queue_push(closure(){
			if(ponline(player())) {
				@item = pinv(player(), @slot);
				if(!is_null(@item) && @item['name'] == 'FIREWORK_STAR') {
					play_sound(ploc(), array('sound': 'BLOCK_FIRE_EXTINGUISH', 'pitch': 0));
					@item['name'] = 'SUNFLOWER';
					set_pinv(player(), @slot, @item);
				}
			}
		}, player().'railgun');
	}
}
