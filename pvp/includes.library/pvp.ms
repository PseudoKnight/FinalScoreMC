proc('_pvp_start_round', @id,
	@pvp = import('pvp'.@id)
	if(array_index_exists(@pvp['arena'], 'rsoutput'), set_block_at(@pvp['arena']['rsoutput'], '69:14'))
	if(array_index_exists(@pvp['arena'], 'time'), set_world_time(@pvp['arena']['lobby'][3], @pvp['arena']['time']))

	if(array_index_exists(@pvp['arena'], 'chestspawn')) {
		@pvp['chestspawn'] = array()
		for(@i = 0, @i < array_size(@pvp['arena']['chestspawn']), @i++,
			if(array_index_exists(@pvp['arena']['chestspawn'][@i], 'cooldown')) {
				if(@pvp['arena']['chestspawn'][@i]['start'] == 'true',
					@pvp['chestspawn'][@i] = 0
				, 
					@pvp['chestspawn'][@i] = time()
					set_block_at(@pvp['arena']['chestspawn'][@i]['loc'], '0:0')
				)
			} else if(array_index_exists(@pvp['arena'], 'chestgroup')) {
				if(get_block_at(@pvp['arena']['chestspawn'][@i]['loc']) == '0:0', set_block_at(@pvp['arena']['chestspawn'][@i]['loc'], '54:0'))
				@r = rand(array_size(@pvp['arena']['chestgroup'][@pvp['arena']['chestspawn'][@i]['group']]))
				for(@y = 0, @y < 27, @y++,
					@item = get_inventory_item(@pvp['arena']['chestgroup'][@pvp['arena']['chestspawn'][@i]['group']][@r], @y)
					set_inventory_item(@pvp['arena']['chestspawn'][@i]['loc'], @y, @item)
				)
			}
		)
	}
	
	if(array_index_exists(@pvp['arena'], 'itemspawn')) {
		@pvp['itemspawn'] = array()
		for(@i = 0, @i < array_size(@pvp['arena']['itemspawn']), @i++,
			if(@pvp['arena']['itemspawn'][@i]['start'] == 'true', @time = 0, @time = time())
			array_set(@pvp['itemspawn'], @i, @time)
		)
	}
	
	if(array_index_exists(@pvp['arena'], 'mobspawn')) {
		@pvp['mobspawn'] = array()
		for(@i = 0, @i < array_size(@pvp['arena']['mobspawn']), @i++,
			if(@pvp['arena']['mobspawn'][@i]['start'], @time = 0, @time = time())
			array_set(@pvp['mobspawn'], @i, @time)
		)
	}
	
	if(array_index_exists(@pvp['arena'], 'mobprotect')) {
		foreach(@pvp['arena']['mobprotect'], @team, @mob) {
			@pvp['team'][@team]['mobprotect'] = _spawn_mob(@mob['type'], 1, @mob['loc'])[0]
		}
	}
	
	_remove_region_entities(@pvp['arena']['region'], array('DROPPED_ITEM', 'EXPERIENCE_ORB'))
	_pvp_initialize_players(@id, array_keys(@pvp['players']))

	if(array_index_exists(@pvp['arena'], 'captain')) {
		queue_push(closure(
			@pvp = import('pvp'.@id)
			if(@pvp['team'][0]['captain'] == '') {
				drop_item(_relative(@pvp['arena']['spawn'][0][0], 'up'), @pvp['team'][0]['captainhat'], 0)
			} else {
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color(@pvp['arena']['team'][0]['color']).@pvp['team'][0]['captain']. ' is the captain of '.@pvp['arena']['team'][0]['name'].'.')
			}
			if(@pvp['team'][1]['captain'] == '') {
				@hat = drop_item(_relative(@pvp['arena']['spawn'][1][0], 'up'), @pvp['team'][1]['captainhat'], 0)
			} else {
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color(@pvp['arena']['team'][1]['color']).@pvp['team'][1]['captain']. ' is the captain of '.@pvp['arena']['team'][1]['name'].'.')
			}
			export('pvp'.@id, @pvp)
		), @id)
	}

	if(@pvp['arena']['mode'] == 'ctf') {
		_pvp_flag_spawn(@id, 0)
		_pvp_flag_spawn(@id, 1)
	}

	# The assign() functions in the event binds are required to keep the instances from interfering with each other
	# Just passing the variable (eg. ", @pvp['arena'], @id,") did not work last I tested
	array_push(@pvp['binds'], @id.'death')
	bind('player_death', array('priority': 'high', 'id': @id.'death'), null, @e, assign(@id, @id),
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()), die())
		
		if(array_contains(array('tdm', 'infection'), @pvp['arena']['mode'])) {
			@parts = parse_args(@e['death_message'])
			@parts[0] = color(@pvp['arena']['team'][@pvp['players'][player()]['team']]['color']).player().color('r')
			if(array_index_exists(@pvp['players'], @e['killer'])) {
				for(@i = 1, @i < array_size(@parts), @i++,
					if(@parts[@i] == @e['killer']) {
						@parts[@i] = color(@pvp['arena']['team'][@pvp['players'][@e['killer']]['team']]['color']).@e['killer'].color('r')
					}
				)
			}
			@deathmessage = array_implode(@parts)
		} else {
			@deathmessage = @e['death_message']
		}

		if(array_index_exists(@pvp['arena'], 'lives')) {
			@pvp['players'][player()]['lives'] = @pvp['players'][player()]['lives'] - 1
			if(array_contains(array('tdm', 'dm'), @pvp['arena']['mode'])) {
			  set_pscore('lives', player(), @pvp['players'][player()]['lives'], @id)
			}
		} else if(@pvp['arena']['mode'] == 'infection' && @pvp['players'][player()]['team'] == 0) {
			team_remove_player(@pvp['arena']['team'][@pvp['players'][player()]['team']]['name'], player(), @id)
			array_remove_values(@pvp['team'][0]['players'], player())
			@pvp['players'][player()]['team'] = 1
			team_add_player(@pvp['arena']['team'][1]['name'], player(), @id)
			if(array_index_exists(@pvp['players'][player()], 'class')) {
				_class('unload', player(), @pvp['players'][player()]['class'])
				@pvp['players'][player()]['class'] = @pvp['arena']['classes'][1][0]
				_class('load', player(), @pvp['players'][player()]['class'])
			}
		}
		if(!array_index_exists(@pvp['arena'], 'lives') || @pvp['players'][player()]['lives'] > 0) {
			@pvp['players'][player()]['limbo'] = set_timeout(10000, closure(
				@pvp = import('pvp'.@id)
				if(@pvp['running'] == 'false' || !array_index_exists(@pvp['players'], player()), die())
				if(array_index_exists(@pvp['players'][player()], 'class')) {
					_class('unload', player(), @pvp['players'][player()]['class'])
				}
				array_remove(@pvp['players'], player())
				export('pvp'.@id, @pvp)
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color('r').player().' did not respawn in time.')
				_pvp_check_objectives(@id)
			))
		}

		if(array_index_exists(@pvp['arena'], 'lives')) {
			if(@pvp['players'][player()]['lives'] == 0) {
				if(array_index_exists(@pvp['players'][player()], 'class')) {
					_class('unload', player(), @pvp['players'][player()]['class'])
				}
				array_remove(@pvp['players'], player())
			}
		}
		
		if(array_index_exists(@pvp['arena'], 'respawntime')) {
			@pvp['players'][player()]['respawn'] = time() + (@pvp['arena']['respawntime'] * 1000)
		}
		
		export('pvp'.@id, @pvp)
		
		if(@pvp['arena']['mode'] != 'ctf' && !array_index_exists(@pvp['arena'], 'captain')) {
			_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color('r').@deathmessage)
		}

		@drops = array()
		foreach(@e['drops'], @drop) {
			if(@pvp['arena']['mode'] == 'ctf' && (@drop['type'] == 8 || @drop['type'] == 10)) {
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color(@pvp['arena']['team'][@pvp['players'][player()]['team']]['color']).player().color('r').' dropped the '.color(@pvp['arena']['team'][if(@pvp['players'][player()]['team'] == 0, 1, 0)]['color']).'flag')
				if(@e['cause']['cause'] == 'VOID' || @e['cause']['cause'] == 'LAVA') {
					_pvp_flag_spawn(@id, if(@drop['type'] == 10, 0, 1))
				} else {
					_pvp_flag_spawn(@id, if(@drop['type'] == 10, 0, 1), _relative(ploc(), 'up'))
				}
			} else if(array_index_exists(@pvp['arena'], 'captain') 
			&& @drop['type'] == @pvp['team'][@pvp['players'][player()]['team']]['captainhat']['type']
			&& (max_stack_size(@pvp['team'][@pvp['players'][player()]['team']]['captainhat']['type']) == 1
			|| @drop['data'] == @pvp['team'][@pvp['players'][player()]['team']]['captainhat']['data'])) {
				@pvp = import('pvp'.@id)
				@pvp['team'][@pvp['players'][player()]['team']]['captain'] = ''
				_class('unload', player(), @pvp['players'][player()]['class'])
				@pvp['players'][player()]['class'] = @pvp['arena']['classes'][@pvp['players'][player()]['team']][0]
				_class('load', player(), @pvp['players'][player()]['class'])
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color(@pvp['arena']['team'][@pvp['players'][player()]['team']]['color']).to_upper(@pvp['arena']['team'][@pvp['players'][player()]['team']]['name']).color('r').' - Captain has died and dropped his hat!')
				foreach(@pvp['players'], @p, @player) {
					if(@player['team'] == @pvp['players'][player()]['team']) {
						set_compass_target(@p, ploc())
					}
				}
				
				export('pvp'.@id, @pvp)
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
		
		modify_event('drops', @drops)
		modify_event('xp', null)
		_pvp_check_objectives(@id)
	)

	array_push(@pvp['binds'], @id.'quit')
	bind('player_quit', array('id': @id.'quit'), null, @e, assign(@id, @id), assign(@host, player()),
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()), die())
		if(player() == @host) {
			console('Host ('.@host.') left the match in '.@id.'.')
		}

		if(@pvp['arena']['mode'] == 'ctf' && pinv(player(), 103) != null && (pinv(player(), 103)['type'] == 8 || pinv(player(), 103)['type'] == 10)) {
			_pvp_flag_spawn(@id, if(pinv(player(), 103)['type'] == 10, 0, 1)) 
		}

		modify_event('message', color('gray').'[PVP] '.color(if(array_contains(array('ctf', 'tdm', 'infection'), @pvp['arena']['mode']), @pvp['arena']['team'][@pvp['players'][player()]['team']]['color'], 'white')).@e['message'])
		if(array_index_exists(@pvp['players'][player()], 'class')) {
			_class('unload', player(), @pvp['players'][player()]['class'])
		}
		array_remove(@pvp['players'], player())
		export('pvp'.@id, @pvp)
		_pvp_check_objectives(@id)
		
		bind('player_join', null, array('player': player()), @e, @id,
			@pvp = import('pvp'.@id)
			if(@pvp && @pvp['running'] == 'true' && pworld() == 'custom') {
				set_ploc(@pvp['arena']['lobby'])
				_clear_pinv()
			}
			unbind()
		)
	)

	array_push(@pvp['binds'], @id.'spawn')
	bind('player_spawn', array('id': @id.'spawn'), null, @e, assign(@id, @id),
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()), die())

		if(array_index_exists(@pvp['players'][player()], 'limbo')
		&& @pvp['players'][player()]['limbo']) {
			clear_task(@pvp['players'][player()]['limbo'])
			@pvp['players'][player()]['limbo'] = null
		}
		set_timeout(50, closure( # workaround for bug where players retain potion effects after death
			_clear_peffects(player())
		))
		if(!array_index_exists(@pvp['arena'], 'respawntime')) {
			set_timeout(100, closure(
				_pvp_equip(@id, player())
			))
		} else if(array_index_exists(@pvp['arena'], 'classes')) {
			if(array_index_exists(@pvp, 'team')
			&& array_size(@pvp['arena']['classes'][@pvp['players'][player()]['team']]) > 1) {
				set_timeout(50, closure(
					popen_virtualchest(@id.@pvp['players'][player()]['team'])
				))
			} else if(array_size(@pvp['arena']['classes'][0]) > 1) {
				set_timeout(50, closure(
					popen_virtualchest(@id.'0')
				))
			}
		}

		if(array_index_exists(@pvp['arena'], 'respawntime')) {
			set_timeout(50, closure(msg(color('gray').'[PVP] '.color('r').'You will respawn in at least '.round((@pvp['players'][player()]['respawn'] - time()) / 1000).' seconds.')))
		} else if(array_index_exists(@pvp, 'team')) {
			@r = rand(0, array_size(@pvp['arena']['spawn'][@pvp['players'][player()]['team']]))
			modify_event('location', @pvp['arena']['spawn'][@pvp['players'][player()]['team']][@r])
		} else {
			@r = rand(0, array_size(@pvp['arena']['spawn'][0]))
			# if(!array_index_exists(@arena, 'spawnblock') || get_block_at(@pvp['arena']['spawn'][0][@r]) == @arena['spawnblock'][0]) {
				modify_event('location', @pvp['arena']['spawn'][0][@r])
			# } else {
				# @spawned = false
				# for(@i = 0, @i < array_size(@pvp['arena']['spawn'][0]), @i++,
					# if(get_block_at(@pvp['arena']['spawn'][0][@i]) == @arena['spawnblock'][0]) {
						# modify_event('location', @pvp['arena']['spawn'][0][@i])
						# break()
					# }
				# )
			# }
		}
		

		export('pvp'.@id, @pvp)
	)
	
	# allow use of enderpearls in PVP arenas (overrides main.ms cancel)
	array_push(@pvp['binds'], @id.'interactpearls')
	bind('player_interact', array('id': @id.'interactpearls', 'priority': 'high'), array('button': 'right', 'item': 368), @e,
		consume()
	)

	if(array_index_exists(@pvp['arena'], 'chestspawn')) {
		array_push(@pvp['binds'], @id.'interactchest')
		bind('player_interact', array('id': @id.'interactchest'), array('block': 54), @e, assign(@id, @id),
			@pvp = import('pvp'.@id)
			if(!array_index_exists(@pvp['players'], player()), die())

			@chestloc = array(integer(@e['location'][0]), integer(@e['location'][1]), integer(@e['location'][2]), @e['location'][3])
			for(@i = 0, @i < array_size(@pvp['arena']['chestspawn']), @i++,
				if(@pvp['arena']['chestspawn'][@i]['loc'] == @chestloc
				&& array_index_exists(@pvp['arena']['chestspawn'][@i], 'cooldown')) {
					cancel()
					set_block_at(@e['location'], 0)
					make_effect(@e['location'], 'STEP_SOUND:54')
					@pvp['chestspawn'][@i] = time()
					break()
				}
			)
		)
	}
	
	if(array_index_exists(@pvp['arena'], 'mobspawn')) {
		array_push(@pvp['binds'], @id.'NoMobXP')
		bind('entity_death', array('id': @id.'NoMobXP'), null, @e, assign(@id, @id),
			@pvp = import('pvp'.@id)
			if(array_contains(sk_regions_at(@e['location']), @pvp['arena']['region'])) {
				modify_event('xp', 0)
			}
		)
	}
	
	if(array_index_exists(@pvp['arena'], 'mobprotect')) {
		array_push(@pvp['binds'], @id.'MobDeath')
		bind('entity_death', array('id': @id.'MobDeath'), null, @e, assign(@id, @id),
			@pvp = import('pvp'.@id)
			if(@e['id'] == @pvp['team'][0]['mobprotect']) {
				_pvp_end_match(@id, @pvp['team'][1]['players'])
			} else if(@e['id'] == @pvp['team'][1]['mobprotect']) {
				_pvp_end_match(@id, @pvp['team'][0]['players'])
			}
		)
	}

	array_push(@pvp['binds'], @id.'enderpearl')
	bind('player_teleport', array('id': @id.'enderpearl'), array('type': 'ENDER_PEARL'), @e, assign(@id, @id),
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()), die())
		if(!array_contains(sk_regions_at(@e['to']), @pvp['arena']['region'])) {
			cancel()
		} else if(array_contains(@pvp['arena']['flags'], 'endernades')) {
			explosion(@e['to'], 2)
			cancel()
		}
	)
	
	# if(array_contains(@pvp['arena']['flags'], 'endernades')) {
		# array_push(@pvp['binds'], @id.'endernades')
		# bind('player_interact', array('id': @id.'endernades'), array('item': 368, 'button': 'right'), @e, assign(@id, @id),
			# @pvp = import('pvp'.@id)
			# if(!array_index_exists(@pvp['players'], player()), die())
			# @item = pinv(player(), null)
			# @item['qty'] = @item['qty'] - 1
			# if(@item['qty'] != 0) {
				# @item['type'] = 378
				# set_pinv(array(null: @item))
				# @slot = pinfo(player(), 15)
				# set_timeout(1000, closure(
					# if(pinv(player(), @slot) && pinv(player(), @slot)['type'] == 378) {
						# play_sound(ploc(), array('sound': 'CLICK', 'pitch': 0))
						# @inv = array()
						# @item['type'] = 368
						# @inv[@slot] = @item
						# set_pinv(@inv)
					# }
				# ))
			# }
		# )
	# }
	
	array_push(@pvp['binds'], @id.'command')
	bind('player_command', array('id': @id.'command'), null, @e, assign(@id, @id),
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player())
		|| !array_contains(array('/accept', '/warp', '/spawn', '/home'), @e['prefix']), die())
		if(array_contains(array('ctf', 'tdm', 'infection'), @pvp['arena']['mode'])) {
			_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color(@pvp['arena']['team'][@pvp['players'][player()]['team']]['color']).player().color('r').' left the arena.')
		} else {
			_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color('r').player().' left the arena.')
		}
		if(@pvp['arena']['mode'] == 'ctf' && pinv(player(), 103) && (pinv(player(), 103)['type'] == 8 || pinv(player(), 103)['type'] == 10)) {
			_pvp_flag_spawn(@id, if(pinv(player(), 103)['type'] == 10, 0, 1))
		}
		if(array_index_exists(@pvp['players'][player()], 'class')) {
			_class('unload', player(), @pvp['players'][player()]['class'])
		}
		array_remove(@pvp['players'], player())
		_clear_pinv()
		_clear_peffects(player())
		export('pvp'.@id, @pvp)
		_pvp_check_objectives(@id)
	)
	
	if(@id != 'skypirates' && @id != 'antfarm') {
		array_push(@pvp['binds'], @id.'break')
		bind('block_break', array('id': @id.'break'), null, @e, assign(@id, @id),
			@pvp = import('pvp'.@id)
			if(array_index_exists(@pvp['players'], player()), cancel())
		)
	}

	array_push(@pvp['binds'], @id.'damage')
	bind('entity_damage_player', array('id': @id.'damage'), null, @e, assign(@id, @id),
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()), die())

		if(@e['damager'] == 'PLAYER' || @e['damager'] == 'ARROW' || @e['damager'] == 'WITHER_SKULL' || @e['damager'] == 'SNOWBALL') {
			if(!@pvp['arena']['ff']
				&& array_index_exists(@pvp['players'], @e['data'])
				&& (array_contains(array('dm', 'koth'), @pvp['arena']['mode']) || @pvp['players'][player()]['team'] == @pvp['players'][@e['data']]['team'])) {
					cancel()
			} else if(@e['damager'] == 'WITHER_SKULL') {
				modify_event('amount', @e['amount'] * 6)
				set_timeout(150, closure(set_peffect(player(), 20, 0, 0)))
			}
			if(!array_index_exists(@pvp['players'], @e['data']) && ponline(@e['data'])) {
				set_ploc(@e['data'], @pvp['arena']['lobby'])
			}
		}
	)

	if(array_contains(@pvp['arena']['flags'], 'noinventory')) {
		array_push(@pvp['binds'], @id.'noinventory')
		bind('inventory_click', array('id': @id.'noinventory'), null, @e, assign(@id, @id),
			@pvp = import('pvp'.@id)
			if(!array_index_exists(@pvp['players'], player()), die())
			cancel()
		)
	} else if(@pvp['arena']['mode'] == 'ctf') {
		array_push(@pvp['binds'], @id.'flagclick')
		bind('inventory_click', array('id': @id.'flagclick'), array('slottype': 'ARMOR'), @e, assign(@id, @id),
			@pvp = import('pvp'.@id)
			if(!array_index_exists(@pvp['players'], player()), die())
			
			if(@e['slotitem']['type'] == 10 || @e['slotitem']['type'] == 8, cancel())
		)
	}

	
	if(array_contains(@pvp['arena']['flags'], 'skullrockets')) {
		array_push(@pvp['binds'], @id.'interactskulls')
		bind('player_interact', array('id': @id.'interactskulls'), array('item': 397, 'button': 'right'), @e, assign(@id, @id),
			@pvp = import('pvp'.@id)
			if(!array_index_exists(@pvp['players'], player()), die())
			if(@e['item'] != '397:1', die())

			@skull = shoot_projectile(player(), 'wither_skull')
			ptake_item('397:1', 1)
			cancel()
		)
	}
	
	if(array_contains(@pvp['arena']['flags'], 'primedtnt')) {
		array_push(@pvp['binds'], @id.'primedtnt')
		bind('player_interact', array('id': @id.'primedtnt'), array('item': 46, 'button': 'right'), @e, assign(@id, @id),
			@pvp = import('pvp'.@id)
			if(!array_index_exists(@pvp['players'], player())
			|| @e['action'] != 'right_click_block', die())
			cancel()
			if(@loc = _relative(@e['location'], @e['facing'])) {
				@loc = array(@loc[0] + 0.5, @loc[1] + 0.5, @loc[2] + 0.5, @loc[3])
				ptake_item(46, 1)
				spawn_entity('PRIMED_TNT', 1, @loc)
			}
		)
	}
	
	if(array_contains(@pvp['arena']['flags'], 'shotgunballs')) {
		array_push(@pvp['binds'], @id.'shotgunshoot')
		bind('player_interact', array('id': @id.'shotgunshoot'), array('item': 332, 'button': 'right'), @e, assign(@id, @id),
			@pvp = import('pvp'.@id)
			if(!array_index_exists(@pvp['players'], player()), die())
			cancel()
			@entities = array()
			for(@i = 0, @i < 8, @i++,
				@entities[@i] = shoot_projectile(player(), 'SNOWBALL')
				@v = entity_velocity(@entities[@i])
				set_entity_velocity(@entities[@i], array(@v['x'] * 3.4 + ((rand(3) - 1)), @v['y'] * 3.4 + ((rand(3) - 1)), @v['z'] * 3.4 + ((rand(3) - 1))))
			)
			play_sound(ploc(), array('sound': 'ZOMBIE_WOOD', 'pitch': 1.5, 'volume': 2))
			play_sound(ploc(), array('sound': 'EXPLODE', 'pitch': 2, 'volume': 2))
			@item = pinv(player(), null)
			@item['qty'] = @item['qty'] - 1
			if(@item['qty'] == 0) {
				set_pinv(array(null: null))
			} else {
				@item['type'] = 341
				set_pinv(array(null: @item))
				@slot = pinfo(player(), 15)
				set_timeout(300, closure(
				for(@i = 0, @i < 8, @i++,
					if(entity_exists(@entities[@i]), entity_remove(@entities[@i]))
				)
				set_timeout(600, closure(
					if(pinv(player(), @slot) && pinv(player(), @slot)['type'] == 341) {
						play_sound(ploc(), array('sound': 'PISTON_RETRACT', 'pitch': 1.5))
						@inv = array()
						@item['type'] = 332
						@inv[@slot] = @item
						set_pinv(@inv)
					}
				))
				))
			}
		)
		array_push(@pvp['binds'], @id.'shotgunreload')
		bind('entity_damage', array('id': @id.'shotgunreload'), array('type': 'PLAYER', 'cause': 'PROJECTILE', 'world': 'custom'), @e, assign(@id, @id),
			if(ponline(@e['shooter'])) {
				@pvp = import('pvp'.@id)
				if(array_index_exists(@pvp['players'], @e['shooter'])
				&& pinv(@e['shooter'], null)
				&& pinv(@e['shooter'], null)['type'] == 341) {
					modify_event('amount', 8)
				}
			}
		)
	}
	
	if(array_contains(@pvp['arena']['flags'], 'pistoltears')) {
		array_push(@pvp['binds'], @id.'pistoltears')
		bind('player_interact', array('id': @id.'pistoltears'), array('item': 370, 'button': 'right'), @e, assign(@id, @id),
			@pvp = import('pvp'.@id)
			if(!array_index_exists(@pvp['players'], player()), die())
			@entity = shoot_projectile(player(), 'ARROW')
			@v = entity_velocity(@entity)
			set_entity_velocity(@entity, array(@v['x'] * 3.4, @v['y'] * 3.4, @v['z'] * 3.4))
			play_sound(ploc(), array('sound': 'ZOMBIE_WOOD', 'pitch': 2, 'volume': 2))
			@item = pinv(player(), null)
			@item['qty'] = @item['qty'] - 1
			if(@item['qty'] == 0) {
				set_pinv(array(null: null))
			} else {
				@item['type'] = 371
				set_pinv(array(null: @item))
				@slot = pinfo(player(), 15)
				set_timeout(2000, closure(
					if(pinv(player(), @slot) && pinv(player(), @slot)['type'] == 371) {
						play_sound(ploc(), array('sound': 'DOOR_OPEN', 'pitch': 2))
						@inv = array()
						@item['type'] = 370
						@inv[@slot] = @item
						set_pinv(@inv)
					}
				))
			}
		)
	}
	
	if(array_contains(@pvp['arena']['flags'], 'rallycall')) {
		array_push(@pvp['binds'], @id.'rallycall')
		bind('player_interact', array('id': @id.'rallycall'), array('item': 401, 'button': 'right'), @e, assign(@id, @id),
			@pvp = import('pvp'.@id)
			if(!array_index_exists(@pvp['players'], player())
			|| @e['action'] != 'right_click_block', die())
			cancel()
			if(!@loc = _relative(@e['location'], @e['facing']), die())
			@loc = array(@loc[0] + 0.5, @loc[1], @loc[2] + 0.5, @loc[3])
			launch_firework(@loc, array('strength': 3, 'flicker': true, 'trail': true, 'colors': array('RED'), 'type': 'BURST'))
			set_timeout(3000, closure(
				if(@pvp['players'][player()]['respawn'] == 0) {
					_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color(@pvp['arena']['team'][@pvp['players'][player()]['team']]['color']).player().color('r').' rallied his crew!')
					foreach(array_keys(@pvp['players']), @p) {
						if(@p != player()
						&& @pvp['players'][player()]['team'] == @pvp['players'][@p]['team']
						&& pinfo(@p, 5) > 0
						&& @pvp['players'][@p]['respawn'] == 0) {
							set_ploc(@p, ploc(player()))
						}
					}
				}
			))
		)
	}

	if(array_contains(@pvp['arena']['flags'], 'stackedpickup') || @pvp['arena']['mode'] == 'ctf' || array_index_exists(@pvp['arena'], 'captain')) {
		array_push(@pvp['binds'], @id.'pickup')
		bind('item_pickup', array('id': @id.'pickup'), null, @e, assign(@id, @id), 
			@pvp = import('pvp'.@id)
			if(!array_index_exists(@pvp['players'], player()), die())
			if(@e['item']['type'] == '10') {
				if(@pvp['players'][player()]['team'] == 0) {
					if(_horizontal_distance(ploc(), @pvp['arena']['ctfflag'][0]) > 3) { 
						queue_clear(@id.'0flag')
						modify_event('item', null)
						_pvp_flag_spawn(@id, 0)
						_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color(@pvp['arena']['team'][0]['color']).player().color('r').' returned the '.color(@pvp['arena']['team'][0]['color']).'flag')
						play_sound(ploc(), array('sound': 'ENDERDRAGON_WINGS', 'pitch': 0))
					} else {
						cancel()
						if(pinv(player(), 103) != null && pinv(player(), 103)['type'] == 8) {
							play_sound(@pvp['arena']['ctfflag'][0], array('sound': 'ZOMBIE_METAL', 'volume': 3))
							@pvp['team'][0]['score']++
							set_pscore('captures', to_lower(@pvp['arena']['team'][0]['name']), @pvp['team'][0]['score'], @id)
							set_pinv(player(), array(103: null))
							_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color(@pvp['arena']['team'][0]['color']).player().color('r').' secured the '.color(@pvp['arena']['team'][1]['color']).'flag'.color('r').'!')
							if(array_index_exists(@pvp['arena'], 'rsoutputscore')) {
								set_block_at(@pvp['arena']['rsoutputscore'][0], '76:5')
								set_timeout(1000, closure(
									set_block_at(@pvp['arena']['rsoutputscore'][0], '50:5')
								))
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
					_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color(@pvp['arena']['team'][1]['color']).player().color('r').' picked up the '.color(@pvp['arena']['team'][0]['color']).'flag')
					play_sound(ploc(), array('sound': 'ENDERDRAGON_WINGS', 'volume': 3))
				}
			} else if(@e['item']['type'] == '8') {
				if(@pvp['players'][player()]['team'] == 1) {
					if(_horizontal_distance(ploc(), @pvp['arena']['ctfflag'][1]) > 3) {
						queue_clear(@id.'1flag')
						modify_event('item', null)
						_pvp_flag_spawn(@id, 1)
						_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color(@pvp['arena']['team'][1]['color']).player().color('r').' returned the '.color(@pvp['arena']['team'][1]['color']).'flag')
						play_sound(ploc(), array('sound': 'ENDERDRAGON_WINGS', 'pitch': 0))
					} else {
						cancel()
						if(pinv(player(), 103) != null && pinv(player(), 103)['type'] == 10) {
							set_pinv(player(), array(103: null))
							play_sound(@pvp['arena']['ctfflag'][1], array('sound': 'ZOMBIE_METAL', 'volume': 3))
							@pvp['team'][1]['score']++
							set_pscore('captures', to_lower(@pvp['arena']['team'][1]['name']), @pvp['team'][1]['score'], @id)
							_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color(@pvp['arena']['team'][1]['color']).player().color('r').' secured the '.color(@pvp['arena']['team'][0]['color']).'flag'.color('r').'!')
							if(array_index_exists(@pvp['arena'], 'rsoutputscore')) {
								set_block_at(@pvp['arena']['rsoutputscore'][1], '76:5')
								set_timeout(1000, closure(
									set_block_at(@pvp['arena']['rsoutputscore'][1], '50:5')
								))
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
					_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color(@pvp['arena']['team'][0]['color']).player().color('r').' picked up the '.color(@pvp['arena']['team'][1]['color']).'flag')
					play_sound(ploc(), array('sound': 'ENDERDRAGON_WINGS', 'volume': 3))
				}
			} else if(array_index_exists(@pvp['arena'], 'captain')
			&& @e['item']['type'] == @pvp['team'][0]['captainhat']['type']) {
				if(@pvp['players'][player()]['team'] == 0) {
					modify_event('item', null)
					_class('unload', player(), @pvp['players'][player()]['class'])
					_clear_pinv()
					_clear_peffects()
					queue_clear(@id.'0hat')
					@pvp['players'][player()]['class'] = @pvp['arena']['captain'][0]
					@pvp['team'][0]['captain'] = player()
					_class('load', player(), @pvp['arena']['captain'][0])
					_class('equip', player(), @pvp['arena']['captain'][0])
					_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color(@pvp['arena']['team'][0]['color']).player().color('r').' became the new captain!')
					clear_virtualchest(@id.'0', 0)
				} else {
					cancel()
				}
				
			} else if(array_index_exists(@pvp['arena'], 'captain')
			&& @e['item']['type'] == @pvp['team'][1]['captainhat']['type']) {
				if(@pvp['players'][player()]['team'] == 1) {
					modify_event('item', null)
					_class('unload', player(), @pvp['players'][player()]['class'])
					_clear_pinv()
					_clear_peffects()
					queue_clear(@id.'1hat')
					@pvp['players'][player()]['class'] = @pvp['arena']['captain'][1]
					@pvp['team'][1]['captain'] = player()
					_class('load', player(), @pvp['arena']['captain'][1])
					_class('equip', player(), @pvp['arena']['captain'][1])
					_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color(@pvp['arena']['team'][1]['color']).player().color('r').' became the new captain!')
					clear_virtualchest(@id.'1', 0)
				} else {
					cancel()
				}
			} else if(max_stack_size(@e['item']) == 1) {
				if(array_contains(@pvp['arena']['flags'], 'stackedpickup') && array_index_exists(@pvp['players'], player())) {
					foreach(pinv(), @slot, @item) {
						if(@item != null && @e['item']['type'] == @item['type'] && @e['item']['type'] != '373' && @e['item']['enchants'] == @item['enchants']) {
							if(@item['data'] > @e['item']['data']) {
								set_inventory_item(pinfo()[13], @slot, @e['item'])
							}
							modify_event('item', null)
							break()
						}
					}
				}
			}
		)
	}

	# if(array_contains(array('ctf', 'tdm'), @pvp['arena']['mode'])) {
		# array_push(@pvp['binds'], @id.'tagged')
		# bind('player_tagged', array('id': @id.'tagged'), null, @e, assign(@id, @id), 
			# @pvp = import('pvp'.@id)
			# if(!array_index_exists(@pvp['players'], @e['tagged']), die())
			# modify_event('tag', color(@pvp['arena']['team'][@pvp['players'][@e['tagged']]['team']]['color']).@e['tagged'])
		# )
		# foreach(array_keys(@pvp['players']), @player,
			# tag_refresh(@player)
		# )
	# }

	assign(@pvp['interval'], set_interval(1000, closure(
		@pvp = import('pvp'.@id)
		@check = false
		if(@pvp['arena']['mode'] == 'koth', @hillcount = 0)

		foreach(array_keys(@pvp['players']), @player) {
			if(array_index_exists(@pvp['arena'], 'respawntime')
			&& @pvp['players'][@player]['respawn'] != 0) {
				if(!array_contains(sk_current_regions(@player), @pvp['arena']['broadcast'])) {
					if(array_contains(array('ctf', 'tdm', 'infection'), @pvp['arena']['mode'])) {
						_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color(@pvp['arena']['team'][@pvp['players'][@player]['team']]['color']).@player.color('r').' left the arena.')
					} else {
						_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color('r').@player.' left the arena.')
					}
					if(array_index_exists(@pvp['players'][@player], 'class')) {
						_class('unload', player(), @pvp['players'][@player]['class'])
					}
					array_remove(@pvp['players'], @player)
					_clear_pinv(@player)
					_clear_peffects(@player)
					@check = true
				} else if(@pvp['players'][@player]['respawn'] < time()) {
					if(array_index_exists(@pvp['arena'], 'captain')) {
						if(@pvp['team'][@pvp['players'][@player]['team']]['captain'] != '') {
							set_ploc(@player, ploc(@pvp['team'][@pvp['players'][@player]['team']]['captain']))
							play_sound(ploc(@player), array('sound': 'GHAST_FIREBALL'))
							make_effect(_relative(ploc(@player), 'up'), 'MOBSPAWNER_FLAMES')
							@pvp['players'][@player]['respawn'] = 0
							_pvp_equip(@id, @player)
						}
					} else {
						@r = rand(0, array_size(@pvp['arena']['spawn'][@pvp['players'][player()]['team']]))
						set_ploc(@player, @pvp['arena']['spawn'][@pvp['players'][@player]['team']][@r])
						_pvp_equip(@id, @player)
					}
					if(array_contains(all_virtualchests(), @id.@pvp['players'][@player]['team'])) {
						if(pget_virtualchest(@player), close_pinv(@player))
					}
				}
			} else if(!array_contains(sk_current_regions(@player), @pvp['arena']['region'])
			&& pinfo(@player, 5) > 0) {
				tmsg(@player, color('gray').'[PVP] '.color('r').'You exited the combat region.')
				set_timeout(50, closure(pkill(@player)))
			} else if(@pvp['arena']['mode'] == 'koth' && array_contains(sk_current_regions(@player), @pvp['arena']['kothregion']) && pinfo(@player, 5) > 0) { 
				@king = @player
				@hillcount++
			}
			
		}
		if(@pvp['arena']['mode'] == 'koth' && @hillcount == 1) {
			@score = get_pscore('seconds', @king, @id)
			set_pscore('seconds', @king, @score - 1, @id)
			@check = true
		}
		if(array_index_exists(@pvp['arena'], 'itemspawn')) {
			for(@i = 0, @i < array_size(@pvp['arena']['itemspawn']), @i++,
				if((@pvp['itemspawn'][@i] + (@pvp['arena']['itemspawn'][@i]['cooldown'] * 1000)) < time()) {
					drop_item(@pvp['arena']['itemspawn'][@i]['loc'], array('type': @pvp['arena']['itemspawn'][@i]['item']['type'], 'data': @pvp['arena']['itemspawn'][@i]['item']['data'], 'qty': @pvp['arena']['itemspawn'][@i]['item']['qty']), 0)
					@pvp['itemspawn'][@i] = time()
				}
			) 
		}
		if(array_index_exists(@pvp['arena'], 'mobspawn')) {
			for(@i = 0, @i < array_size(@pvp['arena']['mobspawn']), @i++,
				if((@pvp['mobspawn'][@i] + (@pvp['arena']['mobspawn'][@i]['respawn'] * 1000)) < time()) {
					_spawn_mob(@pvp['arena']['mobspawn'][@i]['type'], @pvp['arena']['mobspawn'][@i]['qty'], @pvp['arena']['mobspawn'][@i]['loc'])
					@pvp['mobspawn'][@i] = time()
				}
			)
		}
		if(array_index_exists(@pvp['arena'], 'chestspawn')) {
			for(@i = 0, @i < array_size(@pvp['arena']['chestspawn']), @i++,
				if(array_index_exists(@pvp['chestspawn'], @i) 
				&& (@pvp['chestspawn'][@i] + (@pvp['arena']['chestspawn'][@i]['cooldown'] * 1000)) < time()) {
					if(get_block_at(@pvp['arena']['chestspawn'][@i]['loc']) == '0:0') {
						set_block_at(@pvp['arena']['chestspawn'][@i]['loc'], '54:0')
						for(@y = 0, @y < array_size(@pvp['arena']['chestspawn'][@i]['items']), @y++,
							set_inventory_item(@pvp['arena']['chestspawn'][@i]['loc'], @y, @pvp['arena']['chestspawn'][@i]['items'][@y])
						)
						@pvp['chestspawn'][@i] = time()
					}
				}
			)
		}

		export('pvp'.@id, @pvp)
		if(@check, _pvp_check_objectives(@id))
	)))
	export('pvp'.@id, @pvp)
	
)

proc('_pvp_initialize_players', @id, @players,
	@c = array(0, 0) # for selecting initial spawn locations
	foreach(@players, @player) {
		if(!ponline(@player), continue())
		@pvp = import('pvp'.@id)
		if(pmode(@player) == 'CREATIVE', set_pmode(@player, 'SURVIVAL'))
		set_pscoreboard(@player, @id)
		if(array_contains(array('ctf', 'tdm', 'infection'), @pvp['arena']['mode'])) {
			team_add_player(@pvp['arena']['team'][@pvp['players'][@player]['team']]['name'], @player, @id)
		}
		switch(@pvp['arena']['mode']
		, 'koth',
			set_pscore('seconds', @player, @pvp['arena']['score'], @id)
		, array('tdm', 'dm'),
			if(array_index_exists(@pvp['arena'], 'lives')) {
				set_pscore('lives', @player, @pvp['arena']['lives'], @id)
			}
		)
		
		if(array_index_exists(@pvp['arena'], 'lives')) {
			@pvp['players'][@player]['lives'] = @pvp['arena']['lives']
		}
		
		if(array_index_exists(@pvp['arena'], 'respawntime')) {
			@pvp['players'][@player]['respawn'] = 0
		}
		
		queue_push(closure(
			if(array_index_exists(@pvp, 'team')) {
				set_ploc(@player, @pvp['arena']['spawn'][@pvp['players'][@player]['team']][@c[@pvp['players'][@player]['team']]])
				if(@c[@pvp['players'][@player]['team']] == array_size(@pvp['arena']['spawn'][@pvp['players'][@player]['team']]) - 1, @c[@pvp['players'][@player]['team']] = 0, @c[@pvp['players'][@player]['team']]++)
			} else {
				set_ploc(@player, @pvp['arena']['spawn'][0][@c[0]])
				if(@c[0] == array_size(@pvp['arena']['spawn'][0]) - 1, @c[0] = 0, @c[0]++)
			}
		), @id)
		queue_delay(50, @id) # this is to help prevent invisible players
		
		set_pbed_location(@player, @pvp['arena']['lobby'])

		_clear_pinv(@player)
		_clear_peffects(@player)
		if(array_index_exists(@pvp['arena'], 'classes') && !array_index_exists(@pvp['players'][@player], 'class')) {
			if(!array_index_exists(@pvp['players'][@player], 'team')) {
				@pvp['players'][@player]['class'] = @pvp['arena']['classes'][0][0]
			} else {
				@pvp['players'][@player]['class'] = @pvp['arena']['classes'][@pvp['players'][@player]['team']][0]
			}
			_class('load', @player, @pvp['players'][@player]['class'])
		}

		_pvp_equip(@id, @player)
		set_phunger(@player, 20)
		set_psaturation(@player, 5)
		set_phealth(@player, 20)

		export('pvp'.@id, @pvp)

	}

)

proc('_pvp_equip', @id, @player,
	@pvp = import('pvp'.@id)
	if(array_index_exists(@pvp['arena'], 'kit')) {
		if(array_index_exists(@pvp, 'team')) {
			set_pinv(@player, @pvp['arena']['kit'][@pvp['players'][@player]['team']])
		} else {
			set_pinv(@player, @pvp['arena']['kit'][0])
		}
	}
	if(array_index_exists(@pvp['arena'], 'effect')) {
		foreach(@pvp['arena']['effect'][0], @effect, @data) {
			set_peffect(@player, @effect, @data['strength'], @data['length'])
		}
		if(array_index_exists(@pvp, 'team')) {
			foreach(@pvp['arena']['effect'][@pvp['players'][@player]['team'] + 1], @effect, @data) {
				set_peffect(@player, @effect, @data['strength'], @data['length'])
			}
		}
	}
	if(array_index_exists(@pvp['players'][@player], 'class')) {
		_class('equip', @player, @pvp['players'][@player]['class'])
	}
	
)

proc('_pvp_flag_spawn', @id, @team, @loc,
	@pvp = import('pvp'.@id)
	if(!@loc, @loc = @pvp['arena']['ctfflag'][@team])
	if(!entity_exists(@pvp['team'][@team]['flag'])) {
		@pvp['team'][@team]['flag'] = drop_item(@loc, array('type': if(@team == 0, '10', '8')), 0)
		export('pvp'.@id, @pvp)
	} else if(_horizontal_distance(entity_loc(@pvp['team'][@team]['flag']), @pvp['arena']['ctfflag'][@team]) > 3) {
		@pvp['team'][@team]['flag'] = drop_item(@loc, array('type': if(@team == 0, '10', '8')), 0)
		export('pvp'.@id, @pvp)
	}
	queue_delay('30000', @id.@team.'flag')
	queue_push(closure(_pvp_flag_spawn(@id, @team)), @id.@team.'flag')
)

proc('_pvp_hat_spawn', @id, @team, @loc,
	@pvp = import('pvp'.@id)
	@hat = drop_item(@loc, @pvp['team'][@team]['captainhat'])
	set_entity_velocity(@hat, array())
	queue_delay('30000', @id.@team.'hat')
	queue_push(closure(
		if(!entity_exists(@hat)) {
			drop_item(@loc, @pvp['team'][@team]['captainhat'], 0)
			_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color(@pvp['arena']['team'][@team]['color']).'Captain\'s hat respawned at dropped location.')
		}
	), @id.@team.'hat')
)

proc('_pvp_check_objectives', @id,
	@pvp = import('pvp'.@id)

	#check total player count
	if(array_size(@pvp['players']) < 1) {
		_pvp_end_match(@id, array())
		die()
	}

	if(array_contains(array('dm', 'koth'), @pvp['arena']['mode']) 
	&& array_size(@pvp['players']) <= 1) {
		_pvp_end_match(@id, array_keys(@pvp['players']))
		die()
	}

	#check team player counts
	if(array_index_exists(@pvp, 'team')) {
		@teamcount = array(0, 0)
		foreach(@pvp['players'], @player) {
			if(!array_index_exists(@pvp['arena'], 'respawntime') || @player['respawn'] == 0) {
				@teamcount[@player['team']]++
				@winner = @player['team']
			}
		}
		if(@teamcount[0] == 0 || @teamcount[1] == 0) {
			_pvp_end_match(@id, @pvp['team'][@winner]['players'])
			die()
		}
	}

	#check ffa player scores
	if(@pvp['arena']['mode'] == 'koth') {
		foreach(@pvp['players'], @player, @data) {
			if(get_pscore('seconds', @player, @id)  <= 0) {
				_pvp_end_match(@id, array(@player))
				die()
			}
		}
	}

	#check team scores
	if(@pvp['arena']['mode'] == 'ctf' 
	&& (@pvp['team'][0]['score'] >= @pvp['arena']['score'] || @pvp['team'][1]['score'] >= @pvp['arena']['score'])) {
		@topteam = if(@pvp['team'][0]['score'] >= @pvp['arena']['score'], 0, 1)
		_pvp_end_match(@id, @pvp['team'][@topteam]['players'])
		die()
	}

)

proc('_pvp_end_match', @id, @winners, 
	@pvp = import('pvp'.@id)

	foreach(array_keys(@pvp['players']), @player) {
		if(array_index_exists(@pvp['players'][@player], 'limbo') && @pvp['players'][@player]['limbo']) {
			clear_task(@pvp['players'][@player]['limbo'])
		}
		if(array_contains(@winners, @player)) {
			@leader = @player
			if(ponline(@player) && @pvp['coins'] >= 1) {
				_acc_add(@player, @pvp['coins'])
				tmsg(@player, color('gold').'+ '.@pvp['coins'].if(@pvp['coins'] >= 2, ' coins', ' coin'))
			}
		}
	}

	set_timeout(3000, closure(
		foreach(array_keys(@pvp['players']), @player) {
			if(array_index_exists(@pvp['players'][@player], 'class')) {
				_class('unload', @player, @pvp['players'][@player]['class'])
			}
			if(ponline(@player) && pinfo(@player, 5) > 0) {
				close_pinv(@player)
				set_ploc(@player, @pvp['arena']['lobby'])
				_clear_pinv(@player)
				_clear_peffects(@player)
			}
		}
		if(array_index_exists(@pvp['arena'], 'restore')) {
			set_timeout(7000, closure(
				foreach(array_keys(@pvp['players']), @player) {
					if(ponline(@player) && pworld(@player) == 'custom') {
						broadcast(color('gray').'[PVP] '.color('r').'RESTORING '.to_upper(@id).'...')
						scriptas(@player,
							foreach(@pvp['arena']['restore'], @region) {
								sudo('//schematic load mce '.@region)
								sudo('//paste -o')
							}
							sudo('/clearclipboard')
							break()
						)
					}
				}
			))
		}
	))

	if(array_contains(array('ctf', 'tdm', 'infection'), @pvp['arena']['mode']) && array_size(@winners) > 0) {
		_worldmsg('custom', color('gray').'[PVP] '.color(@pvp['arena']['team'][@pvp['players'][@leader]['team']]['color']).@pvp['arena']['team'][@pvp['players'][@leader]['team']]['name'].' win!\n'
			.color('gray').'[PVP] '.array_implode(@winners, ' '))
	} else if(array_size(@winners) > 0) {
		_worldmsg('custom', color('gray').'[PVP] '.color('r').array_implode(@winners, ' and ').' wins!')
	} else {
		_worldmsg('custom', color('gray').'[PVP] '.color('r').'Nobody wins! Wait.. what?!')
	}

	_remove_region_entities(@pvp['arena']['region'])

	if(array_index_exists(@pvp['arena'], 'rsoutput'), set_block_at(@pvp['arena']['rsoutput'], '69:6'))

	foreach(@pvp['binds'], @bind) {
		unbind(@bind)
	}

	if(@pvp['arena']['mode'] == 'ctf') {
		queue_clear(@id.'0flag')
		queue_clear(@id.'1flag')
	}

	if(array_index_exists(@pvp['arena'], 'captain')) {
		queue_clear(@id.'0hat')
		queue_clear(@id.'1hat')
	}

	if(array_contains(all_virtualchests(), @id.'0')) {
		del_virtualchest(@id.'0')
	}
	if(array_contains(all_virtualchests(), @id.'1')) {
		del_virtualchest(@id.'1')
	}

	remove_scoreboard(@id)
	clear_task(@pvp['interval'])
	@pvp = array('players': array(), 'running': 'false', 'cooldown': time())
	export('pvp'.@id, @pvp)
)