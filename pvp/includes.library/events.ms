# The assign() functions in the event binds are required to keep the instances from interfering with each other
# Just passing the variable (eg. ", @pvp['arena'], @id,") did not work last I tested
array_push(@pvp['binds'], @id.'death')
bind(player_death, array('priority': 'high', 'id': @id.'death'), null, @e, @id = @id) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()), 
		die())

	@deathmessage = @e['death_message']
		
	try(
	if(array_index_exists(@pvp['arena'], 'team')) {
		@parts = parse_args(@e['death_message'])
		@parts[0] = @pvp['players'][player()]['color'].player().color('r')
		if(array_index_exists(@pvp['players'], @e['killer'])) {
			for(@i = 1, @i < array_size(@parts), @i++) {
				if(@parts[@i] == @e['killer']) {
					@parts[@i] = @pvp['players'][@e['killer']]['color'].@e['killer'].color('r')
				}
			}
		}
		@deathmessage = array_implode(@parts)
	}
	, @type,
		console(@type.' in '.@e)
	)
	
	@pvp['stats'][player()]['deaths'] += 1
	if(array_index_exists(@pvp['players'], @e['killer'])
	&& @e['killer'] != @e['player']) {
		@pvp['stats'][@e['killer']]['kills'] += 1
	}
	@totaldamage = 0
	foreach(@amount in @pvp['stats'][player()]['damagetaken']) {
		@totaldamage += @amount
	}
	foreach(@damager: @amount in @pvp['stats'][player()]['damagetaken']) {
		if(@damager != @e['killer'] && @damager != 'other'
		&& @amount > @totaldamage / 2) {
			@pvp['stats'][@damager]['assists'] += 1
			if(@e['killer'] && array_index_exists(@pvp['players'], @damager)) {
				@deathmessage .= ', assisted by '.@pvp['players'][@damager]['color'].@damager
			}
		}
	}
	@pvp['stats'][player()]['damagetaken'] = array()
	
	_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color('r').@deathmessage)

	if(array_index_exists(@pvp['arena'], 'lives')) {
		@pvp['players'][player()]['lives'] = @pvp['players'][player()]['lives'] - 1
		if(array_contains(array('tdm', 'dm'), @pvp['arena']['mode'])) {
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
		if(@pvp['arena']['mode'] == 'ctf' && (@drop['type'] == 8 || @drop['type'] == 10)) {
			_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.@pvp['players'][player()]['color']
				.player().color('r').' dropped the '.@pvp['arena']['team'][if(@pvp['players'][player()]['team'] == 0, 1, 0)]['color'].'flag')
			if(@e['cause']['cause'] == 'VOID' || @e['cause']['cause'] == 'LAVA') {
				_pvp_flag_spawn(@id, if(@drop['type'] == 10, 0, 1))
			} else {
				_pvp_flag_spawn(@id, if(@drop['type'] == 10, 0, 1), _relative(ploc(), 'up'))
			}
		} else if(array_index_exists(@pvp['arena'], 'captain') 
		&& @drop['type'] == @pvp['team'][@pvp['players'][player()]['team']]['captainhat']['type']
		&& (max_stack_size(@pvp['team'][@pvp['players'][player()]['team']]['captainhat']['type']) == 1
		|| @drop['data'] == @pvp['team'][@pvp['players'][player()]['team']]['captainhat']['data'])) {
			@pvp['team'][@pvp['players'][player()]['team']]['captain'] = ''
			_class('unload', player(), @pvp['players'][player()]['class'], @pvp)
			foreach(@classname: @class in @pvp['arena']['classes']) {
				if(!array_index_exists(@class, 'team') || @class['team'] == @pvp['players'][player()]['team']) {
					@pvp['players'][player()]['class'] = @classname
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
			if(array_index_exists(@pvp['arena'], 'timer')) {
				if(function_exists('premove_bar')) {
					premove_bar()
				}
			}
			array_remove(@pvp['players'], player())
			_set_spectator(@id, player(), @pvp)
		}
	}
	
	modify_event('drops', @drops)
	modify_event('xp', null)
	_pvp_check_objectives(@id)
}

array_push(@pvp['binds'], @id.'quit')
bind(player_quit, array('id': @id.'quit'), null, @e, @id = @id) {
	@pvp = import('pvp'.@id)
	if(array_index_exists(@pvp['players'], player())) {
		if(@pvp['arena']['mode'] == 'ctf' 
		&& !is_null(pinv(player(), 103))
		&& (pinv(player(), 103)['type'] == 8 
		|| pinv(player(), 103)['type'] == 10)) {
			_pvp_flag_spawn(@id, if(pinv(player(), 103)['type'] == 10, 0, 1)) 
		}

		modify_event('message', color('gray').'[PVP] '
			.@pvp['players'][player()]['color'].@e['message'])
		if(array_index_exists(@pvp['players'][player()], 'class')) {
			_class('unload', player(), @pvp['players'][player()]['class'], @pvp)
		}
		array_remove(@pvp['players'], player())
		if(array_index_exists(@pvp['arena'], 'lives')) {
			set_pscore('lives', player(), 0, @id)
		}
		_pvp_check_objectives(@id)
	} else if(array_contains(@pvp['spectators'], player())) {
		_remove_spectator(@id, player(), @pvp)
	} else {
		die()
	}

	bind(player_join, null, array('player': player()), @e, @id = @id) {
		@pvp = import('pvp'.@id)
		unbind()
		if(@pvp && pworld() == 'custom') {
			_clear_pinv()
			try(set_ploc(@pvp['arena']['lobby']))
		}
	}
}

array_push(@pvp['binds'], @id.'spawn')
bind(player_spawn, array('id': @id.'spawn'), null, @e, @id = @id) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()), 
		die())

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

	if(array_index_exists(@pvp['arena'], 'respawntime')) {
		queue_push(closure(){
			msg(color('gray').'[PVP] '.color('r').'You will respawn in at least '
				.round((@pvp['players'][player()]['respawn'] - time()) / 1000).' seconds.')
		})
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

		@chestloc = array(
			integer(@e['location'][0]), 
			integer(@e['location'][1]), 
			integer(@e['location'][2]), 
			@e['location'][3]
		)
		for(@i = 0, @i < array_size(@pvp['arena']['chestspawn']), @i++) {
			if(@pvp['arena']['chestspawn'][@i]['loc'] == @chestloc
			&& array_index_exists(@pvp['arena']['chestspawn'][@i], 'cooldown')) {
				cancel()
				set_block_at(@e['location'], 0)
				make_effect(@e['location'], 'STEP_SOUND:54')
				@pvp['chestspawn'][@i] = time()
				break()
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
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player())
	|| !array_contains(array('/accept', '/warp', '/spawn', '/home'), @e['prefix']), die())
	_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
		.@pvp['players'][player()]['color'].player().color('r').' left the arena.')
	if(@pvp['arena']['mode'] == 'ctf' 
	&& pinv(player(), 103) 
	&& (pinv(player(), 103)['type'] == 8 
	|| pinv(player(), 103)['type'] == 10)) {
		_pvp_flag_spawn(@id, if(pinv(player(), 103)['type'] == 10, 0, 1))
	}
	if(array_index_exists(@pvp['players'][player()], 'class')) {
		_class('unload', player(), @pvp['players'][player()]['class'], @pvp)
	}
	if(array_index_exists(@pvp['arena'], 'timer')) {
		if(function_exists('premove_bar')) {
			premove_bar()
		}
	}
	array_remove(@pvp['players'], player())
	if(array_index_exists(@pvp['arena'], 'lives')) {
		set_pscore('lives', player(), 0, @id)
	}
	_clear_pinv()
	_clear_peffects(player())
	_pvp_check_objectives(@id)
}

if(!array_contains(@pvp['arena']['flags'], 'build')) {
	array_push(@pvp['binds'], @id.'break')
	bind(block_break, array('id': @id.'break'), null, @e, @id = @id) {
		@pvp = import('pvp'.@id)
		if(array_index_exists(@pvp['players'], player()), 
			cancel())
	}
}

array_push(@pvp['binds'], @id.'EntityDamage')
bind(entity_damage, array('id': @id.'EntityDamage'), array('world': 'custom'), @e, @id = @id) {
	@pvp = import('pvp'.@id)
	if(array_index_exists(@e, 'damager')
	&& array_contains(@pvp['spectators'], @e['damager'])) {
		cancel()
	
	} else if(@e['type'] == 'PLAYER') {
		if(array_index_exists(@pvp['players'], @e['player'])) {
			if(@e['cause'] == 'PROJECTILE') {
				if(array_index_exists(@pvp['players'], @e['shooter'])) {
					@damager = @e['shooter']
				} else {
					@damager = 'other'
				}
			} else if(array_index_exists(@e, 'damager') && array_index_exists(@pvp['players'], @e['damager'])) {
				@damager = @e['damager']
			} else {
				@damager = 'other'
			}
				
			if(!@pvp['arena']['ff']
			&& array_index_exists(@pvp['players'], @damager)
			&& (!array_index_exists(@pvp['arena'], 'team') 
			|| @pvp['players'][@e['player']]['team'] == @pvp['players'][@damager]['team'])) {
				cancel()
				
			} else {
			
				if(array_contains(@pvp['arena']['flags'], 'effects')) {
					play_effect(_relative(ploc(@e['player']), 'up', 2), 'tile_break', array('id': 115, 'particleCount': 20, 'offsetY': 0.3))
				}

				if(array_index_exists(@pvp['stats'][@e['player']]['damagetaken'], @damager)) {
					@pvp['stats'][@e['player']]['damagetaken'][@damager] += @e['amount']
				} else {
					@pvp['stats'][@e['player']]['damagetaken'][@damager] = @e['amount']
				}
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
		
		if(@e['slotitem']['type'] == 10 || @e['slotitem']['type'] == 8, 
			cancel())
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
		if(!array_index_exists(@pvp['players'], player()), 
			die())
			
		foreach(@slot: @item in pinv()) {
			if(!is_null(@item)
			&& @e['item']['type'] == @item['type'] 
			&& @e['item']['type'] != '373' 
			&& @e['item']['enchants'] == @item['enchants']) {
				if(@item['data'] > @e['item']['data']) {
					set_inventory_item(pinfo(player(), 13), @slot, @e['item'])
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
	
		modify_event('item', null)
		consume()
		_class('powerup', player(), @pvp['players'][player()]['class'], @pvp)
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
		if(!array_index_exists(@pvp['players'], player()), 
			die())
		
		if(@e['item']['type'] == '10') {
			consume()
			if(@pvp['players'][player()]['team'] == 0) {
				if(_horizontal_distance(ploc(), @pvp['arena']['ctfflag'][0]) > 3) { 
					queue_clear(@id.'0flag')
					modify_event('item', null)
					_pvp_flag_spawn(@id, 0)
					_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
						.@pvp['arena']['team'][0]['color'].player().color('r').' returned the '
						.@pvp['arena']['team'][0]['color'].'flag')
					play_sound(ploc(), array('sound': 'ENDERDRAGON_WINGS', 'pitch': 0))
				} else {
					cancel()
					if(!is_null(pinv(player(), 103)) && pinv(player(), 103)['type'] == 8) {
						play_sound(@pvp['arena']['ctfflag'][0], array('sound': 'ZOMBIE_METAL', 'volume': 3))
						@pvp['team'][0]['score']++
						set_pscore('captures', @pvp['arena']['team'][0]['name'], @pvp['team'][0]['score'], @id)
						set_pinv(player(), array(103: null))
						_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
							.@pvp['arena']['team'][0]['color'].player().color('r').' secured the '
							.@pvp['arena']['team'][1]['color'].'flag'.color('r').'!')
						if(array_index_exists(@pvp['arena'], 'rsoutputscore')) {
							set_block_at(@pvp['arena']['rsoutputscore'][0], '76:5')
							set_timeout(1000, closure(){
								set_block_at(@pvp['arena']['rsoutputscore'][0], '50:5')
							})
						}
						export('pvp'.@id, @pvp)
						_pvp_flag_spawn(@id, 1)
						_pvp_check_objectives(@id)
					}
				}
			} else {
				queue_clear(@id.'0flag')
				modify_event('item', null)
				set_pinv(player(), array(103: array('type': 10, 'qty': 1)))
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
					.@pvp['arena']['team'][1]['color'].player().color('r').' picked up the '
					.@pvp['arena']['team'][0]['color'].'flag')
				play_sound(ploc(), array('sound': 'ENDERDRAGON_WINGS', 'volume': 3))
			}
		} else if(@e['item']['type'] == '8') {
			consume()
			if(@pvp['players'][player()]['team'] == 1) {
				if(_horizontal_distance(ploc(), @pvp['arena']['ctfflag'][1]) > 3) {
					queue_clear(@id.'1flag')
					modify_event('item', null)
					_pvp_flag_spawn(@id, 1)
					_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
						.@pvp['arena']['team'][1]['color'].player().color('r').' returned the '
						.@pvp['arena']['team'][1]['color'].'flag')
					play_sound(ploc(), array('sound': 'ENDERDRAGON_WINGS', 'pitch': 0))
				} else {
					cancel()
					if(!is_null(pinv(player(), 103)) && pinv(player(), 103)['type'] == 10) {
						set_pinv(player(), array(103: null))
						play_sound(@pvp['arena']['ctfflag'][1], array('sound': 'ZOMBIE_METAL', 'volume': 3))
						@pvp['team'][1]['score']++
						set_pscore('captures', @pvp['arena']['team'][1]['name'], @pvp['team'][1]['score'], @id)
						_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
							.@pvp['arena']['team'][1]['color'].player().color('r').' secured the '
							.@pvp['arena']['team'][0]['color'].'flag'.color('r').'!')
						if(array_index_exists(@pvp['arena'], 'rsoutputscore')) {
							set_block_at(@pvp['arena']['rsoutputscore'][1], '76:5')
							set_timeout(1000, closure(){
								set_block_at(@pvp['arena']['rsoutputscore'][1], '50:5')
							})
						}
						export('pvp'.@id, @pvp)
						_pvp_flag_spawn(@id, 0)
						_pvp_check_objectives(@id)
					}
				}
			} else {
				queue_clear(@id.'1flag')
				modify_event('item', null)
				set_pinv(player(), array(103: array('type': 8, 'qty': 1)))
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
					.@pvp['arena']['team'][0]['color'].player().color('r').' picked up the '
					.@pvp['arena']['team'][1]['color'].'flag')
				play_sound(ploc(), array('sound': 'ENDERDRAGON_WINGS', 'volume': 3))
			}
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
	bind(entity_damage, array('id': @id.'protectdrops'), array('type': 'DROPPED_ITEM', 'cause': 'BLOCK_EXPLOSION', 'world': 'custom'), 
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