switch(@action) {
case 'load':
	tmsg(@player, color('e').'Hunt the other players!');
	tmsg(@player, color('e').'When you\'re spotted, you regain health and hunger.');
	tmsg(@player, color('e').'Sprint to "ghost" through walls and rematerialize out of sight.');
	tmsg(@player, color('e').'Scare them, hit them, and then ghost away to safety.');

	bind('inventory_click', array('id': @player.'invclick'), array('player': @player), @event) {
		cancel();
	}
	
	bind('item_pickup', array('id': @player.'pickup'), array('player': @player), @event) {
		cancel();
	}
	
	set_pflyspeed(@player, 0.08);
	bind('player_toggle_sprint', array('id': @player.'sprint'), array('player': @player), @event, @pvp) {
		@mode = pmode();
		if(@event['sprinting'] && @mode != 'SPECTATOR') {
			set_pmode('SPECTATOR');
			@loc = ploc();
			play_sound(@loc, associative_array('sound': 'BLOCK_WOOL_STEP', 'pitch': 0.5));
			spawn_particle(location_shift(@loc, 'up', 2), array(
				'particle': 'CRIT',
				'count': 10,
				'xoffset': 0.5,
				'yoffset': 1,
				'zoffset': 0.5,
			));
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
					@ploc['y'] = @pvp['arena']['spawn'][0][0]['y'] + 1;
					if(get_block(@ploc) == 'AIR') {
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
		if(!has_bind(@player.'sprint')) {
			clear_task();
			die();
		}
		
		try {
			if(pmode(@player) == 'SPECTATOR') {
				die();
			}
		} catch(PlayerOfflineException @ex) {
			clear_task();
			die();
		}

		@hunter = puuid(@player);
		foreach(@p: @data in @pvp['players']) {
			if(@p == @player, continue());
			if(entity_can_see(@hunter, puuid(@p)) && (@dist = distance(ploc(@p), ploc(@player))) < 6) {
				@helm = pinv(@p, 103);
				@loc = ploc(@p);
				if(is_null(@helm)) {
					set_pinv(@p, 103, array('name': 'CARVED_PUMPKIN'));
					play_sound(@loc, associative_array('sound': 'ENTITY_ELDER_GUARDIAN_DEATH', 'pitch': 2), @p);
					set_phunger(@player, min(20, phunger(@player) + 1));
					set_phealth(@player, min(20, phealth(@player) + if(@dist < 2, 2, 1)));
					set_peffect(@player, 5, 0, 2);
					@data['heartrate'] = max(300, @data['heartrate'] - 200);
					@data['lastscare'] = time();
				}
				set_ptexp(@player, ptexp(@player) + 1);
				set_peffect(@p, 9, 0, 4);
				play_sound(@loc, array('sound': 'ENTITY_GUARDIAN_ATTACK', 'pitch': 1.5), @p);
			} else if(pinv(@p, 103)) {
				set_pinv(@p, 103, null);
			}
		}
	});

case 'unload':
	unbind(@player.'invclick');
	unbind(@player.'sprint');
	unbind(@player.'pickup');
	set_pmode(@player, 'ADVENTURE');
	set_pflyspeed(@player, 0.1);
}
