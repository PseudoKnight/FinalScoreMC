switch(@action) {
case 'load':
	bind('inventory_click', array('id': @player.'invclick'), array('player': @player), @event) {
		cancel();
	}
	
	bind('player_toggle_sprint', array('id': @player.'sprint'), array('player': @player), @event, @pvp) {
		if(@event['sprinting']) {
			set_pmode('SPECTATOR');
		} else {
			if(pmode() == 'SPECTATOR') {
				set_interval(50, closure(){
					try {
						if(pmode() != 'SPECTATOR') {
							clear_task();
							die();
						}
						@ploc = ploc();
						@ploc['y'] = @pvp['arena']['spawn'][0][0][1] + 1;
						if(get_block_at(@ploc) == '0:0') {
							@seen = false;
							@hunter = puuid();
							foreach(@p in array_keys(@pvp['players'])) {
								if(@p != player() && entity_can_see(@hunter, puuid(@p))) {
									@seen = true;
									break();
								}
							}
							if(!@seen) {
								set_pmode('ADVENTURE');
								@ploc['x'] = floor(@ploc['x']) + 0.5;
								@ploc['y'] -= 1;
								@ploc['z'] = floor(@ploc['z']) + 0.5;
								set_ploc(@ploc);
								clear_task();
							}
						}
					} catch(Exception @ex) {
						clear_task();
					}
				});
			}
		}
	}

	set_interval(250, closure() {
		try {
			if(pinv(@player, 103)['type'] != 7) {
				clear_task();
				die();
			}
		} catch(Exception @ex) {
			clear_task();
			die();
		}

		@hunter = puuid(@player);
		foreach(@p in array_keys(@pvp['players'])) {
			if(@p == @player, continue());
			@helm = pinv(@p, 103);
			if(entity_can_see(@hunter, puuid(@p)) && _distance(ploc(@p), ploc(@player)) < 6) {
				@loc = ploc(@p);
				if(is_null(@helm)) {
					set_inventory_item(puuid(@p), 103, associative_array('type': 86));
					play_named_sound(@loc, associative_array('sound': 'entity.elder_guardian.death', 'pitch': 2), @p);
					set_phunger(@player, min(20, phunger(@player) + 1));
					set_phealth(@player, min(20, pinfo(@player, 5) + 1));
				}
				set_ptexp(@player, ptexp(@player) + 1);
				set_peffect(@p, 9, 0, 4);
				play_named_sound(@loc, array('sound': 'entity.guardian.attack', 'pitch': 2));
			} else if(!is_null(@helm) && @helm['type'] == 86) {
				set_inventory_item(puuid(@p), 103, null);
			}
		}
	});

case 'unload':
	unbind(@player.'invclick');
	unbind(@player.'sprint');
	set_pmode(@player, 'ADVENTURE');
}
