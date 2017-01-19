# The assign() functions in the event binds are required to keep the instances from interfering with each other
# Just passing the variable (eg. ", @pvp['arena'], @id,") did not work last I tested
array_push(@pvp['binds'], @id.'death')
bind(player_death, array('priority': 'high', 'id': @id.'death'), null, @e, @id) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player())) {
		die();
	}

	@deathmessage = @e['death_message'];
	@killer = @e['killer'];

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

	if(array_index_exists(@pvp['arena'], 'team')) {
		@parts = parse_args(@deathmessage);
		@parts[0] = @pvp['players'][player()]['color'].player().color('r');
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

	_regionmsg(@pvp['arena']['broadcast'], @deathmessage);

	if(array_index_exists(@pvp['arena'], 'lives')) {
		@pvp['players'][player()]['lives'] = @pvp['players'][player()]['lives'] - 1
		if(@pvp['arena']['lives'] > 1) {
			set_pscore('lives', player(), @pvp['players'][player()]['lives'], @id)
		}

	} else if(@pvp['arena']['mode'] === 'infection' && @pvp['players'][player()]['team'] == 0) {
		team_remove_player(@pvp['arena']['team'][@pvp['players'][player()]['team']]['name'], player(), @id)
		array_remove_values(@pvp['team'][0]['players'], player())
		@pvp['players'][player()]['team'] = 1
		@pvp['players'][player()]['color'] = @pvp['arena']['team'][1]['color']
		team_add_player(@pvp['arena']['team'][1]['name'], player(), @id)
		set_timeout(50, closure(){
			if(array_index_exists(@pvp['arena'], 'classes')) {
				if(array_index_exists(@pvp['players'][player()], 'class')) {
					_class('unload', player(), @pvp['players'][player()]['class'], @pvp)
					array_remove(@pvp['players'][player()], 'class')
				}
				foreach(@classname: @class in @pvp['arena']['classes']) {
					if(!array_index_exists(@class, 'team') || @class['team'] == @pvp['players'][player()]['team']) {
						@pvp['players'][player()]['class'] = @classname
						_class('load', player(), @pvp['players'][player()]['class'], @pvp)
					}
				}
			}
		});
	}
	set_timeout(5000, closure(){
		try {
			if(pinfo(player(), 5) <= 0) {
				if(function_exists('respawn')) {
					respawn(player())
				}
			}
		} catch(PlayerOfflineException @ex) {
			// rage quit
		}
	})

	if(array_index_exists(@pvp['arena'], 'respawntime')) {
		@pvp['players'][player()]['respawn'] = time() + (@pvp['arena']['respawntime'] * 1000)
	}

	@drops = array();
	if(array_contains(@pvp['arena']['flags'], 'keepinventory')) {
		@inv = pinv();
		if(array_index_exists(@pvp['arena'], 'dropchance')) {
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
				_drop(@inv, @slot, @pvp['arena']['dropchance']);
			}
			foreach(@slot in 100..103) {
				_drop(@inv, @slot, @pvp['arena']['dropchance']);
			}
			_drop(@inv, -106, @pvp['arena']['dropchance']);
		}
		@pvp['players'][player()]['inv'] = @inv;
	} else {
		foreach(@drop in @e['drops']) {
			if(!@drop) {
				continue();
			}
			if(@pvp['arena']['mode'] === 'ctf' && !is_null(@flag = _flag(@drop))) {
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.@pvp['players'][player()]['color']
					.player().color('r').' dropped the '.@pvp['arena']['team'][@flag]['color'].'flag')
				if(@e['cause']['cause'] === 'VOID' || @e['cause']['cause'] === 'LAVA') {
					_pvp_flag_spawn(@id, @flag)
				} else {
					_pvp_flag_spawn(@id, @flag, _relative(ploc(), 'up'))
				}
			} else if(array_index_exists(@pvp['arena'], 'captain')
			&& @drop['type'] == @pvp['team'][@pvp['players'][player()]['team']]['captainhat']['type']
			&& (max_stack_size(@pvp['team'][@pvp['players'][player()]['team']]['captainhat']['type']) == 1
			|| @drop['data'] == @pvp['team'][@pvp['players'][player()]['team']]['captainhat']['data'])) {
				@pvp['team'][@pvp['players'][player()]['team']]['captain'] = ''
				_class('unload', player(), @pvp['players'][player()]['class'], @pvp)
				foreach(@classname: @class in @pvp['arena']['classes']) {
					if(@classname != @pvp['players'][player()]['class']
					&& (!array_index_exists(@class, 'team') || @class['team'] == @pvp['players'][player()]['team'])) {
						@pvp['players'][player()]['class'] = @classname
						break()
					}
				}
				_class('load', player(), @pvp['players'][player()]['class'], @pvp)
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.@pvp['players'][player()]['color']
					.to_upper(@pvp['arena']['team'][@pvp['players'][player()]['team']]['name']).color('r').' - Captain has died and dropped his hat!')
				foreach(@p: @player in @pvp['players']) {
					if(@player['team'] == @pvp['players'][player()]['team']) {
						set_compass_target(@p, ploc())
					}
				}

				if(@e['cause']['cause'] === 'VOID' || @e['cause']['cause'] === 'LAVA') {
					_pvp_hat_spawn(@id, @pvp['players'][player()]['team'])
				} else {
					_pvp_hat_spawn(@id, @pvp['players'][player()]['team'], _relative(ploc(), 'up'))
				}
			} else if(!array_index_exists(@pvp['arena'], 'denydrop')
			|| array_index_exists(@pvp['arena'], 'denydrop')
			&& is_array(@pvp['arena']['denydrop'])
			&& !array_contains(@pvp['arena']['denydrop'], @drop['type'])) {
				array_push(@drops, @drop)
			}
		}
	}

	if(@pvp['arena']['respawnmode'] == 'mob'
	&& !@pvp['team'][@pvp['players'][player()]['team']]['respawns']) {
		_remove_player(player(), @pvp);

	} else if(array_index_exists(@pvp['arena'], 'lives')
	&& !@pvp['players'][player()]['lives']) {
		_remove_player(player(), @pvp);
	}

	modify_event('drops', @drops)
	modify_event('xp', null)
	_pvp_check_objectives(@id)
}

array_push(@pvp['binds'], @id.'quit')
bind(player_quit, array('id': @id.'quit', 'priority': 'HIGH'), null, @e, @id) {
	@pvp = import('pvp'.@id)
	if(array_index_exists(@pvp['players'], player())) {
		if(@pvp['arena']['mode'] === 'ctf'
		&& !is_null(@flag = _flag(pinv(player(), 103)))) {
			_pvp_flag_spawn(@id, @flag)
		}

		modify_event('message', color('gray').'[PVP] '
			.@pvp['players'][player()]['color'].@e['message'])
		if(array_index_exists(@pvp['players'][player()], 'class')) {
			_class('unload', player(), @pvp['players'][player()]['class'], @pvp)
		}
		array_remove(@pvp['players'], player())
		if(array_index_exists(@pvp['arena'], 'lives') && @pvp['arena']['lives'] > 1) {
			set_pscore('lives', player(), 0, @id)
		}
		dm_set_pvisible(true);
		set_ploc(@pvp['arena']['lobby']);
		_pvp_check_objectives(@id);
	} else if(array_contains(@pvp['spectators'], player())) {
		_remove_spectator(player(), @pvp);
	}
}

array_push(@pvp['binds'], @id.'spawn')
bind(player_spawn, array('id': @id.'spawn'), null, @e, @id) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()),
		die())

	consume();

	if(!array_index_exists(@pvp['arena'], 'respawntime')) {
		queue_push(closure(){
			_pvp_equip(@id, player())
		})
	} else if(array_index_exists(@pvp['arena'], 'classes')) {
		if(@pvp['arena']['class_picking'] === 'random') {
			_class_select_random(player(), @pvp);
		} else if(!array_index_exists(@pvp['arena'], 'class_picks')
		|| (array_index_exists(@pvp['players'][player()], 'picks') && @pvp['players'][player()]['picks'] > 0)) {
			if(array_index_exists(@pvp['players'][player()], 'picks')
			&& @pvp['players'][player()]['picks'] < @pvp['players'][player()]['lives']) {
				msg(color('gold').@pvp['players'][player()]['picks'].' class picks left.');
			}
			if(!array_index_exists(@pvp['players'][player()], 'team') || @pvp['players'][player()]['team'] == 0) {
				if(array_contains(all_virtualchests(), @id.'0')) {
					queue_push(closure(){
						popen_virtualchest(player(), @id.'0')
					})
				}
			} else {
				if(array_contains(all_virtualchests(), @id.'1')) {
					queue_push(closure(){
						popen_virtualchest(player(), @id.'1')
					})
				}
			}
		}

	}

	if(array_index_exists(@pvp['arena'], 'respawntime') && @pvp['running'] == 2) {
		@newLoc = _relative(@pvp['arena']['spawn'][0][0], 'up', 10000000);
		@newLoc['x'] = @newLoc[0];
		@newLoc['y'] = @newLoc[1];
		@newLoc['z'] = @newLoc[2];
		@newLoc['world'] = @newLoc[3];
		@newLoc['pitch'] = 90;
		modify_event('location', @newLoc);

		set_timeout(50, closure(){
			set_pstorm(player(), true);
		});

	} else if(array_index_exists(@pvp, 'team')) {
		@team = @pvp['players'][player()]['team'];
		if(@pvp['arena']['respawnmode'] == 'mob') {
			while(@pvp['team'][@team]['respawns']) {
				@uuid = @pvp['team'][@team]['respawns'][0];
				try {
					@loc = entity_loc(@uuid);
					@loc[1] -= 1;
					modify_event('location', @loc);
					entity_remove(@uuid);
					array_remove(@pvp['team'][@team]['respawns'], 0);
					set_pscore('respawns', @pvp['arena']['team'][@team]['name'], array_size(@pvp['team'][@team]['respawns']), @id);
					die();
				} catch(BadEntityException @ex) {
					// Either the mob is dead or the chunk is unloaded.
					// Remove it just to be sure.
					array_remove(@pvp['team'][@pvp['players'][player()]['team']]['respawns'], 0);
				}
			}
			_remove_player(player(), @pvp);
		} else {
			@r = rand(0, array_size(@pvp['arena']['spawn'][@team]));
			modify_event('location', @pvp['arena']['spawn'][@team][@r]);
		}
	} else {
		@r = rand(0, array_size(@pvp['arena']['spawn'][0]))
		modify_event('location', @pvp['arena']['spawn'][0][@r])
	}

}

# allow use of enderpearls in PVP arenas (overrides main.ms cancel)
array_push(@pvp['binds'], @id.'interactpearls')
bind(player_interact, array('id': @id.'interactpearls', 'priority': 'high'), array('button': 'right', 'item': 368), @e) {
	consume()
}

if(array_index_exists(@pvp['arena'], 'chestspawn')) {
	array_push(@pvp['binds'], @id.'interactchest')
	bind(player_interact, array('id': @id.'interactchest'), array('block': 54), @e, @id) {
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()),
			die())

		for(@i = 0, @i < array_size(@pvp['arena']['chestspawn']), @i++) {
			if(@pvp['arena']['chestspawn'][@i]['loc'][0] == @e['location'][0]
			&& @pvp['arena']['chestspawn'][@i]['loc'][1] == @e['location'][1]
			&& @pvp['arena']['chestspawn'][@i]['loc'][2] == @e['location'][2]
			&& array_index_exists(@pvp['arena']['chestspawn'][@i], 'cooldown')) {
				cancel();
				set_block_at(@e['location'], 0);
				make_effect(@e['location'], 'STEP_SOUND:54');
				@pvp['chestspawn'][@i] = time();
				if(array_index_exists(@pvp, 'stats')) {
					@pvp['stats'][player()]['pickups']++;
				}
				break();
			}
		}
	}
}

if(array_contains(@pvp['arena']['flags'], 'noxp')) {
	array_push(@pvp['binds'], @id.'noxp')
	bind(entity_death, array('id': @id.'noxp'), null, @e, @id) {
		@pvp = import('pvp'.@id)
		if(!_is_survival_world(@e['location']['world'])
		&& array_contains(sk_regions_at(@e['location']), @pvp['arena']['region'])) {
			modify_event('xp', 0)
		}
	}
}

if(array_index_exists(@pvp['arena'], 'mobprotect')) {
	array_push(@pvp['binds'], @id.'mobprotectdeath');
	bind(entity_death, array('id': @id.'mobprotectdeath'), null, @e, @id) {
		@pvp = import('pvp'.@id)
		foreach(@team: @data in @pvp['arena']['mobprotect']) {
			if(@pvp['team'][@team]['mobprotect'] == @e['id']) {
				if(@team == 0) {
					_pvp_end_match(@id, @pvp['team'][1]['players']);
				} else {
					_pvp_end_match(@id, @pvp['team'][0]['players']);
				}
			}
		}
	}

	array_push(@pvp['binds'], @id.'mobprotectdamage');
	bind(entity_damage, array('id': @id.'mobprotectdamage'), null, @e, @id) {
		@pvp = import('pvp'.@id)
		foreach(@team: @data in @pvp['arena']['mobprotect']) {
			if(@pvp['team'][@team]['mobprotect'] == @e['id']) {
				@health = get_entity_health(@e['id'])
				set_pscore('mobhealth', @pvp['arena']['team'][@team]['name'], ceil(@health), @id);
				foreach(@p: @player in @pvp['players']) {
					if(@player['team'] == @team) {
						play_sound(ploc(@p), array('sound': 'NOTE_PLING', 'pitch': 0.5 + (1.5 * (@health / 100))), @p);
					}
				}
			}
		}
	}
}

if(@pvp['arena']['respawnmode'] == 'mob') {
	array_push(@pvp['binds'], @id.'mobrespawns');
	bind(entity_death, array('id': @id.'mobrespawns'), array('type': 'VILLAGER'), @e, @id) {
		@pvp = import('pvp'.@id)
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

array_push(@pvp['binds'], @id.'enderpearl')
bind(player_teleport, array('id': @id.'enderpearl', 'priority': 'highest'), array('type': 'ENDER_PEARL'), @e, @id) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()),
		die())

	if(!array_contains(sk_regions_at(@e['to']), @pvp['arena']['region'])) {
		cancel()
		consume()
	}
}

array_push(@pvp['binds'], @id.'command')
bind(player_command, array('id': @id.'command'), null, @e, @id) {
	@pvp = import('pvp'.@id);
	if(!array_contains(array('/accept', '/warp', '/spawn', '/home', '/join'), @e['prefix'])) {
		die();
	}

	if(array_index_exists(@pvp['players'], player())) {
		set_ploc(@pvp['arena']['lobby']);
		_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
			.@pvp['players'][player()]['color'].player().color('r').' left the arena.');
		if(@pvp['arena']['mode'] === 'ctf'
		&& !is_null(@flag = _flag(pinv(player(), 103)))) {
			_pvp_flag_spawn(@id, @flag);
		}
		if(array_index_exists(@pvp['players'][player()], 'class')) {
			_class('unload', player(), @pvp['players'][player()]['class'], @pvp);
		}
		if(array_index_exists(@pvp['arena'], 'resourcepack')) {
			send_resourcepack(player(), 'http://mc.finalscoremc.com:25966/resourcepacks/default.zip');
		}
		array_remove(@pvp['players'], player());
		if(array_index_exists(@pvp['arena'], 'lives') && @pvp['arena']['lives'] > 1) {
			set_pscore('lives', player(), 0, @id);
		}
		set_pflight(player(), false);
		dm_set_pvisible(player(), true);
		preset_time(player());
		set_pstorm(player(), null);
		_clear_pinv();
		_clear_peffects(player());
		_pvp_check_objectives(@id);

	} else if(array_contains(@pvp['spectators'], player())) {
		_remove_spectator(player(), @pvp);
	}
}

if(!array_contains(@pvp['arena']['flags'], 'build')) {
	array_push(@pvp['binds'], @id.'break')
	bind(block_break, array('id': @id.'break'), null, @e, @id) {
		@pvp = import('pvp'.@id);
		if(array_index_exists(@pvp['players'], player())) {
			cancel();
		}
	}

	array_push(@pvp['binds'], @id.'place')
	bind(block_place, array('id': @id.'place'), null, @e, @id) {
		@pvp = import('pvp'.@id);
		if(array_index_exists(@pvp['players'], player())) {
			cancel();
		}
	}
}

array_push(@pvp['binds'], @id.'EntityDamage')
bind(entity_damage, array('id': @id.'EntityDamage', 'priority': 'LOWEST'), null, @e, @id) {
	@pvp = import('pvp'.@id)
	if(array_index_exists(@e, 'damager')
	&& array_contains(@pvp['spectators'], @e['damager'])) {
		cancel()

	} else if(@e['type'] === 'PLAYER') {
		if(array_index_exists(@pvp['players'], @e['player'])) {
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
				die();
			}

			if(@pvp['arena']['ff'] != 'true'
			&& ((array_index_exists(@pvp['arena'], 'team') && @pvp['players'][@e['player']]['team'] == @pvp['players'][@damager]['team'])
			|| (!array_index_exists(@pvp['arena'], 'team') && @e['player'] == @damager))) {
				@ff = @pvp['arena']['ff'];
				if(@ff == 'knockback') {
					modify_event('amount', 0);
				} else if(@ff == 'reduced') {
					modify_event('amount', @e['amount'] / 2);
				} else {
					cancel();
				}
			} else {
				_stats_damage(@damager, @e['player'], @e['amount'], @pvp);
			}

		} else if(array_contains(@pvp['spectators'], @e['player'])) {
			cancel()
		}
	}
}


if(array_contains(@pvp['arena']['flags'], 'noinventory')) {
	array_push(@pvp['binds'], @id.'noinventory')
	bind(inventory_click, array('id': @id.'noinventory'), null, @e, @id) {
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()),
			die())

		cancel()
	}
}

if(array_contains(@pvp['arena']['flags'], 'rallycall')) {
	array_push(@pvp['binds'], @id.'rallycall')
	bind(player_interact, array('id': @id.'rallycall', 'priority': 'HIGH'), array('item': 401, 'button': 'right'), @e, @id) {
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player())
		|| @e['action'] !== 'right_click_block',
			die())

		consume()
		cancel()
		if(!@loc = _relative(@e['location'], @e['facing']), die())
		@loc = array(@loc[0] + 0.5, @loc[1], @loc[2] + 0.5, @loc[3])
		launch_firework(@loc, array(
			'strength': 3,
			'flicker': true,
			'trail': true,
			'colors': array('RED'),
			'type': 'BURST')
		)
		set_timeout(3000, closure(){
			if(@pvp['players'][player()]['respawn'] == 0) {
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
					.@pvp['players'][player()]['color'].player().color('r').' rallied his crew!')
				foreach(array_keys(@pvp['players']), @p) {
					if(@p != player()
					&& @pvp['players'][player()]['team'] == @pvp['players'][@p]['team']
					&& pinfo(@p, 5) > 0
					&& @pvp['players'][@p]['respawn'] == 0) {
						set_ploc(@p, ploc(player()))
					}
				}
			}
		})
	}
}

if(array_contains(@pvp['arena']['flags'], 'stackedpickup')) {
	array_push(@pvp['binds'], @id.'stackedpickup')
	bind(item_pickup, array('id': @id.'stackedpickup', 'priority': 'LOW'), null, @e, @id) {
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player())
		|| max_stack_size(@e['item']) != 1,
			die())

		foreach(@slot: @item in pinv()) {
			if(!is_null(@item)
			&& @e['item']['type'] == @item['type']
			&& @e['item']['type'] != 373
			&& @e['item']['enchants'] == @item['enchants']) {
				if(@item['data'] > @e['item']['data']) {
					@inv = associative_array();
					@inv[@slot] = @e['item'];
					set_pinv(player(), @inv);
				}
				modify_event('item', null)
				break()
			}
		}
	}
}

if(array_index_exists(@pvp['arena'], 'powerup')) {
	array_push(@pvp['binds'], @id.'powerup')
	bind(item_pickup, array('id': @id.'powerup', 'priority': 'HIGH'), array('item': @pvp['arena']['powerup']), @e, @id) {
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()),
			die())

		modify_event('item', null);
		consume();
		_class('powerup', player(), @pvp['players'][player()]['class'], @pvp);
		if(array_index_exists(@pvp, 'stats')) {
			@pvp['stats'][player()]['pickups']++;
		}
	}
}

if(array_contains(@pvp['arena']['flags'], 'nobottles')) {
	array_push(@pvp['binds'], @id.'nobottles')
	bind(player_consume, array('id': @id.'nobottles'), array('item': 373), @event, @id) {
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()),
			die())

		queue_push(closure(){
			ptake_item(374, 1)
		})
	}
}

if(array_index_exists(@pvp['arena'], 'captain')) {
	array_push(@pvp['binds'], @id.'hatpickup')
	bind(item_pickup, array('id': @id.'hatpickup'), null, @e, @id) {
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()),
			die())

		if(@e['item']['type'] == @pvp['team'][0]['captainhat']['type']) {
			consume()
			if(@pvp['players'][player()]['team'] == 0) {
				modify_event('item', null)
				_class('unload', player(), @pvp['players'][player()]['class'], @pvp)
				_clear_pinv()
				_clear_peffects()
				queue_clear(@id.'0hat')
				@pvp['players'][player()]['class'] = @pvp['arena']['captain'][0]
				@pvp['team'][0]['captain'] = player()
				_class('load', player(), @pvp['players'][player()]['class'], @pvp)
				_class('equip', player(), @pvp['players'][player()]['class'], @pvp)
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
					.@pvp['arena']['team'][0]['color'].player().color('r').' became the new captain!')
				clear_virtualchest(@id.'0', 0)
			} else {
				cancel()
			}

		} else if(@e['item']['type'] == @pvp['team'][1]['captainhat']['type']) {
			consume()
			if(@pvp['players'][player()]['team'] == 1) {
				modify_event('item', null)
				_class('unload', player(), @pvp['players'][player()]['class'], @pvp)
				_clear_pinv()
				_clear_peffects()
				queue_clear(@id.'1hat')
				@pvp['players'][player()]['class'] = @pvp['arena']['captain'][1]
				@pvp['team'][1]['captain'] = player()
				_class('load', player(), @pvp['players'][player()]['class'], @pvp)
				_class('equip', player(), @pvp['players'][player()]['class'], @pvp)
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
					.@pvp['arena']['team'][1]['color'].player().color('r').' became the new captain!')
				clear_virtualchest(@id.'1', 0)
			} else {
				cancel()
			}
		}
	}
}

if(array_index_exists(@pvp['arena'], 'captain')) {
	array_push(@pvp['binds'], @id.'protectdrops')
	bind(entity_damage, array('id': @id.'protectdrops'), array('type': 'DROPPED_ITEM'),
	@e, @region = @pvp['arena']['region']) {
		if(array_contains(sk_regions_at(entity_loc(@e['id'])), @region)) {
			cancel()
		}
	}
}

if(array_contains(@pvp['arena']['flags'], 'infinitedispensers')) {
	array_push(@pvp['binds'], @id.'infinitedispensers')
	bind(projectile_hit, array('id': @id.'infinitedispensers'), array('type': 'ARROW'), @e) {
		if(!_is_survival_world(@e['location']['world']) && is_array(@e['shooter'])) {
			entity_remove(@e['id'])
		}
	}
}

if(array_index_exists(@pvp['arena'], 'blockbreak')) {
	@pvp['blockcheck'] = false;
	@pvp['binds'][] = @id.'blockbreakgoal';
	bind(block_break, array('id': @id.'blockbreakgoal'), null, @event, @id) {
		@pvp = import('pvp'.@id);
		if(!array_index_exists(@pvp['players'], player())) {
			die();
		}
		@pvp['blockcheck'] = true;
	}
	
	@pvp['binds'][] = @id.'blockexplode';
	bind(entity_explode, array('id': @id.'blockexplode'), array('type': 'PRIMED_TNT'), @event, @id) {
		if(_is_survival_world(@event['location']['world'])) {
			die();
		}
		@pvp = import('pvp'.@id);
		if(array_contains(sk_regions_at(@event['location']), @pvp['arena']['region'])) {
			@pvp['blockcheck'] = true;
		}
	}
}

### SPECATORS ###

array_push(@pvp['binds'], @id.'interactspec')
bind(player_interact, array('id': @id.'interactspec', 'priority': 'HIGHEST'), null, @e, @id) {
	@pvp = import('pvp'.@id)
	if(array_contains(@pvp['spectators'], @e['player'])) {
		consume();
		cancel();
	}
}

array_push(@pvp['binds'], @id.'interactentityspec')
bind(player_interact_entity, array('id': @id.'interactentityspec', 'priority': 'HIGHEST'), array('clicked': 'HORSE'), @e, @id) {
	@pvp = import('pvp'.@id)
	if(array_contains(@pvp['spectators'], @e['player'])) {
		consume();
		cancel();
	}
}

array_push(@pvp['binds'], @id.'targetspec')
bind(target_player, array('id': @id.'targetspec', 'priority': 'HIGHEST'), null, @e, @id) {
	@pvp = import('pvp'.@id)
	if(array_contains(@pvp['spectators'], @e['player'])) {
		consume();
		cancel();
	}
}

array_push(@pvp['binds'], @id.'platespec')
bind(pressure_plate_activated, array('id': @id.'platespec', 'priority': 'HIGHEST'), null, @e, @id) {
	@pvp = import('pvp'.@id)
	if(array_contains(@pvp['spectators'], @e['player'])) {
		consume();
		cancel();
	}
}

array_push(@pvp['binds'], @id.'dropspec');
bind(item_drop, array('id': @id.'dropspec', 'priority': 'HIGHEST'), null, @e, @id) {
	@pvp = import('pvp'.@id);
	if(array_contains(@pvp['spectators'], @e['player'])) {
		consume();
		cancel();
	}
}

array_push(@pvp['binds'], @id.'pickupspec', 'priority': 'HIGHEST');
bind(item_pickup, array('id': @id.'pickupspec'), null, @e, @id) {
	@pvp = import('pvp'.@id);
	if(array_contains(@pvp['spectators'], @e['player'])) {
		consume();
		cancel();
	}
}
