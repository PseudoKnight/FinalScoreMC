switch(@action) {
case 'load':
	tmsg(@player, color('e').'Hunt the other players. Do not let them escape via the stairs!');
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
	
	@sneak = array();
	
	proc _reveal(@player, @sneak, @pvp) {
		set_pinv(@player, associative_array(
			103: associative_array('name': 'BEDROCK'),
			102: associative_array('name': 'CHAINMAIL_CHESTPLATE')
		));
		foreach(@p: @pinfo in @pvp['players']) {
			if(@pinfo['team'] == 1) {
				psend_block_change(@p, @sneak[0], 0);
			}
		}
		@ploc = _relative(ploc(@player), 'up', 2);
		play_effect(@ploc, 'EXPLOSION_LARGE');
		play_sound(@ploc, associative_array('sound': 'ENDERMAN_DEATH', 'pitch': 2));
		array_remove(@sneak, 0);
	}
	
	bind(player_toggle_sneak, associative_array('id': @player.'sneak'), associative_array('player': @player), @event, @sneak, @pvp) {
		if(@event['sneaking']) {
			set_pinv(player(), associative_array(103: null, 102: null));
			@sneak[0] = _relative(ploc(), 'up', 1);
			foreach(@p: @player in @pvp['players']) {
				if(@player['team'] == 1) {
					psend_block_change(@p, @event['location'], 7);
				}
			}
		} else if(!pinv(player(), 103)) {
			_reveal(player(), @sneak, @pvp);
		}
	}

	set_interval(250, closure() {
		if(!array_index_exists(@pvp['players'], @player)) {
			clear_task();
			die();
		}
		
		try {
			if(pmode(@player) == 'SPECTATOR') {
				die();
			} else if(pinfo(@player, 11)) {
				if(@sneak && _distance(@sneak[0], ploc(@player)) > 1.5) {
					_reveal(@player, @sneak, @pvp);
				} else {
					die();
				}
			}
		} catch(PlayerOfflineException @ex) {
			clear_task();
			die();
		}

		@hunter = puuid(@player);
		foreach(@p in array_keys(@pvp['players'])) {
			if(@p == @player, continue());
			if(entity_can_see(@hunter, puuid(@p)) && (@dist = _distance(ploc(@p), ploc(@player))) < 6) {
				@helm = pinv(@p, 103);
				@loc = ploc(@p);
				if(is_null(@helm)) {
					set_pinv(@p, associative_array(103: associative_array('type': 86)));
					play_named_sound(@loc, associative_array('sound': 'entity.elder_guardian.death', 'pitch': 2), @p);
					set_phunger(@player, min(20, phunger(@player) + if(@dist < 3, 2, 1)));
					set_phealth(@player, min(20, pinfo(@player, 5) + if(@dist < 3, 2, 1)));
					set_peffect(@player, 5, 0, 2);
				}
				set_ptexp(@player, ptexp(@player) + 1);
				set_peffect(@p, 9, 0, 4);
				set_peffect(@p, 15, 0, 240);
				play_named_sound(@loc, array('sound': 'entity.guardian.attack', 'pitch': 1.5), @p);
			} else if(pinv(@p, 103)) {
				set_pinv(@p, associative_array(103: null));
			}
		}
	});

case 'unload':
	unbind(@player.'invclick');
	unbind(@player.'sprint');
	unbind(@player.'pickup');
	unbind(@player.'sneak');
	set_pmode(@player, 'ADVENTURE');
	set_pflyspeed(@player, 0.1);
}
