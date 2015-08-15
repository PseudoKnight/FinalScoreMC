# The assign() functions in the event binds are required to keep the instances from interfering with each other
# Just passing the variable (eg. ", @pvp['arena'], @id,") did not work last I tested
array_push(@pvp['binds'], @id.'death')
bind(player_death, array('priority': 'high', 'id': @id.'death'), null, @e, @id = @id) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player())) { 
		die();
	}

	@deathmessage = @e['death_message'];
	@killer = @e['killer'];
	
	if(array_index_exists(@pvp, 'stats')) {
		if(@e['cause']['cause'] == 'CUSTOM'
		&& @pvp['stats'][player()]['damaged'] + 5000 > time()) {
			@killer = @pvp['stats'][player()]['damager'];
			@deathmessage = player().' was doomed by '.@killer;
		}
		
		if(@pvp['stats'][player()]['lastdamager'] != ''
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
	} else if(@pvp['arena']['mode'] == 'infection' && @pvp['players'][player()]['team'] == 0) {
		team_remove_player(@pvp['arena']['team'][@pvp['players'][player()]['team']]['name'], player(), @id)
		array_remove_values(@pvp['team'][0]['players'], player())
		@pvp['players'][player()]['team'] = 1
		@pvp['players'][player()]['color'] = @pvp['arena']['team'][1]['color']
		team_add_player(@pvp['arena']['team'][1]['name'], player(), @id)
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
	}
	set_timeout(5000, closure(){
		try(
			if(pinfo(player(), 5) <= 0) {
				if(function_exists('respawn')) {
					respawn(player())
				}
			}
		)
	})

	if(array_index_exists(@pvp['arena'], 'respawntime')) {
		@pvp['players'][player()]['respawn'] = time() + (@pvp['arena']['respawntime'] * 1000)
	}
	
	if(array_contains(@pvp['arena']['flags'], 'keepinventory')) {
		@pvp['players'][player()]['inv'] = pinv()
	}
	
	@drops = array()
	foreach(@drop in @e['drops']) {
		if(@pvp['arena']['mode'] == 'ctf' && !is_null(@flag = _flag(@drop))) {
			_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.@pvp['players'][player()]['color']
				.player().color('r').' dropped the '.@pvp['arena']['team'][@flag]['color'].'flag')
			if(@e['cause']['cause'] == 'VOID' || @e['cause']['cause'] == 'LAVA') {
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
			
			if(@e['cause']['cause'] == 'VOID' || @e['cause']['cause'] == 'LAVA') {
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
	
	if(array_index_exists(@pvp['arena'], 'lives')) {
		if(@pvp['players'][player()]['lives'] == 0) {
			if(array_index_exists(@pvp['players'][player()], 'class')) {
				_class('unload', player(), @pvp['players'][player()]['class'], @pvp)
			}
			array_remove(@pvp['players'], player());
			
			# Delay spectator mode so that health amount is updated.
			# Health can be above zero when pkill() or set_phealth() are used.
			queue_push(closure(){
				_set_spectator(@id, player(), @pvp);
			});
		}
	}
	
	modify_event('drops', @drops)
	modify_event('xp', null)
	_pvp_check_objectives(@id)
}

array_push(@pvp['binds'], @id.'quit')
bind(player_quit, array('id': @id.'quit', 'priority': 'HIGH'), null, @e, @id = @id) {
	@pvp = import('pvp'.@id)
	if(array_index_exists(@pvp['players'], player())) {
		if(@pvp['arena']['mode'] == 'ctf' 
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
		_pvp_check_objectives(@id)
	} else if(array_contains(@pvp['spectators'], player())) {
		_remove_spectator(@id, player(), @pvp)
	} else {
		die()
	}
	
	array_push(@pvp['binds'], player().'join');
	bind(player_join, array('id': player().'join'), array('player': player()), @e, @id = @id) {
		unbind()
		set_timeout(500, closure(){
			@pvp = import('pvp'.@id)
			if(!is_null(@pvp) && @pvp['running'] && pworld() == 'custom') {
				set_ploc(@pvp['arena']['lobby']);
			}
		});
	}
}

array_push(@pvp['binds'], @id.'spawn')
bind(player_spawn, array('id': @id.'spawn'), null, @e, @id = @id) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()), 
		die())

	consume();

	if(!array_index_exists(@pvp['arena'], 'respawntime')) {
		queue_push(closure(){
			_pvp_equip(@id, player())
		})
	} else if(array_index_exists(@pvp['arena'], 'classes')) {
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

	if(array_index_exists(@pvp['arena'], 'respawntime') && @pvp['running'] == 2) {
		@newLoc = _relative(@e['location'], 'up', 10000000);
		@newLoc['pitch'] = 90;
		modify_event('location', @newLoc);
		
		queue_push(closure(){
			set_pstorm(player(), true);
		}, player());
		
	} else if(array_index_exists(@pvp, 'team')) {
		@r = rand(0, array_size(@pvp['arena']['spawn'][@pvp['players'][player()]['team']]))
		modify_event('location', @pvp['arena']['spawn'][@pvp['players'][player()]['team']][@r])
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
	bind(player_interact, array('id': @id.'interactchest'), array('block': 54), @e, @id = @id) {
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
	bind(entity_death, array('id': @id.'noxp'), null, @e, @id = @id) {
		@pvp = import('pvp'.@id)
		if(@e['location']['world'] == 'custom'
		&& array_contains(sk_regions_at(@e['location']), @pvp['arena']['region'])) {
			modify_event('xp', 0)
		}
	}
}

if(array_index_exists(@pvp['arena'], 'mobprotect')) {
	array_push(@pvp['binds'], @id.'mobprotectdeath');
	bind(entity_death, array('id': @id.'mobprotectdeath'), null, @e, @id = @id) {
		@pvp = import('pvp'.@id)
		foreach(@team: @data in @pvp['arena']['mobprotect']) {
			try(
				if(@pvp['team'][@team]['mobprotect'] == @e['id']) {
					
					if(@team == 0) {
						_pvp_end_match(@id, @pvp['team'][1]['players'])
					} else {
						_pvp_end_match(@id, @pvp['team'][0]['players'])
					}
				}
			);
		}
	}
	
	array_push(@pvp['binds'], @id.'mobprotectdamage');
	bind(entity_damage, array('id': @id.'mobprotectdamage'), null, @e, @id = @id) {
		@pvp = import('pvp'.@id)
		foreach(@team: @data in @pvp['arena']['mobprotect']) {
			try(
				if(@pvp['team'][@team]['mobprotect'] == @e['id']) {
					set_pscore('mobhealth', @pvp['arena']['team'][@team]['name'], ceil(get_entity_health(@e['id'])), @id);
				}
			);
		}
	}
}

array_push(@pvp['binds'], @id.'enderpearl')
bind(player_teleport, array('id': @id.'enderpearl', 'priority': 'highest'), array('type': 'ENDER_PEARL'), @e, @id = @id) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()), 
		die())
		
	if(!array_contains(sk_regions_at(@e['to']), @pvp['arena']['region'])) {
		cancel()
		consume()
	}
}

array_push(@pvp['binds'], @id.'command')
bind(player_command, array('id': @id.'command'), null, @e, @id = @id) {
	@pvp = import('pvp'.@id);
	if(!array_contains(array('/accept', '/warp', '/spawn', '/home', '/join'), @e['prefix'])) {
		die();
	}
	
	if(array_index_exists(@pvp['players'], player())) {
		set_ploc(@pvp['arena']['lobby']);
		_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
			.@pvp['players'][player()]['color'].player().color('r').' left the arena.');
		if(@pvp['arena']['mode'] == 'ctf' 
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
		preset_time(player());
		set_pstorm(player(), null);
		_clear_pinv();
		_clear_peffects(player());
		_pvp_check_objectives(@id);
		
	} else if(array_contains(@pvp['spectators'], player())) {
		_remove_spectator(@id, player(), @pvp);
	}
}

if(!array_contains(@pvp['arena']['flags'], 'build')) {
	array_push(@pvp['binds'], @id.'break')
	bind(block_break, array('id': @id.'break'), null, @e, @id = @id) {
		@pvp = import('pvp'.@id);
		if(array_index_exists(@pvp['players'], player())) {
			cancel();
		}
	}

	array_push(@pvp['binds'], @id.'place')
	bind(block_place, array('id': @id.'place'), null, @e, @id = @id) {
		@pvp = import('pvp'.@id);
		if(array_index_exists(@pvp['players'], player())) {
			cancel();
		}
	}
}

array_push(@pvp['binds'], @id.'EntityDamage')
bind(entity_damage, array('id': @id.'EntityDamage', 'priority': 'LOWEST'), array('world': 'custom'), @e, @id = @id) {
	@pvp = import('pvp'.@id)
	if(array_index_exists(@e, 'damager')
	&& array_contains(@pvp['spectators'], @e['damager'])) {
		cancel()
	
	} else if(@e['type'] == 'PLAYER') {
		if(array_index_exists(@pvp['players'], @e['player'])) {
			@damager = '';
			if(array_index_exists(@e, 'shooter')) {
				if(array_index_exists(@pvp['players'], @e['shooter'])) {
					@damager = @e['shooter'];
				} else {
					try(@damager = get_mob_owner(@e['shooter']));
				}
			} else if(array_index_exists(@e, 'damager')) {
				if(array_index_exists(@pvp['players'], @e['damager'])) {
					@damager = @e['damager'];
				} else {
					try(@damager = get_mob_owner(@e['shooter']));
				}
			}
				
			if(!@pvp['arena']['ff']
			&& array_index_exists(@pvp['players'], @damager)
			&& (!array_index_exists(@pvp['arena'], 'team') 
			|| @pvp['players'][@e['player']]['team'] == @pvp['players'][@damager]['team'])) {
				cancel()
				
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
	bind(inventory_click, array('id': @id.'noinventory'), null, @e, @id = @id) {
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()), 
			die())
			
		cancel()
	}
} else if(@pvp['arena']['mode'] == 'ctf') {
	array_push(@pvp['binds'], @id.'flagclick')
	bind(inventory_click, array('id': @id.'flagclick'), array('slottype': 'ARMOR'), @e, @id = @id) {
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()), die())
		
		if(!is_null(_flag(@e['slotitem']))) { 
			cancel();
		}
	}
}

if(array_contains(@pvp['arena']['flags'], 'rallycall')) {
	array_push(@pvp['binds'], @id.'rallycall')
	bind(player_interact, array('id': @id.'rallycall', 'priority': 'HIGH'), array('item': 401, 'button': 'right'), @e, @id = @id) {
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player())
		|| @e['action'] != 'right_click_block', 
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
	bind(item_pickup, array('id': @id.'stackedpickup', 'priority': 'LOW'), null, @e, @id = @id) { 
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player())
		|| max_stack_size(@e['item']) != 1, 
			die())
			
		foreach(@slot: @item in pinv()) {
			if(!is_null(@item)
			&& @e['item']['type'] == @item['type'] 
			&& @e['item']['type'] != '373' 
			&& @e['item']['enchants'] == @item['enchants']) {
				if(@item['data'] > @e['item']['data']) {
					@inv = array();
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
	bind(item_pickup, array('id': @id.'powerup', 'priority': 'HIGH'), array('item': @pvp['arena']['powerup']), @e, @id = @id) { 
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
	bind(player_consume, array('id': @id.'nobottles'), array('item': 373), @event, @id = @id) {
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()), 
			die())
			
		queue_push(closure(){
			ptake_item(374, 1)
		})
	}
}

if(@pvp['arena']['mode'] == 'ctf') {
	array_push(@pvp['binds'], @id.'flagpickup')
	bind(item_pickup, array('id': @id.'flagpickup'), null, @e, @id = @id) { 
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player())) {
			die();
		}
			
		@flag = _flag(@e['item']);
		if(is_null(@flag)) {
			die();
		}
		
		if(@flag == @pvp['players'][player()]['team']) {
			if(_horizontal_distance(ploc(), @pvp['arena']['ctfflag'][@flag]) > 3) { 
				queue_clear(@id.@flag.'flag');
				modify_event('item', null);
				_pvp_flag_spawn(@id, @flag);
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
					.@pvp['arena']['team'][@flag]['color'].player().color('r').' returned the '
					.@pvp['arena']['team'][@flag]['color'].'flag');
				play_sound(ploc(), array('sound': 'ENDERDRAGON_WINGS', 'pitch': 0));
			} else {
				cancel();
				@heldflag = _flag(pinv(player(), 103));
				if(!is_null(@heldflag)) {
					play_sound(@pvp['arena']['ctfflag'][@flag], array('sound': 'ZOMBIE_METAL', 'volume': 3));
					@pvp['team'][@flag]['score']++;
					set_pscore('captures', @pvp['arena']['team'][@flag]['name'], @pvp['team'][@flag]['score'], @id)
					set_pinv(player(), array(103: null));
					_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
						.@pvp['arena']['team'][@flag]['color'].player().color('r').' secured the '
						.@pvp['arena']['team'][@heldflag]['color'].'flag'.color('r').'!');
					if(array_index_exists(@pvp['arena'], 'rsoutputscore')) {
						set_block_at(@pvp['arena']['rsoutputscore'][@flag], '76:5');
						set_timeout(1000, closure(){
							set_block_at(@pvp['arena']['rsoutputscore'][@flag], '50:5');
						})
					}
					_pvp_flag_spawn(@id, @heldflag);
					_pvp_check_objectives(@id);
				}
			}
		} else {
			queue_clear(@id.@flag.'flag');
			modify_event('item', null);
			set_pinv(player(), array(103: array('type': 425, 'data': if(@flag, 4, 1))));
			_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
				.@pvp['arena']['team'][if(@flag, 0, 1)]['color'].player().color('r').' picked up the '
				.@pvp['arena']['team'][@flag]['color'].'flag');
			play_sound(ploc(), array('sound': 'ENDERDRAGON_WINGS', 'volume': 3));
		}
	}
}


if(array_index_exists(@pvp['arena'], 'captain')) {
	array_push(@pvp['binds'], @id.'hatpickup')
	bind(item_pickup, array('id': @id.'hatpickup'), null, @e, @id = @id) { 
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

if(@pvp['arena']['mode'] == 'ctf' || array_index_exists(@pvp['arena'], 'captain')) {
	array_push(@pvp['binds'], @id.'protectdrops')
	bind(entity_damage, array('id': @id.'protectdrops'), array('type': 'DROPPED_ITEM', 'world': 'custom'), 
	@e, @region = @pvp['arena']['region']) {
		if(array_contains(sk_regions_at(entity_loc(@e['id'])), @region)) {
			cancel()
		}
	}
}

if(array_contains(@pvp['arena']['flags'], 'infinitedispensers')) {
	array_push(@pvp['binds'], @id.'infinitedispensers')
	bind(projectile_hit, array('id': @id.'infinitedispensers'), array('type': 'ARROW'), @e) {
		if(@e['location']['world'] == 'custom' && is_array(@e['shooter'])) {
			entity_remove(@e['id'])
		}
	}
}

if(@pvp[arena][mode] == 'tntrun') {
	array_push(@pvp[binds], @id.'nodrops')
	bind(item_spawn, array(id: @id.'nodrops'), array(item: 70), @e, @region = @pvp[arena][region]) {
		if(array_contains(sk_regions_at(@e[location]), @region)) {
			cancel()
		}
	}
	
	array_push(@pvp[binds], @id.'limitentities')
	bind(entity_change_block, array(id: @id.'limitentities'), array(from: 12), @e, @region = @pvp[arena][region]) {
		if(array_contains(sk_regions_at(@e[location]), @region)) {
			entity_remove(@e[entity])
		}
	}
}

### SPECATORS ###

array_push(@pvp['binds'], @id.'interactspec')
bind(player_interact, array('id': @id.'interactspec'), null, @e, @id = @id) {
	@pvp = import('pvp'.@id)
	if(array_contains(@pvp['spectators'], @e['player'])) {
		cancel()
	}
}

array_push(@pvp['binds'], @id.'interactentityspec')
bind(player_interact_entity, array('id': @id.'interactentityspec'), array('clicked': 'HORSE'), @e, @id = @id) {
	@pvp = import('pvp'.@id)
	if(array_contains(@pvp['spectators'], @e['player'])) {
		cancel()
	}
}

array_push(@pvp['binds'], @id.'targetspec')
bind(target_player, array('id': @id.'targetspec'), null, @e, @id = @id) {
	@pvp = import('pvp'.@id)
	if(array_contains(@pvp['spectators'], @e['player'])) {
		cancel()
	}
}

array_push(@pvp['binds'], @id.'platespec')
bind(pressure_plate_activated, array('id': @id.'platespec'), null, @e, @id = @id) {
	@pvp = import('pvp'.@id)
	if(array_contains(@pvp['spectators'], @e['player'])) {
		cancel()
	}
}

array_push(@pvp['binds'], @id.'dropspec');
bind(item_drop, array('id': @id.'dropspec'), null, @e, @id = @id) {
	@pvp = import('pvp'.@id);
	if(array_contains(@pvp['spectators'], @e['player'])) {
		cancel();
	}
}