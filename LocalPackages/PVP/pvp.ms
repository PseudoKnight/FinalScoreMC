proc('_start_round', @id,
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
	
	_remove_region_items(@pvp['arena']['region'])

	@c = array(0, 0) # for selecting initial spawn locations
	foreach(array_keys(@pvp['players']), @player,
		if(!ponline(@player), continue())
		queue_delay(50, @id)
		queue_push(closure(
		@pvp = import('pvp'.@id)
		
		switch(@pvp['arena']['mode']
		, 'koth',
			set_pscore('seconds', @player, @pvp['arena']['score'], @id)
			set_plevel(@player, @pvp['arena']['score'])
		, array('tdm', 'dm'),
			if(array_index_exists(@pvp['arena'], 'lives')) {
				set_pscore('lives', @player, @pvp['arena']['lives'], @id)
			}
		)
		
		if(array_index_exists(@pvp['arena'], 'lives')) {
			@pvp['players'][@player]['lives'] = @pvp['arena']['lives']
			set_plevel(@player, @pvp['arena']['lives'])
		}
		
		if(array_contains(array('tdm', 'ctf', 'infection'), @pvp['arena']['mode'])) {
			set_ploc(@player, @pvp['arena']['spawn'][@pvp['players'][@player]['team']][@c[@pvp['players'][@player]['team']]])
			if(@c[@pvp['players'][@player]['team']] == array_size(@pvp['arena']['spawn'][@pvp['players'][@player]['team']]) - 1, @c[@pvp['players'][@player]['team']] = 0, @c[@pvp['players'][@player]['team']]++)
		} else {
			set_ploc(@player, @pvp['arena']['spawn'][0][@c[0]])
			if(@c[0] == array_size(@pvp['arena']['spawn'][0]) - 1, @c[0] = 0, @c[0]++)
		}
		set_pbed_location(@player, @pvp['arena']['lobby'])

		_clear_pinv(@player)
		if(array_index_exists(@pvp['arena'], 'classes') && !array_index_exists(@pvp['players'][@player], 'class')) {
			if(!array_index_exists(@pvp['players'][@player], 'team')
			|| array_size(@pvp['arena']['classes'][@pvp['players'][@player]['team']]) == 0) {
				@pvp['players'][@player]['class'] = @pvp['arena']['classes'][2][0]
			} else {
				@pvp['players'][@player]['class'] = @pvp['arena']['classes'][@pvp['players'][@player]['team']][0],
			}
		}
		_equip(@id, @player)
		set_phunger(@player, 20)
		set_psaturation(@player, 5)
		set_phealth(@player, 20)
		if(array_index_exists(@pvp['players'][@player], 'class')) {
			_class('load', @player, @pvp['players'][@player]['class'])
		}
		if(array_index_exists(@pvp['arena'], 'effect')) {
			foreach(@pvp['arena']['effect'], @effect, @data,
				set_peffect(@player, @effect, @data['strength'], @data['length'])
			)
		}
		export('pvp'.@id, @pvp)
		), @id)
	)

	if(@pvp['arena']['mode'] == 'ctf') {
		_flag_spawn(@id, 0)
		_flag_spawn(@id, 1)
	}

	# The assign() functions in the event binds are required to keep the instances from interfering with each other
	# Just passing the variable (eg. ", @pvp['arena'], @id,") did not work last I tested
	array_push(@pvp['binds'], @id.'death')
	bind('player_death', array('priority': 'high', 'id': @id.'death'), null, @event, assign(@id, @id),
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()), die())
		
		if(array_contains(array('tdm', 'infection'), @pvp['arena']['mode'])) {
			@parts = parse_args(@event['death_message'])
			@parts[0] = color(@pvp['arena']['team'][@pvp['players'][player()]['team']]['color']).player().color('r')
			for(@i = 1, @i < array_size(@parts), @i++,
				if(@parts[@i] == @event['killer']) {
					@parts[@i] = color(@pvp['arena']['team'][@pvp['players'][@event['killer']]['team']]['color']).@event['killer'].color('r')
				}
			)
			@deathmessage = array_implode(@parts)
		} else {
			@deathmessage = @event['death_message']
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
				_check_objectives(@id)
			))
		}

		if(array_index_exists(@pvp['arena'], 'lives')) {
			if(@pvp['players'][player()]['lives'] == 0) {
				if(array_index_exists(@pvp['players'][player()], 'class')) {
					_class('unload', player(), @pvp['players'][player()]['class'])
				}
				array_remove(@pvp['players'], @player)
			}
		}
		
		if(@pvp['arena']['mode'] != 'ctf') {
			_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color('r').@deathmessage)
		}

		@drops = array()
		foreach(@event['drops'], @drop,
			if(array_index_exists(@pvp['arena'], 'denydrop') && !array_contains(@pvp['arena']['denydrop'], @drop['type']) && !array_contains(array(8, 10), @drop['type'])) {
				array_push(@drops, @drop)
			}
			if(@pvp['arena']['mode'] == 'ctf' && (@drop['type'] == 8 || @drop['type'] == 10)) {
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color(@pvp['arena']['team'][@pvp['players'][player()]['team']]['color']).player().color('r').' dropped the '.color(@pvp['arena']['team'][if(@pvp['players'][player()]['team'] == 0, 1, 0)]['color']).'flag')
				if(@event['cause']['cause'] == 'VOID' || @event['cause']['cause'] == 'LAVA') {
					_flag_spawn(@id, if(@drop['type'] == 10, 0, 1))
				} else {
					_flag_spawn(@id, if(@drop['type'] == 10, 0, 1), array(ploc()[0], ploc()[1] + 1, ploc()[2], ploc()[3]))
				}
			}
		)
		
		export('pvp'.@id, @pvp)
		if(array_index_exists(@pvp['arena'], 'denydrop'), modify_event('drops', @drops))
		modify_event('xp', null)
		_check_objectives(@id)
	)

	array_push(@pvp['binds'], @id.'quit')
	bind('player_quit', array('id': @id.'quit'), null, @event, assign(@id, @id), assign(@host, player()),
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()), die())
		if(player() == @host) {
			console('Host ('.@host.') left the match in '.@id.'.')
		}

		if(@pvp['arena']['mode'] == 'ctf' && pinv(player(), 103) != null && (pinv(player(), 103)['type'] == 8 || pinv(player(), 103)['type'] == 10)) {
			_flag_spawn(@id, if(pinv(player(), 103)['type'] == 10, 0, 1)) 
		}

		modify_event('message', color('gray').'[PVP] '.color(if(array_contains(array('ctf', 'tdm', 'infection'), @pvp['arena']['mode']), @pvp['arena']['team'][@pvp['players'][player()]['team']]['color'], 'white')).@event['message'])
		if(array_index_exists(@pvp['players'][player()], 'class')) {
			_class('unload', player(), @pvp['players'][player()]['class'])
		}
		array_remove(@pvp['players'], @player)
		export('pvp'.@id, @pvp)
		_check_objectives(@id)
		
		bind('player_join', null, array('player': @player), @event, @id,
			@pvp = import('pvp'.@id)
			if(@pvp && @pvp['running'] == 'true' && pworld() == 'custom') {
				set_ploc(@pvp['arena']['lobby'])
				_clear_pinv()
			}
			unbind()
		)
	)

	array_push(@pvp['binds'], @id.'spawn')
	bind('player_spawn', array('id': @id.'spawn'), null, @event, assign(@id, @id),
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()), die())

		clear_task(@pvp['players'][player()]['limbo'])
		@pvp['players'][player()]['limbo'] = null
		_equip(@id, player())

		if(@pvp['arena']['mode'] == 'ctf' && array_index_exists(@pvp['arena'], 'score')) {
			set_plevel(@pvp['team'][@pvp['players'][player()]['team']]['score'])
		} else if(@pvp['arena']['mode'] == 'koth') {
			set_plevel(get_pscore('seconds', player(), @id))
		} else if(array_index_exists(@pvp['arena'], 'lives')) {
			set_plevel(@pvp['players'][player()]['lives'])
		}

		if(array_contains(array('tdm', 'ctf', 'infection'), @pvp['arena']['mode'])) {
			@r = rand(0, array_size(@pvp['arena']['spawn'][@pvp['players'][player()]['team']]))
			modify_event('location', @pvp['arena']['spawn'][@pvp['players'][player()]['team']][@r])
		} else {
			@r = rand(0, array_size(@pvp['arena']['spawn'][0]))
			modify_event('location', array_rand(@pvp['arena']['spawn'][0], 1, false)[0])
		}

		if(array_index_exists(@pvp['arena'], 'effect')) {
			set_timeout(50, closure(
			foreach(@pvp['arena']['effect'], @effect, @data,
				set_peffect(@player, @effect, @data['strength'], @data['length'])
			)
			))
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

			for(@i = 0, @i < array_size(@pvp['arena']['chestspawn']), @i++,
				if(@pvp['arena']['chestspawn'][@i]['loc'] == @e['location']
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

	if(array_contains(@pvp['arena']['flags'], 'skullrockets')) {
		array_push(@pvp['binds'], @id.'interactskulls')
		bind('player_interact', array('id': @id.'interactskulls'), array('item': 397, 'button': 'right'), @e, assign(@id, @id),
			@pvp = import('pvp'.@id)
			if(!array_index_exists(@pvp['players'], player()), die())
			if(@e['item'] != '397:1', die())

			@skull = shoot_projectile(player(), 'wither_skull')
			set_timeout(50, closure(
				@velocity = entity_velocity(@skull)
				set_entity_velocity(@skull, array(@velocity['x'] * 4, @velocity['y'] * 4, @velocity['z'] * 4))
			))
			ptake_item('397:1', 1)
			cancel()
		)
	}
	
	if(array_index_exists(@pvp['arena'], 'mobspawn')) {
		array_push(@pvp['binds'], @id.'entitydrops')
		bind('entity_death', array('id': @id.'entitydrops'), null, @e, assign(@id, @id),
			@pvp = import('pvp'.@id)
			if(array_contains(sk_regions_at(@e['location']), @pvp['arena']['region'])) {
				modify_event('xp', 0)
			}
		)
	}


	array_push(@pvp['binds'], @id.'teleport')
	bind('player_teleport', array('id': @id.'teleport'), null, @event, assign(@id, @id),
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()), die())
		if(@event['type'] == 'ENDER_PEARL') {
			if(!array_contains(sk_regions_at(@event['to']), @pvp['arena']['region'])) {
				cancel()
			} else if(array_contains(@pvp['arena']['flags'], 'endernades')) {
				explosion(@event['to'], 2)
				cancel()
			}
		} else if(!array_contains(sk_regions_at(@event['to']), @pvp['arena']['region'])) {
			if(array_contains(array('ctf', 'tdm', 'infection'), @pvp['arena']['mode'])) {
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color(@pvp['arena']['team'][@pvp['players'][player()]['team']]['color']).player().color('r').' left the arena.')
			} else {
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color('r').player().' left the arena.')
			}
			if(@pvp['arena']['mode'] == 'ctf' && pinv(player(), 103) != null && (pinv(player(), 103)['type'] == 8 || pinv(player(), 103)['type'] == 10)) {
				_flag_spawn(@id, if(pinv(player(), 103)['type'] == 10, 0, 1))
			}
			if(array_index_exists(@pvp['players'][player()], 'class')) {
				_class('unload', player(), @pvp['players'][player()]['class'])
			}
			array_remove(@pvp['players'], player())
			_remove_peffects(player())
			export('pvp'.@id, @pvp)
			_check_objectives(@id)
		}
	)
	
	array_push(@pvp['binds'], @id.'break')
	bind('block_break', array('id': @id.'break'), null, @event, assign(@id, @id),
		@pvp = import('pvp'.@id)
		if(array_index_exists(@pvp['players'], player()) && @id != 'skypirates', cancel())
	)

	array_push(@pvp['binds'], @id.'damage')
	bind('entity_damage_player', array('id': @id.'damage'), null, @event, assign(@id, @id),
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()), die())

		if(@event['damager'] == 'PLAYER' || @event['damager'] == 'ARROW' || @event['damager'] == 'WITHER_SKULL') {
			if(!@pvp['arena']['ff']
				&& array_index_exists(@pvp['players'], @event['data'])
				&& (array_contains(array('dm', 'koth'), @pvp['arena']['mode']) || @pvp['players'][player()]['team'] == @pvp['players'][@event['data']]['team'])) {
					cancel()
			} else if(@event['damager'] == 'WITHER_SKULL') {
				modify_event('amount', @event['amount'] * 6)
				set_timeout(150, closure(set_peffect(player(), 20, 0, 0)))
			}
			if(!array_index_exists(@pvp['players'], @event['data']) && ponline(@event['data'])) {
				set_ploc(@event['data'], @pvp['arena']['lobby'])
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
		bind('inventory_click', array('id': @id.'flagclick'), array('slottype': 'ARMOR'), @event, assign(@id, @id),
			@pvp = import('pvp'.@id)
			if(!array_index_exists(@pvp['players'], player()), die())
			
			if(@event['slotitem']['type'] == 10 || @event['slotitem']['type'] == 8, cancel())
		)
	}
	


	if(array_contains(@pvp['arena']['flags'], 'stackedpickup') || @pvp['arena']['mode'] == 'ctf') {
		array_push(@pvp['binds'], @id.'pickup')
		bind('item_pickup', array('id': @id.'pickup'), null, @event, assign(@id, @id), 

			if(@event['item']['type'] == '10') {
				@pvp = import('pvp'.@id)
				if(@pvp['players'][player()]['team'] == 0) {
					if(_horizontal_distance(ploc(), @pvp['arena']['ctfflag'][0]) > 3) { 
						queue_clear(@id.'0flag')
						modify_event('item', null)
						_flag_spawn(@id, 0)
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
							foreach(array_keys(@pvp['players']), @player,
								if(@pvp['players'][@player]['team'] == 0) {
									set_plevel(@player, @pvp['team'][0]['score'])
								}
							)
							if(array_index_exists(@pvp['arena'], 'rsoutputscore')) {
								set_block_at(@pvp['arena']['rsoutputscore'][0], '76:5')
								set_timeout(1000, closure(
									set_block_at(@pvp['arena']['rsoutputscore'][0], '50:5')
								))
							}
							export('pvp'.@id, @pvp)
							_flag_spawn(@id, 1)
							_check_objectives(@id)
						}
					}
				} else {
					queue_clear(@id.'0flag')
					modify_event('item', null)
					set_pinv(player(), array(103: array('type': 10, 'qty': 1)))
					_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color(@pvp['arena']['team'][1]['color']).player().color('r').' picked up the '.color(@pvp['arena']['team'][0]['color']).'flag')
					play_sound(ploc(), array('sound': 'ENDERDRAGON_WINGS', 'volume': 3))
				}
			} else if(@event['item']['type'] == '8') {
				@pvp = import('pvp'.@id)
				if(@pvp['players'][player()]['team'] == 1) {
					if(_horizontal_distance(ploc(), @pvp['arena']['ctfflag'][1]) > 3) {
						queue_clear(@id.'1flag')
						modify_event('item', null)
						_flag_spawn(@id, 1)
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
							foreach(array_keys(@pvp['players']), @player,
								if(@pvp['players'][@player]['team'] == 1) {
									set_plevel(@player, @pvp['team'][1]['score'])
								}
							)
							if(array_index_exists(@pvp['arena'], 'rsoutputscore')) {
								set_block_at(@pvp['arena']['rsoutputscore'][1], '76:5')
								set_timeout(1000, closure(
									set_block_at(@pvp['arena']['rsoutputscore'][1], '50:5')
								))
							}
							export('pvp'.@id, @pvp)
							_flag_spawn(@id, 0)
							_check_objectives(@id)
						}
					}
				} else {
					queue_clear(@id.'1flag')
					modify_event('item', null)
					set_pinv(player(), array(103: array('type': 8, 'qty': 1)))
					_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color(@pvp['arena']['team'][0]['color']).player().color('r').' picked up the '.color(@pvp['arena']['team'][1]['color']).'flag')
					play_sound(ploc(), array('sound': 'ENDERDRAGON_WINGS', 'volume': 3))
				}

			} else if(max_stack_size(@event['item']) == 1) {
				@pvp = import('pvp'.@id)
				if(array_contains(@pvp['arena']['flags'], 'stackedpickup') && array_index_exists(@pvp['players'], player())) {
					foreach(pinv(), @slot, @item,
						if(@item != null && @event['item']['type'] == @item['type'] && @event['item']['type'] != '373' && @event['item']['enchants'] == @item['enchants']) {
							if(@item['data'] > @event['item']['data']) {
								set_inventory_item(pinfo()[13], @slot, @event['item'])
							}
							modify_event('item', null)
							break()
						}
					)
				}
			}

		)
	}

	# if(array_contains(array('ctf', 'tdm'), @pvp['arena']['mode'])) {
		# array_push(@pvp['binds'], @id.'tagged')
		# bind('player_tagged', array('id': @id.'tagged'), null, @event, assign(@id, @id), 
			# @pvp = import('pvp'.@id)
			# if(!array_index_exists(@pvp['players'], @event['tagged']), die())
			# modify_event('tag', color(@pvp['arena']['team'][@pvp['players'][@event['tagged']]['team']]['color']).@event['tagged'])
		# )
		# foreach(array_keys(@pvp['players']), @player,
			# tag_refresh(@player)
		# )
	# }

	assign(@pvp['interval'], set_interval(1000, closure(
		@pvp = import('pvp'.@id)
		@check = false
		if(@pvp['arena']['mode'] == 'koth', @hillcount = 0)

		foreach(array_keys(@pvp['players']), @player,
			if(!array_contains(sk_current_regions(@player), @pvp['arena']['region'])
			&& pinfo(@player, 5) > 0) {
				pkill(@player)
			}

			if(@pvp['arena']['mode'] == 'koth' && array_contains(sk_current_regions(@player), @pvp['arena']['kothregion']) && pinfo(@player, 5) > 0) { 
				@king = @player
				@hillcount++
			}
		)
		if(@pvp['arena']['mode'] == 'koth' && @hillcount == 1) {
			@score = get_pscore('seconds', @king, @id)
			set_pscore('seconds', @king, @score - 1, @id)
			set_plevel(@king, @score - 1)
			@check = true
		}
		if(array_index_exists(@pvp['arena'], 'itemspawn')) {
			for(@i = 0, @i < array_size(@pvp['arena']['itemspawn']), @i++,
				if((@pvp['itemspawn'][@i] + (@pvp['arena']['itemspawn'][@i]['cooldown'] * 1000)) < time()) {
					@item = drop_item(@pvp['arena']['itemspawn'][@i]['loc'], array('type': @pvp['arena']['itemspawn'][@i]['item']['type'], 'data': @pvp['arena']['itemspawn'][@i]['item']['data'], 'qty': @pvp['arena']['itemspawn'][@i]['item']['qty']))
					set_entity_velocity(@item, array())
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

		if(array_index_exists(@pvp['arena'], 'rsinputwin')) {
			foreach(@pvp['arena']['rsinputwin'], @team, @torch,
				if(get_block_at(@torch) == '75:5') {
					_end_match(@id, @pvp['team'][@team]['players'])
					die()
				}
			)
		}

		export('pvp'.@id, @pvp)
		if(@check, _check_objectives(@id))
	)))
	export('pvp'.@id, @pvp)
)

# proc('_class_select', @id, @player,
	# @pvp = import('pvp'.@id)
	# @classnames = @pvp['arena']['classes'][@pvp['players'][@player]['team']]
	# foreach(@classnames, @classname,
		# @class[@classname] = get_value('class.'.@classname)
	# )
# )

proc('_equip', @id, @player,
	@pvp = import('pvp'.@id)
	if(array_index_exists(@pvp['arena'], 'kit')) {
		if(array_contains(array('tdm', 'ctf', 'infection'), @pvp['arena']['mode'])) {
			set_pinv(@player, @pvp['arena']['kit'][@pvp['players'][@player]['team']])
		} else {
			set_pinv(@player, @pvp['arena']['kit'][0])
		}
	}
	if(array_index_exists(@pvp['players'][@player], 'class')) {
		_class('equip', @player, @pvp['players'][@player]['class'])
	}
)

proc('_flag_spawn', @id, @team, @loc,
	@pvp = import('pvp'.@id)
	if(!@loc, @loc = @pvp['arena']['ctfflag'][@team])
	if(!entity_type(@pvp['team'][@team]['flag'])) {
		@pvp['team'][@team]['flag'] = drop_item(@loc, array('type': if(@team == 0, '10', '8')))
		set_entity_velocity(@pvp['team'][@team]['flag'], array())
		export('pvp'.@id, @pvp)
	} else if(_horizontal_distance(entity_loc(@pvp['team'][@team]['flag']), @pvp['arena']['ctfflag'][@team]) > 3) {
		@pvp['team'][@team]['flag'] = drop_item(@loc, array('type': if(@team == 0, '10', '8')))
		set_entity_velocity(@pvp['team'][@team]['flag'], array())
		export('pvp'.@id, @pvp)
	}
	queue_delay('30000', @id.@team.'flag')
	queue_push(closure(_flag_spawn()), @id.@team.'flag')
)

proc('_check_objectives', @id,
	@pvp = import('pvp'.@id)

	#check total player count
	if(array_size(@pvp['players']) < 1) {
		_end_match(@id, array())
		die()
	}

	if(array_contains(array('dm', 'koth'), @pvp['arena']['mode']) 
	&& array_size(@pvp['players']) <= 1) {
		_end_match(@id, array_keys(@pvp['players']))
		die()
	}

	#check team player counts
	if(array_contains(array('tdm', 'ctf', 'infection'), @pvp['arena']['mode'])) {
		@teamcount = array(0, 0)
		foreach(@pvp['players'], @player,
			@teamcount[@player['team']]++
		)
		if(@teamcount[0] == 0 || @teamcount[1] == 0) {
			_end_match(@id, @pvp['team'][@pvp['players'][array_keys(@pvp['players'])[0]]['team']]['players'])
			die()
		}
	}

	#check ffa player scores
	if(@pvp['arena']['mode'] == 'koth') {
		foreach(@pvp['players'], @player, @data,
			if(get_pscore('seconds', @player, @id)  <= 0) {
				_end_match(@id, array(@player))
				die()
			}
		)
	}

	#check team scores
	if(@pvp['arena']['mode'] == 'ctf' 
	&& (@pvp['team'][0]['score'] >= @pvp['arena']['score'] || @pvp['team'][1]['score'] >= @pvp['arena']['score'])) {
		@topteam = if(@pvp['team'][0]['score'] >= @pvp['arena']['score'], 0, 1)
		_end_match(@id, @pvp['team'][@topteam]['players'])
		die()
	}

)

proc('_end_match', @id, @winners, 
	@pvp = import('pvp'.@id)

	foreach(array_keys(@pvp['players']), @player,
		if(array_index_exists(@pvp['players'][@player], 'limbo') && @pvp['players'][@player]['limbo'], clear_task(@pvp['players'][@player]['limbo']))
		set_timeout(3000, closure(
			if(array_index_exists(@pvp['players'][@player], 'class')) {
				_class('unload', @player, @pvp['players'][@player]['class'])
			}
			if(ponline(@player)) {
				close_pinv(@player)
				set_ploc(@player, @pvp['arena']['lobby'])
				_clear_pinv(@player)
				_remove_peffects(@player)
			}
		))
		if(array_contains(@winners, @player), @leader = @player)
	)

	foreach(@winners, @player,
		if(ponline(@player) && @pvp['coins'] >= 1) {
			_acc_add(@player, @pvp['coins'])
			tmsg(@player, color('gold').'+ '.@pvp['coins'].if(@pvp['coins'] >= 2, ' coins', ' coin'))
		}
	)

	if(array_contains(array('ctf', 'tdm', 'infection'), @pvp['arena']['mode']) && array_size(@winners) > 0) {
		_worldmsg('custom', color('gray').'[PVP] '.color(@pvp['arena']['team'][@pvp['players'][@leader]['team']]['color']).@pvp['arena']['team'][@pvp['players'][@leader]['team']]['name'].' win!\n'
			.color('gray').'[PVP] '.array_implode(@winners, ' '))
	} else if(array_size(@winners) > 0) {
		_worldmsg('custom', color('gray').'[PVP] '.color('r').array_implode(@winners, ' and ').' wins!')
	} else {
		_worldmsg('custom', color('gray').'[PVP] '.color('r').'Nobody wins! Wait.. what?!')
	}

	if(array_index_exists(@pvp['arena'], 'restore')) {
		set_timeout(10000, closure(
			runas('~console', '/prs restore '.@pvp['arena']['restore'])
		))
	}
	if(array_index_exists(@pvp['arena'], 'rsoutput'), set_block_at(@pvp['arena']['rsoutput'], '69:6'))

	foreach(@pvp['binds'], @bind,
		unbind(@bind)
	)

	if(@pvp['arena']['mode'] == 'ctf') {
		queue_clear(@id.'0flag')
		queue_clear(@id.'1flag')
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