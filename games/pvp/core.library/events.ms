proc _bind_events(@pvp) {
	@id = @pvp['id'];

	# Arena specific events
	if(array_contains(@pvp['arena']['flags'], 'script')){
		@arenaScript = "../arenas.library/@id.ms";
		if(file_exists(@arenaScript)){
			include(@arenaScript);
		}
		_arena_bind_events(@id);
	}

	# Optional events
	foreach(@option in array('blockbreak', 'captain', 'chestspawn', 'mobprotect', 'powerup')) {
		if(array_index_exists(@pvp['arena'], @option)) {
			include("../events.library/@option.ms");
			_bind(@pvp);
		}
	}

	foreach(@flag in array('infinitedispensers', 'nobottles', 'noinventory', 'rallycall', 'stackedpickup')) {
		if(array_contains(@pvp['arena']['flags'], @flag)) {
			include("../events.library/@flag.ms");
			_bind(@pvp);
		}
	}

	foreach(@flag in array('build')) {
		if(!array_contains(@pvp['arena']['flags'], @flag)) {
			include("../events.library/@flag.ms");
			_bind(@pvp);
		}
	}

	if(@pvp['arena']['respawnmode'] == 'mob') {
		@pvp['binds'][] = bind('entity_death', null, array(type: 'VILLAGER'), @e, @pvp, @id) {
			foreach(@team: @data in @pvp['team']) {
				@index = array_index(@data['respawns'], @e['id']);
				if(!is_null(@index)) {
					array_remove(@data['respawns'], @index);
					set_pscore('respawns', @pvp['arena']['team'][@team]['name'], array_size(@data['respawns']), @id);
					break();
				}
			}
		}
	}

	# Main events
	@pvp['binds'][] = bind('player_death', array(priority: 'HIGH'), null, @e, @pvp, @id) {
		@pvp = import('pvp'.@id);
		@arena = @pvp['arena'];
		if(!array_index_exists(@pvp['players'], player())) {
			die();
		}

		@playerData = @pvp['players'][player()];
		@team = array_get(@playerData, 'team', 0);
		@deathmessage = @e['death_message'];
		@killer = @e['killer'];
		@location = @e['location'];

		// Stats
		if(array_index_exists(@pvp, 'stats')) {
			if(@e['cause']['cause'] === 'CUSTOM'
			&& @pvp['stats'][player()]['damaged'] + 5000 > time()) {
				@killer = @pvp['stats'][player()]['damager'];
				@deathmessage = player().' was doomed by '.@killer;
			}

			if(@pvp['stats'][player()]['lastdamager'] !== ''
			&& @pvp['stats'][player()]['lastdamaged'] + 5000 > time()) {
				@lastdamager = @pvp['stats'][player()]['lastdamager'];
				@deathmessage .= ', assisted by '
					.if(array_index_exists(@pvp['players'], @lastdamager), @pvp['players'][@lastdamager]['color'])
					.@lastdamager.color('r');
			}

			@pvp['stats'][player()]['deaths'] += 1;
			if(array_index_exists(@pvp['stats'], @killer)
			&& @killer != player()) {
				@pvp['stats'][@killer]['kills'] += 1;
			}

			@pvp['stats'][player()]['lastdamaged'] = 0;
			@pvp['stats'][player()]['lastdamager'] = '';
			@pvp['stats'][player()]['damaged'] = 0;
			@pvp['stats'][player()]['damager'] = '';
		}

		// Death Message
		if(array_index_exists(@arena, 'team')) {
			@parts = parse_args(@deathmessage);
			@parts[0] = @playerData['color'].player().color('r');
			if(array_index_exists(@pvp['players'], @killer)) {
				for(@i = 1, @i < array_size(@parts), @i++) {
					if(@parts[@i] == @killer) {
						@parts[@i] = if(array_index_exists(@pvp['players'], @killer), @pvp['players'][@killer]['color'])
							.@killer.color('r');
						break();
					}
				}
			}
			@deathmessage = array_implode(@parts);
		}
		_pvp_msg(@pvp, @deathmessage);

		// Lives
		if(array_index_exists(@arena, 'lives')) {
			@playerData['lives']--;
			if(@arena['lives'] > 1) {
				set_pscore('lives', player(), @playerData['lives'], @id);
			}

		} else if(@arena['mode'] === 'infection' && @playerData['team'] == 0) {
			team_remove_player(@arena['team'][@team]['name'], player(), @id);
			array_remove_values(@pvp['team'][0]['players'], player());
			@playerData['team'] = 1;
			@playerData['color'] = @arena['team'][1]['color'];
			team_add_player(@arena['team'][1]['name'], player(), @id);
			set_timeout(50, closure(){
				if(array_index_exists(@arena, 'classes')) {
					if(array_index_exists(@playerData, 'class')) {
						_classes_unload(player(), @playerData['class'], @pvp);
						array_remove(@playerData, 'class');
					}
					foreach(@classname: @class in @arena['classes']) {
						if(!array_index_exists(@class, 'disabled')
						&& (!array_index_exists(@class, 'team') || @class['team'] == @team)) {
							@playerData['class'] = @classname;
							_classes_load(player(), @playerData['class'], @pvp);
						}
					}
				}
			});
		}

		// Inventory and Drops
		@drops = array();
		if(array_contains(@arena['flags'], 'keepinventory')) {
			@inv = pinv();
			if(array_index_exists(@arena, 'dropchance')) {
				proc _drop(@inv, @slot, @chance) {
					@item = @inv[@slot];
					if(@item && rand(100) < @chance) {
						@qtyLeft = floor(@item['qty'] / 2);
						@item['qty'] = @item['qty'] - @qtyLeft;
						drop_item(player(), @item);
						msg('You dropped: '.if(@item['qty'] > 1, @item['qty'].' ').@item['name']);
						if(@qtyLeft) {
							@item['qty'] = @qtyLeft;
						} else {
							@inv[@slot] = null;
						}
					}
				}
				foreach(@slot in 0..35) {
					_drop(@inv, @slot, @arena['dropchance']);
				}
				foreach(@slot in 100..103) {
					_drop(@inv, @slot, @arena['dropchance']);
				}
				_drop(@inv, -106, @arena['dropchance']);
			}
			@playerData['inv'] = @inv;
		} else {
			foreach(@drop in @e['drops']) {
				if(!@drop) {
					continue();
				}
				if(@arena['mode'] === 'ctf' && !is_null(@flag = _flag(@drop))) {
					_pvp_msg(@pvp, color('gray').'[PVP] '.@playerData['color']
						.player().color('r').' dropped the '.@arena['team'][@flag]['color'].'flag')
					if(@e['cause']['cause'] === 'VOID' || @e['cause']['cause'] === 'LAVA') {
						_pvp_flag_spawn(@id, @flag);
					} else {
						_pvp_flag_spawn(@id, @flag, location_shift(ploc(), 'up'));
					}
				} else if(@arena['mode'] == 'bombingrun' && _is_bomb(@pvp, @drop)) {
					@pvp['bombholder'] = null;
					switch(@e['cause']['cause']) {
						case 'VOID':
						case 'LAVA':
						case 'FIRE':
						case 'FIRE_TICK':
							_pvp_bomb_spawn(@pvp);
						default:
							_pvp_bomb_spawn(@pvp, location_shift(ploc(), 'up'));
					}
				} else if(array_index_exists(@arena, 'captain')
				&& @drop['name'] == @pvp['team'][@team]['captainhat']['name']) {
					@pvp['team'][@team]['captain'] = '';
					_classes_unload(player(),@playerData['class'], @pvp);
					foreach(@classname: @class in @arena['classes']) {
						if(@classname != @playerData['class']
						&& !array_index_exists(@class, 'disabled')
						&& (!array_index_exists(@class, 'team') || @class['team'] == @team)) {
							@playerData['class'] = @classname;
							break();
						}
					}
					_classes_load(player(), @playerData['class'], @pvp);
					_pvp_msg(@pvp, color('gray').'[PVP] '.@playerData['color']
						._to_upper_camel_case(@arena['team'][@team]['name']).color('r').' - Captain has died and dropped his hat!');
					foreach(@p: @player in @pvp['players']) {
						if(@player['team'] == @team) {
							set_compass_target(@p, ploc());
						}
					}

					if(@e['cause']['cause'] === 'VOID' || @e['cause']['cause'] === 'LAVA') {
						_pvp_hat_spawn(@id, @team);
					} else {
						_pvp_hat_spawn(@id, @team, location_shift(ploc(), 'up'));
					}
				} else if(!array_index_exists(@arena, 'denydrop')
				|| array_index_exists(@arena, 'denydrop')
				&& is_array(@arena['denydrop'])
				&& !array_contains(@arena['denydrop'], @drop['name'])) {
					@drops[] = @drop;
				}
			}
		}

		// Don't actually die
		_player_reset(player());

		// Respawning
		if(@arena['respawnmode'] == 'mob'
		&& !@pvp['team'][@team]['respawns']) {
			_player_to_spectator(player(), @pvp);

		} else if(array_index_exists(@arena, 'lives')
		&& !@playerData['lives']) {
			_player_to_spectator(player(), @pvp);

		} else {
			// Class Selection & Equip
			if(!array_index_exists(@arena, 'respawntime')) {
				set_timeout(50, closure(){ // wait until after fake death to fix fake inventory
					_player_equip(@id, player());
				});
			} else if(array_index_exists(@arena, 'classes')) {
				if(array_index_exists(@playerData, 'class')) {
					_classes_unload(player(), @playerData['class'], @pvp);
				}
				if(@arena['class_picking'] === 'random') {
					_classes_select_random(player(), @pvp);
				} else if(!array_index_exists(@arena, 'class_picks')
				|| (array_index_exists(@playerData, 'picks') && @playerData['picks'] > 0)) {
					if(array_index_exists(@playerData, 'picks')
					&& @playerData['picks'] < @playerData['lives']) {
						msg(color('gold').@playerData['picks'].' class picks left.');
					}
					if(!array_index_exists(@playerData, 'team') || @playerData['team'] == 0) {
						set_timeout(300, closure(){
							if(array_contains(get_virtual_inventories(), @id.'0')) {
								popen_inventory(player(), @id.'0');
							}
						});
					} else {
						set_timeout(300, closure(){
							if(array_contains(get_virtual_inventories(), @id.'1')) {
								popen_inventory(player(), @id.'1');
							}
						});
					}
				}
			}

			// Teleport
			if(array_index_exists(@arena, 'respawntime') && @pvp['running'] == 2) {
				@playerData['respawn'] = time() + (@arena['respawntime'] * 1000) - 50; // 50ms tick precision
				set_pmode('SPECTATOR');
				if(!array_contains(sk_current_regions(), @arena['region'])) {
					if(ponline(@killer)) {
						set_ploc(ploc(@killer));
					} else {
						@distance = 128;
						@closest = '';
						foreach(@p in array_keys(@pvp['players'])) {
							if(@p == player() && array_contains(sk_current_regions(), @arena['region'])) {
								continue();
							}
							@pDistance = distance(ploc(@p), @location);
							if(@pDistance < @distance) {
								@distance = @pDistance;
								@closest = @p;
							}
						}
						if(@closest) {
							set_ploc(ploc(@closest));
						} else {
							set_ploc(@arena['spawn'][0][0]);
						}
					}
				}
			} else if(@arena['respawnmode'] == 'mob') {
				while(@pvp['team'][@team]['respawns']) {
					@uuid = @pvp['team'][@team]['respawns'][0];
					try {
						@loc = entity_loc(@uuid);
						@loc[1] -= 1;
						set_ploc(@loc);
						entity_remove(@uuid);
						array_remove(@pvp['team'][@team]['respawns'], 0);
						set_pscore('respawns', @arena['team'][@team]['name'], array_size(@pvp['team'][@team]['respawns']), @id);
						die();
					} catch(BadEntityException @ex) {
						// Either the mob is dead or the chunk is unloaded.
						// Remove it just to be sure.
						array_remove(@pvp['team'][@team]['respawns'], 0);
					}
				}
				_player_to_spectator(player(), @pvp);
			} else {
				@r = rand(0, array_size(@arena['spawn'][@team]));
				set_ploc(@arena['spawn'][@team][@r]);
			}
		}

		// Death Effects
		set_peffect(player(), 'BLINDNESS', 0, 0.3);
		set_peffect(player(), 'NIGHT_VISION', 0, 0.3);
		title(player(), 'You died.', '', 0, 6, 0);
		foreach(@item in @drops) {
			drop_item(@location, @item);
		}
		@deadplayer = spawn_entity('SKELETON', 1, @location, closure(@deadplayer) {
			add_scoreboard_tag(@deadplayer, 'nodrops');
			set_mob_equipment(@deadplayer, array(WEAPON: null));
		})[0];
		set_entity_health(@deadplayer, 0);

		modify_event('drops', null);
		modify_event('xp', null);
		set_timeout(1000, closure(){
			// just in case of a tie
			_pvp_check_objectives(@id);
		});
	}

	@pvp['binds'][] = bind('player_quit', array(priority: 'HIGH'), null, @e, @pvp, @id) {
		if(array_index_exists(@pvp['players'], player())) {
			modify_event('message', color('gray').'[PVP] '.@pvp['players'][player()]['color'].@e['message']);
			_player_remove(player(), @id);
		} else if(array_contains(@pvp['spectators'], player())) {
			_spectator_remove(player(), @pvp);
		}
	}

	@pvp['binds'][] = bind('entity_death', null, null, @event, @pvp) {
		if(!_is_survival_world(@event['location']['world'])
		&& array_contains(sk_regions_at(@event['location']), @pvp['arena']['region'])) {
			if(array_contains(get_scoreboard_tags(@event['id']), 'nodrops')) {
				modify_event('drops', null);
			}
			if(array_contains(@pvp['arena']['flags'], 'noxp')) {
				modify_event('xp', 0);
			}
		}
	}

	@pvp['binds'][] = bind('player_teleport', array(priority: 'HIGH'), array(type: 'ENDER_PEARL'), @e, @pvp) {
		if(array_index_exists(@pvp['players'], player())) {
			consume();
			if(!array_contains(sk_regions_at(@e['to']), @pvp['arena']['region'])) {
				cancel();
			}
		}
	}

	@pvp['binds'][] = bind('player_command', null, null, @e, @pvp, @id) {
		if(!array_contains(array('/accept', '/warp', '/spawn', '/home', '/join', '/dev', '/park', '/survival'), @e['prefix'])) {
			die();
		}

		if(array_index_exists(@pvp['players'], player())) {
			_pvp_msg(@pvp, color('gray').'[PVP] '.@pvp['players'][player()]['color'].player().color('r').' left the arena.');
			_player_remove(player(), @id);
		} else if(array_contains(@pvp['spectators'], player())) {
			_spectator_remove(player(), @pvp);
		}
	}

	@pvp['binds'][] = bind('entity_damage', array(priority: 'LOWEST'), null, @e, @pvp) {
		if(@e['type'] === 'PLAYER' && array_index_exists(@pvp['players'], player())) {
			@damager = '';
			if(array_index_exists(@e, 'shooter')) {
				if(array_index_exists(@pvp['players'], @e['shooter'])) {
					@damager = @e['shooter'];
				} else {
					try {
						@damager = get_mob_owner(@e['shooter']);
					} catch(Exception @ex) {
						die();
					}
				}
			} else if(array_index_exists(@e, 'damager')) {
				if(array_index_exists(@pvp['players'], @e['damager'])) {
					@damager = @e['damager'];
				} else {
					try {
						@damager = get_mob_owner(@e['damager']);
					} catch(Exception @ex) {
						die();
					}
				}
			}

			if(!@damager) {
				// We want to attribute as much damage as possible.
				// This is debug logging so that we can capture more.
				@cause = @e['cause'];
				@amount = @e['amount'];
				// Don't log self-inflicted damage unless induced by another player.
				@unattributedTypes = array(
					'FLY_INTO_WALL', // never attribute
					'FALL', // attribute only when very recently hit, though accuracy may be difficult
					'LAVA', // players can knock other players into hazards
					'FIRE', // standing in fire; treat similar to lava
					'FIRE_TICK', // certain abilities set players on fire, damaging over time
					'WITHER', // certain abilties apply wither effect (eg. silken fangs), similar to fire_tick
					'POISON', // splash potions and other abilities, similar to fire_tick and wither
					'BLOCK_EXPLOSION' // custom explosions, always caused by abilities and should be attributable
				);
				if(!array_contains(@unattributedTypes, @cause)) {
					console("Unattributed damage: {cause: @cause, amount: @amount}", false);
				}
				die();
			}

			if(@pvp['arena']['ff'] != 'true'
			&& ((array_index_exists(@pvp['arena'], 'team') && @pvp['players'][ player()]['team'] == @pvp['players'][@damager]['team'])
			|| (!array_index_exists(@pvp['arena'], 'team') &&  player() == @damager))) {
				@ff = @pvp['arena']['ff'];
				if(@ff == 'knockback') {
					modify_event('amount', 0);
				} else if(@ff == 'reduced') {
					modify_event('amount', @e['amount'] / 3);
				} else {
					cancel();
				}
			} else {
				_stats_damage(@damager, player(), @e['amount'], @pvp);
			}
		}
	}

	@pvp['binds'][] = bind('entity_damage', array(priority: 'HIGHEST'), array(cause: 'ENTITY_EXPLOSION'), @event, @pvp) {
		if(entity_type(@event['damager']) == 'FIREWORK') {
			foreach(@player in array_keys(@pvp['players'])) {
				if(get_firework_shooter(@event['damager']) == puuid(@player)) {
					consume();
					if(array_index_exists(@event, 'player')) {
						_stats_damage(@player, @event['player'], @event['amount'], @pvp);
					}
					break();
				}
			}
		}
	}

	// barrier eat projectiles
	@pvp['binds'][] = bind('projectile_hit', array(priority: 'HIGHEST'), array(hittype: 'BLOCK', type: 'ARROW'), @event, @pvp) {
		if(get_block(@event['hit']) == 'BARRIER') {
			consume();
			try(entity_remove(@event['id']))
		}
	}
}
