switch(@action) {
case 'load':
	bind('inventory_click', array('id': @player.'invclick'), array('player': @player), @event) {
		cancel();
	}
	
	bind('player_toggle_sprint', array('id': @player.'sprint'), array('player': @player), @event, @pvp) {
		@mode = pmode();
		if(@event['sprinting'] && @mode != 'SPECTATOR') {
			set_pmode('SPECTATOR');
			play_sound(ploc(), associative_array('sound': 'STEP_WOOL', 'pitch': 0.5));
		} else if(!@event['sprinting'] && @mode == 'SPECTATOR') {
			@armorstand = spawn_entity('ARMOR_STAND', 1, ploc())[0];
			set_entity_spec(@armorstand, associative_array('visible': false));
			set_interval(50, closure(){
				try {
					if(pmode() != 'SPECTATOR' || pinfo(player(), 19)) {
						clear_task();
						die();
					}
					@ploc = ploc();
					@ploc['y'] = @pvp['arena']['spawn'][0][0][1] + 1;
					if(get_block_at(@ploc) == '0:0') {
						set_entity_loc(@armorstand, @ploc);
						@seen = false;
						@hunter = puuid();
						foreach(@p in array_keys(@pvp['players'])) {
							if(@p != player() && entity_can_see(@armorstand, puuid(@p))) {
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
							entity_remove(@armorstand);
						}
					}
				} catch(Exception @ex) {
					clear_task();
				}
			});
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
		
		if(pmode(@player) == 'SPECTATOR') {
			die();
		}

		@hunter = puuid(@player);
		foreach(@p in array_keys(@pvp['players'])) {
			if(@p == @player, continue());
			if(entity_can_see(@hunter, puuid(@p)) && _distance(ploc(@p), ploc(@player)) < 6) {
				@helm = pinv(@p, 103);
				@loc = ploc(@p);
				if(is_null(@helm)) {
					set_pinv(@p, associative_array(103: associative_array('type': 86)));
					play_named_sound(@loc, associative_array('sound': 'entity.elder_guardian.death', 'pitch': 2), @p);
					set_phunger(@player, min(20, phunger(@player) + 1));
					set_phealth(@player, min(20, pinfo(@player, 5) + 1));
					set_peffect(@player, 5, 0, 2);
				}
				set_ptexp(@player, ptexp(@player) + 1);
				set_peffect(@p, 9, 0, 4);
				set_peffect(@p, 15, 0, 240);
				play_named_sound(@loc, array('sound': 'entity.guardian.attack', 'pitch': 2), @p);
			} else {
				set_pinv(@p, associative_array(103: null));
			}
		}
	});

case 'unload':
	unbind(@player.'invclick');
	unbind(@player.'sprint');
	set_pmode(@player, 'ADVENTURE');
}
