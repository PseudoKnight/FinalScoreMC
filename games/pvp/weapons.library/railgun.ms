proc _weapon_bind_events(@pvp) {
	@pvp['binds'][] = bind('player_interact', null, array(itemname: 'SUNFLOWER', button: 'right', hand: 'main_hand'), @event, @pvp) {
		if(!array_index_exists(@pvp['players'], player()) || pcooldown('SUNFLOWER')) {
			die();
		}

		_weapon_hit_scan(player(), array(raySize: 0.1), 16, array(
			tracer: 'END_ROD', 
			display: 'white_stained_glass',
			hitparticle: 'LAVA'
		), @pvp);

		play_sound(ploc(), array(sound: 'ENTITY_ZOMBIE_VILLAGER_CURE', pitch: 1.8, volume: 3));
		@item = pinv(player(), null);
		@item['qty'] -= 1;
		if(@item['qty'] == 0) {
			set_pinv(player(), null, null);
		} else {
			@item['name'] = 'FIREWORK_STAR';
			set_pinv(player(), null, @item);
			@slot = pheld_slot();
			set_pcooldown('FIREWORK_STAR', 8000 / 50);
			set_pcooldown('SUNFLOWER', 4000 / 50);
			set_timeout(8000, closure(){
				if(ponline(player()) && array_index_exists(@pvp['players'], player())) {
					@item = pinv(player(), @slot);
					if(!is_null(@item) && @item['name'] === 'FIREWORK_STAR' && !pcooldown('FIREWORK_STAR')) {
						play_sound(ploc(), array(sound: 'BLOCK_FIRE_EXTINGUISH', pitch: 0));
						@item['name'] = 'SUNFLOWER';
						set_pinv(player(), @slot, @item);
					}
				}
			});
		}
	}
}
