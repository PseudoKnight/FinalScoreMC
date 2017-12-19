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
			play_sound(@loc, associative_array('sound': 'STEP_WOOL', 'pitch': 0.5));
			play_effect(_relative(@loc, 'up', 2), 'CRIT', associative_array(
				'speed': 0,
				'particleCount': 10,
				'offsetX': 0.5,
				'offsetY': 1,
				'offsetZ': 0.5,
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
			if(entity_can_see(@hunter, puuid(@p)) && (@dist = _distance(ploc(@p), ploc(@player))) < 6) {
				@helm = pinv(@p, 103);
				@loc = ploc(@p);
				if(is_null(@helm)) {
					set_pinv(@p, 103, array('name': 'PUMPKIN'));
					play_named_sound(@loc, associative_array('sound': 'entity.elder_guardian.death', 'pitch': 2), @p);
					set_phunger(@player, min(20, phunger(@player) + 1));
					set_phealth(@player, min(20, phealth(@player) + if(@dist < 2, 2, 1)));
					set_peffect(@player, 5, 0, 2);
					@data['heartrate'] = max(300, @data['heartrate'] - 200);
					@data['lastscare'] = time();
				}
				set_ptexp(@player, ptexp(@player) + 1);
				set_peffect(@p, 9, 0, 4);
				play_named_sound(@loc, array('sound': 'entity.guardian.attack', 'pitch': 1.5), @p);
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
