switch(@action) {
case 'load':
	proc _set_equipment(@player, @thorns, @pvp) {
		if(array_index_exists(@pvp['players'], @player) && @pvp['players'][@player]['class'] == 'ent') {
			@kit = array(
				'helmet': array('name': 'LOG', 'data': 1),
				'chestplate': array('name': 'LEATHER_CHESTPLATE', 'meta': array(
					'color': array('r': 0, 'g': 50, 'b': 0),
				)),
				'leggings': array('name': 'LEATHER_LEGGINGS', 'meta': array(
					'color': array('r': 58, 'g': 28, 'b': 1),
				)),
				'boots': array('name': 'LEATHER_BOOTS', 'meta': array(
					'color': array('r': 58, 'g': 28, 'b': 1),
				)),
			);
			if(@thorns) {
				@enchants = array(array('elevel': 13, 'etype': 'THORNS'));
				foreach(@item in @kit) {
					@item['enchants'] = @enchants;
				}
				set_peffect(@player, 11, 0, 999);
			} else {
				set_peffect(@player, 11, 0, 0);
			}
			set_mob_equipment(puuid(@player), @kit);
		}
	}

	bind(item_held, array('id': @player.'entbark'), null, @event, @player, @pvp) {
		if(@player == player() && (@event['to'] == 1 && pinv(player(), 1) || @event['from'] == 1)) {
			_set_equipment(player(), @event['to'] == 1, @pvp);
		}
	}
	
	bind(entity_damage, array('id': @player.'entdamage', 'priority': 'MONITOR'), array('id': puuid(@player)), @event, @player, @pvp) {
		if(pheld_slot(@player) == 1) {
			@item = pinv(@player, 1);
			if(@item) {
				@item['qty']--;
				if(@item['qty'] == 0) {
					set_pinv(@player, 1, null);
					_set_equipment(@player, false, @pvp);
				} else {
					set_pinv(@player, 1, @item);
				}
			}
		}
	}

	bind(entity_damage, array('id': @player.'entfall'), array('id': puuid(@player), 'cause': 'FALL'), @event, @player, @pvp) {
		@damage = @event['amount'];
		@target = entity_loc(@event['id']);
		@world = @target['world'];
		
		modify_event('amount', @damage * 0.1);
		foreach(@p in players_in_radius(@target, 6)) {
			if(@p != @player && array_index_exists(@pvp['players'], @p) && pmode(@p) != 'SPECTATOR') {
				damage_entity(puuid(@p), @damage, puuid(@player));
			}
		}
		play_sound(@target, array('sound': 'entity_wither_break_block', 'pitch': 0.7));
		
		@radius = 6;
		@circle = array();
		for(@angle = 0, @angle < 6.28, @angle += 0.5) {
			@circle[] = array(
				@radius * cos(@angle) + @target['x'],
				@target['y'],
				@radius * sin(@angle) + @target['z'],
				@world,
			);
		}
		
		foreach(@point in @circle) {
			if(get_block_at(@point) == '0:0') {
				play_effect(@point, 'TILE_BREAK', array('id': 3, 'particleCount': 5));
				if(get_block_at(location_shift(@point, 'down')) != '0:0') {
					foreach(@p in all_players(@world)) {
						psend_block_change(@p, @point, 32);
					}
				}
			}
		}
		
		set_timeout(1000, closure(){
			foreach(@point in @circle) {
				@block = get_block_at(@point);
				if(@block == '0:0') {
					foreach(@p in all_players(@world)) {
						psend_block_change(@p, @point, @block);
					}
				}
			}
		});
	}
	
	bind(player_toggle_sneak, array('id': @player.'entsneak'), array('player': @player, 'sneaking': true), @event, @pvp) {
		if(pheld_slot() != 0) {
			die();
		}
		set_pexp(0);
		@loc = ploc();
		play_sound(@loc, array('sound': 'entity_illusion_illager_prepare_blindness', 'pitch': 0.7));
		play_sound(@loc, array('sound': 'entity_husk_ambient', 'pitch': 0.8));
		try(set_attribute(puuid(), 'knockbackresistance', 1));
		set_interval(100, closure(){
			try {
				if(!psneaking() || pheld_slot() != 0) {
					clear_task();
					set_pexp(0);
					try(set_attribute(puuid(), 'knockbackresistance', 0));
					die();
				}
				@xp = pexp();
				if(@xp < 99) {
					set_pexp(min(99, @xp + 3));
				} else {
					clear_task();
					set_pexp(0);
					try(set_attribute(puuid(), 'knockbackresistance', 0));
					@players = _weapon_hit_scan(player(), 13, 2, array('tracerparticle': 'HAPPY_VILLAGER'), @pvp);
					@loc = ploc();
					if(@players) {
						@p = @players[0];
						play_sound(@loc, array('sound': 'block_chest_open', 'pitch': 0.6));
						@timer = array(20);
						set_interval(50, closure(){
							@timer[0]--;
							try {
								if(@timer[0] <= 0) {
									clear_task();
									@facing = pfacing(player());
									@facing[0] = @facing[0] + 90;
									@facing[1] = 0 - @facing[1];
									@x = 1.60 * cos(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
									@y = max((1.60 * sin(to_radians(@facing[1]))) + 0.2, 0.2);
									@z = 1.60 * sin(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
									set_pvelocity(@p, @x, @y, @z);
									@loc = ploc();
									play_sound(@loc, array('sound': 'entity_player_attack_sweep', 'pitch': 1.4));
									play_sound(@loc, array('sound': 'entity_snowball_throw', 'pitch': 0.52));
								} else {
									set_ploc(@p, location_shift(ploc(), 'up', 2));
								}
							} catch(PlayerOfflineException @ex) {
								clear_task();
							}
						});
					} else {
						play_sound(@loc, array('sound': 'entity_player_attack_sweep', 'pitch': 1.4));
						play_sound(@loc, array('sound': 'entity_snowball_throw', 'pitch': 0.52));
					}
				}
			} catch(PlayerOfflineException @ex) {
				clear_task();
			}
		});
	}
	
	bind(player_death, array('id': @player.'entdeath'), array('player': @player), @event) {
		drop_item(@event['location'], array('name': 'APPLE'), true);
		play_sound(@event['location'], array('sound': 'entity_husk_death', 'pitch': 0.5));
	}
	
	bind(player_interact, array('id': @player.'entattack'), array('player': @player, 'item': 18, 'hand': 'main_hand', 'button': 'right'), @event) {
		if(!pcooldown('LEAVES')) {
			@loc = ptarget_space();
			if(get_block_at(location_shift(@loc, 'down')) != '0:0') {
				set_pcooldown('LEAVES', 5);
				@loc['x'] += 0.5;
				@loc['z'] += 0.5;
				play_sound(@loc, array('sound': 'entity_wither_break_block', 'pitch': 1.5, 'volume': 0.7));
				play_sound(ploc(), array('sound': 'entity_player_attack_sweep', 'pitch': 2));
				foreach(@p in all_players(pworld())) {
					if(@p == player()) {
						set_timeout(50, closure(){
							psend_block_change(player(), @loc, 32);
						});
					} else {
						psend_block_change(@p, @loc, 32);
					}
				}
				foreach(@p in players_in_radius(@loc, 1)) {
					damage_entity(puuid(@p), 3.5, puuid());
				}
				set_timeout(1000, closure(){
					foreach(@p in all_players(pworld())) {
						psend_block_change(@p, @loc, 0);
					}
				});
			}
		}
	}
	
case 'unload':
	unbind(@player.'entfall');
	unbind(@player.'entsneak');
	unbind(@player.'entbark');
	unbind(@player.'entdamage');
	unbind(@player.'entdeath');
	unbind(@player.'entattack');
	try(set_attribute(puuid(@player), 'knockbackresistance', 0));
}
