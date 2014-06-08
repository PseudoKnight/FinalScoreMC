proc('_pvp_start_match', @id) {
	@pvp = import('pvp'.@id)
	if(array_index_exists(@pvp['arena'], 'rsoutput'), 
		set_block_at(@pvp['arena']['rsoutput'], '69:14'))
	if(array_index_exists(@pvp['arena'], 'time'), 
		set_world_time(@pvp['arena']['lobby'][3], @pvp['arena']['time']))

	if(array_index_exists(@pvp['arena'], 'chestspawn')) {
		@pvp['chestspawn'] = array()
		for(@i = 0, @i < array_size(@pvp['arena']['chestspawn']), @i++) {
			if(array_index_exists(@pvp['arena']['chestspawn'][@i], 'cooldown')) {
				if(@pvp['arena']['chestspawn'][@i]['start'] == 'true') {
					@pvp['chestspawn'][@i] = 0
				} else {
					@pvp['chestspawn'][@i] = time()
					set_block_at(@pvp['arena']['chestspawn'][@i]['loc'], '0:0')
				}
			} else if(array_index_exists(@pvp['arena'], 'chestgroup')) {
				if(get_block_at(@pvp['arena']['chestspawn'][@i]['loc'])[0] == '0', 
					set_block_at(@pvp['arena']['chestspawn'][@i]['loc'], '54:0'))
				@r = rand(array_size(@pvp['arena']['chestgroup'][@pvp['arena']['chestspawn'][@i]['group']]))
				for(@y = 0, @y < 27, @y++) {
					@item = get_inventory_item(@pvp['arena']['chestgroup'][@pvp['arena']['chestspawn'][@i]['group']][@r], @y)
					set_inventory_item(@pvp['arena']['chestspawn'][@i]['loc'], @y, @item)
				}
			}
		}
	}
	
	if(array_index_exists(@pvp['arena'], 'itemspawn')) {
		@pvp['itemspawn'] = array()
		for(@i = 0, @i < array_size(@pvp['arena']['itemspawn']), @i++) {
			if(@pvp['arena']['itemspawn'][@i]['start'] == 'true') {
				@time = 0
			} else {
				@time = time()
			}
			array_set(@pvp['itemspawn'], @i, @time)
		}
	}
	
	if(array_index_exists(@pvp['arena'], 'mobspawn')) {
		@pvp['mobspawn'] = array()
		for(@i = 0, @i < array_size(@pvp['arena']['mobspawn']), @i++) {
			if(@pvp['arena']['mobspawn'][@i]['start']) {
				@time = 0
			} else {
				@time = time()
			}
			array_set(@pvp['mobspawn'], @i, @time)
		}
	}
	
	if(array_index_exists(@pvp['arena'], 'mobprotect')) {
		foreach(@pvp['arena']['mobprotect'], @team, @mob) {
			 @entityid = _spawn_mob(@mob['type'], 1, @mob['loc'])[0]
			 @pvp['team'][@team]['mobprotect'] = entity_uuid(@entityid)
		}
	}
	
	if(array_index_exists(@pvp['arena'], 'timer')) {
		@pvp['starttime'] = time() / 1000
	}
	
	_remove_region_entities(@pvp['arena']['region'], array('DROPPED_ITEM', 'EXPERIENCE_ORB'))
	_pvp_initialize_players(@id, array_keys(@pvp['players']))

	if(array_index_exists(@pvp['arena'], 'captain')) {
		queue_push(closure(){
			@pvp = import('pvp'.@id)
			if(@pvp['team'][0]['captain'] == '') {
				drop_item(_relative(@pvp['arena']['spawn'][0][0], 'up', 2), @pvp['team'][0]['captainhat'], false)
			} else {
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color(@pvp['arena']['team'][0]['color'])
					.@pvp['team'][0]['captain']. ' is the captain of '.@pvp['arena']['team'][0]['name'].'.')
			}
			if(@pvp['team'][1]['captain'] == '') {
				drop_item(_relative(@pvp['arena']['spawn'][1][0], 'up', 2), @pvp['team'][1]['captainhat'], false)
			} else {
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color(@pvp['arena']['team'][1]['color'])
					.@pvp['team'][1]['captain']. ' is the captain of '.@pvp['arena']['team'][1]['name'].'.')
			}
		}, @id)
	}

	if(@pvp['arena']['mode'] == 'ctf') {
		_pvp_flag_spawn(@id, 0)
		_pvp_flag_spawn(@id, 1)
	}

	include('spectator.ms')
	include('events.ms')

	if(array_index_exists(@pvp['arena'], 'weapons')) {
		include('weapons.ms')
	}

	@pvp['interval'] = set_interval(1000, closure(){
		@pvp = import('pvp'.@id)
		@check = false
		if(@pvp['arena']['mode'] == 'koth', 
			@hillcount = 0)
		
		if(array_index_exists(@pvp['arena'], 'timer')) {
			@totalsecsleft = ceil((@pvp['arena']['timer'][1] * 60) - ((time() / 1000) - @pvp['starttime']))
			if(@totalsecsleft < 0) {
				_pvp_end_match(@id, @pvp['team'][@pvp['arena']['timer'][0]]['players'])
				die()
			}
			@minleft = floor(@totalsecsleft / 60)
			@secsleft = mod(@totalsecsleft, 60)
			@timeleft = @minleft.':'.if(@secsleft < 10, '0').@secsleft
			@percentage = round((@totalsecsleft / (@pvp['arena']['timer'][1] * 60)) * 100)
		}

		foreach(array_keys(@pvp['players']), @player) {
			if(array_index_exists(@pvp['arena'], 'timer')) {
				if(phas_bar(@player)) {
					premove_bar(@player)
				}
				set_bar_message(@player, @timeleft, @percentage)
			}
			if(array_index_exists(@pvp['arena'], 'respawntime')
			&& @pvp['players'][@player]['respawn'] != 0) {
				if(!array_contains(sk_current_regions(@player), @pvp['arena']['broadcast'])) {
					if(array_contains(array('ctf', 'tdm', 'infection'), @pvp['arena']['mode'])) {
						_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
							.color(@pvp['arena']['team'][@pvp['players'][@player]['team']]['color']).@player
							.color('r').' left the arena.')
					} else {
						_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
							.color('r').@player.' left the arena.')
					}
					if(array_index_exists(@pvp['players'][@player], 'class')) {
						_class('unload', player(), @pvp['players'][@player]['class'], @pvp)
					}
					if(array_index_exists(@pvp['arena'], 'timer') && phas_bar(@player)) {
						premove_bar(@player)
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
						if(pget_virtualchest(@player), 
							close_pinv(@player))
					}
				}
			} else if(!array_contains(sk_current_regions(@player), @pvp['arena']['region'])
			&& pinfo(@player, 5) > 0) {
				tmsg(@player, color('gray').'[PVP] '.color('r').'You exited the combat region.')
				set_timeout(50, closure(pkill(@player)))
			} else if(@pvp['arena']['mode'] == 'koth' 
			&& array_contains(sk_current_regions(@player), @pvp['arena']['kothregion']) 
			&& pinfo(@player, 5) > 0) { 
				@king = @player
				@hillcount++
			}
			
		}
		
		foreach(@p in @pvp['spectators']) {
			if(!array_contains(sk_current_regions(@p), @pvp['arena']['region'])) {
				_remove_spectator(@id, @p)
			}
		}
		
		if(@pvp['arena']['mode'] == 'koth' && @hillcount == 1) {
			@score = get_pscore('seconds', @king, @id)
			set_pscore('seconds', @king, @score - 1, @id)
			@check = true
		}
		if(array_index_exists(@pvp['arena'], 'itemspawn')) {
			for(@i = 0, @i < array_size(@pvp['arena']['itemspawn']), @i++) {
				if((@pvp['itemspawn'][@i] + (@pvp['arena']['itemspawn'][@i]['cooldown'] * 1000)) < time()) {
					drop_item(@pvp['arena']['itemspawn'][@i]['loc'], array(
						'type': @pvp['arena']['itemspawn'][@i]['item']['type'], 
						'data': @pvp['arena']['itemspawn'][@i]['item']['data'], 
						'qty': @pvp['arena']['itemspawn'][@i]['item']['qty']
						), false)
					@pvp['itemspawn'][@i] = time()
				}
			}
		}
		if(array_index_exists(@pvp['arena'], 'mobspawn')) {
			for(@i = 0, @i < array_size(@pvp['arena']['mobspawn']), @i++) {
				if((@pvp['mobspawn'][@i] + (@pvp['arena']['mobspawn'][@i]['respawn'] * 1000)) < time()) {
					_spawn_mob(@pvp['arena']['mobspawn'][@i]['type'], 
						@pvp['arena']['mobspawn'][@i]['qty'], 
						@pvp['arena']['mobspawn'][@i]['loc'])
					@pvp['mobspawn'][@i] = time()
				}
			}
		}
		if(array_index_exists(@pvp['arena'], 'chestspawn')) {
			for(@i = 0, @i < array_size(@pvp['arena']['chestspawn']), @i++) {
				if(array_index_exists(@pvp['chestspawn'], @i) 
				&& (@pvp['chestspawn'][@i] + (@pvp['arena']['chestspawn'][@i]['cooldown'] * 1000)) < time()) {
					if(get_block_at(@pvp['arena']['chestspawn'][@i]['loc'])[0] == '0') {
						set_block_at(@pvp['arena']['chestspawn'][@i]['loc'], '54:0')
						for(@y = 0, @y < array_size(@pvp['arena']['chestspawn'][@i]['items']), @y++,
							set_inventory_item(@pvp['arena']['chestspawn'][@i]['loc'], @y, @pvp['arena']['chestspawn'][@i]['items'][@y])
						)
						@pvp['chestspawn'][@i] = time()
					}
				}
			}
		}

		export('pvp'.@id, @pvp)
		if(@check, 
			_pvp_check_objectives(@id))
	})
	export('pvp'.@id, @pvp)
	
}

proc('_pvp_initialize_players', @id, @players) {
	@c = array(0, 0) # for selecting initial spawn locations
	foreach(@players, @player) {
		if(!ponline(@player), continue())
		@pvp = import('pvp'.@id)
		if(pmode(@player) == 'CREATIVE', 
			set_pmode(@player, 'SURVIVAL'))
		if(has_permission(@player, 'vanish.standard'), 
			scriptas(@player, run('/v off')))
		set_pscoreboard(@player, @id)
		if(array_contains(array('ctf', 'tdm', 'infection'), @pvp['arena']['mode'])) {
			team_add_player(@pvp['arena']['team'][@pvp['players'][@player]['team']]['name'], @player, @id)
		}
		switch(@pvp['arena']['mode']) {
			case 'koth':
				set_pscore('seconds', @player, @pvp['arena']['score'], @id)
			case 'tdm':
			case 'dm':
				if(array_index_exists(@pvp['arena'], 'lives')) {
					set_pscore('lives', @player, @pvp['arena']['lives'], @id)
				}
		}
		
		if(array_index_exists(@pvp['arena'], 'lives')) {
			@pvp['players'][@player]['lives'] = @pvp['arena']['lives']
		}
		
		if(array_index_exists(@pvp['arena'], 'respawntime')) {
			@pvp['players'][@player]['respawn'] = 0
		}
		
		if(!array_index_exists(@pvp['stats'], @player)) {
			@pvp['stats'][@player] = array('kills': 0, 'damagetaken': array(), 'deaths': 0, 'assists': 0)
		}
		
		queue_push(closure(){
			if(array_index_exists(@pvp, 'team')) {
				set_ploc(@player, @pvp['arena']['spawn'][@pvp['players'][@player]['team']][@c[@pvp['players'][@player]['team']]])
				if(@c[@pvp['players'][@player]['team']] == array_size(@pvp['arena']['spawn'][@pvp['players'][@player]['team']]) - 1) {
					@c[@pvp['players'][@player]['team']] = 0
				} else {
					@c[@pvp['players'][@player]['team']]++
				}
			} else {
				set_ploc(@player, @pvp['arena']['spawn'][0][@c[0]])
				if(@c[0] == array_size(@pvp['arena']['spawn'][0]) - 1) {
					@c[0] = 0
				} else {
					@c[0]++
				}
			}
		}, @id)
		queue_delay(50, @id) # this is to help prevent invisible players
		
		set_pbed_location(@player, @pvp['arena']['lobby'])

		_clear_pinv(@player)
		_clear_peffects(@player)
		if(array_index_exists(@pvp['arena'], 'classes') && !array_index_exists(@pvp['players'][@player], 'class')) {
			@rand = array_rand(@pvp['arena']['classes'], array_size(@pvp['arena']['classes']))
			foreach(@r in @rand) {
				if(!array_index_exists(@pvp['arena']['classes'][@r], 'team')
				|| @pvp['players'][@player]['team'] == @pvp['arena']['classes'][@r]['team']) {
					@pvp['players'][@player]['class'] = @r
					break()
				}
			}
			if(array_index_exists(@pvp['players'][@player], 'class')) {
				_class('load', @player, @pvp['players'][@player]['class'], @pvp)
			}
		}
		
		foreach(@p in @pvp['spectators']) {
			raw_set_pvanish(@p, true, @player)
		}
		
		set_phunger(@player, 20)
		set_psaturation(@player, 5)
		set_phealth(@player, 20)
		_pvp_equip(@id, @player)

		export('pvp'.@id, @pvp)
	}

}

proc('_pvp_equip', @id, @player) {
	@pvp = import('pvp'.@id)
	if(array_index_exists(@pvp['players'][@player], 'inv')) {
		set_pinv(@player, @pvp['players'][@player]['inv'])
	} else {
		if(array_index_exists(@pvp['arena'], 'kit')) {
			if(array_index_exists(@pvp, 'team')) {
				set_pinv(@player, @pvp['arena']['kit'][@pvp['players'][@player]['team']])
			} else {
				set_pinv(@player, @pvp['arena']['kit'][0])
			}
		}
		if(array_index_exists(@pvp['players'][@player], 'class')) {
			_class('equip', @player, @pvp['players'][@player]['class'], @pvp)
		}
	}
	if(array_index_exists(@pvp['arena'], 'effect')) {
		foreach(@pvp['arena']['effect'][0], @effect, @data) {
			set_peffect(@player, @effect, @data['strength'], @data['length'], true)
		}
		if(array_index_exists(@pvp, 'team')) {
			foreach(@pvp['arena']['effect'][@pvp['players'][@player]['team'] + 1], @effect, @data) {
				set_peffect(@player, @effect, @data['strength'], @data['length'], true)
			}
		}
	}
}

proc('_pvp_flag_spawn', @id, @team, @loc) {
	@pvp = import('pvp'.@id)
	if(!@loc, 
		@loc = @pvp['arena']['ctfflag'][@team])
	if(!entity_exists(@pvp['team'][@team]['flag'])) {
		@pvp['team'][@team]['flag'] = drop_item(@loc, array('type': if(@team == 0, '10', '8')), 0)
		export('pvp'.@id, @pvp)
	} else if(_horizontal_distance(entity_loc(@pvp['team'][@team]['flag']), @pvp['arena']['ctfflag'][@team]) > 3) {
		@pvp['team'][@team]['flag'] = drop_item(@loc, array('type': if(@team == 0, '10', '8')), 0)
		export('pvp'.@id, @pvp)
	}
	queue_delay('30000', @id.@team.'flag')
	queue_push(closure(_pvp_flag_spawn(@id, @team)), @id.@team.'flag')
}

proc('_pvp_hat_spawn', @id, @team, @loc) {
	@pvp = import('pvp'.@id)
	@hat = drop_item(@loc, @pvp['team'][@team]['captainhat'])
	set_entity_velocity(@hat, array())
}

proc('_pvp_check_objectives', @id) {
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
		if(@pvp['team'][0]['score'] >= @pvp['arena']['score']) {
			@topteam = 0
		} else {
			@topteam = 1
		}
		_pvp_end_match(@id, @pvp['team'][@topteam]['players'])
		die()
	}

}

proc('_pvp_end_match', @id, @winners) {
	@pvp = import('pvp'.@id)

	foreach(array_keys(@pvp['players']), @player) {
		if(array_index_exists(@pvp['arena'], 'timer') && phas_bar(@player)) {
			premove_bar(@player)
		}
		if(array_contains(@winners, @player)) {
			@leader = @player
			if(ponline(@player) && @pvp['coins'] >= 1) {
				_acc_add(@player, @pvp['coins'])
				tmsg(@player, color('gold').'+ '.@pvp['coins'].if(@pvp['coins'] >= 2, ' coins', ' coin'))
			}
		}
	}

	set_timeout(3000, closure(){
		foreach(array_keys(@pvp['players']), @player) {
			if(array_index_exists(@pvp['players'][@player], 'class')) {
				_class('unload', @player, @pvp['players'][@player]['class'], @pvp)
			}
			if(ponline(@player) && pinfo(@player, 5) > 0) {
				close_pinv(@player)
				set_ploc(@player, @pvp['arena']['lobby'])
				_clear_pinv(@player)
				_clear_peffects(@player)
			}
		}
		if(array_index_exists(@pvp['arena'], 'restore')) {
			set_timeout(7000, closure(){
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
			})
		}
	})

	if(array_contains(array('ctf', 'tdm', 'infection'), @pvp['arena']['mode']) && array_size(@winners) > 0) {
		_worldmsg('custom', color('gray').'[PVP] '
			.color(@pvp['arena']['team'][@pvp['players'][@leader]['team']]['color']).color('bold')
			.@pvp['arena']['team'][@pvp['players'][@leader]['team']]['name'].' win!\n'
			.color(@pvp['arena']['team'][@pvp['players'][@leader]['team']]['color']).array_implode(@winners, ' '))
	} else if(array_size(@winners) > 0) {
		_worldmsg('custom', color('gray').'[PVP] '.color('r').array_implode(@winners, ' and ').' wins!')

	} else {
		_worldmsg('custom', color('gray').'[PVP] '.color('r').'Nobody wins! Wait.. what?!')
	}
	
	if(@pvp['arena']['stats'] == true) {
		_regionmsg(@pvp['arena']['broadcast'], 
			color('gray').'|--'.color('bold').'[ STATS ]'.color('gray').'----------|\n'
			.color('gray').' Kills : Assists : Deaths\n'
			.'|---------------------|')
		foreach(@player: @stats in @pvp['stats']) {
			_regionmsg(@pvp['arena']['broadcast'], ' '.@stats['kills'].' : '.@stats['assists'].' : '.@stats['deaths'].' - '.@player)
		}
		_regionmsg(@pvp['arena']['broadcast'], color('gray').'|---------------------|')
	}
	
	if(array_index_exists(@pvp['arena'], 'chestspawn')) {
		for(@i = 0, @i < array_size(@pvp['arena']['chestspawn']), @i++) {
			if(get_block_at(@pvp['arena']['chestspawn'][@i]['loc']) == '54:0', 
				set_block_at(@pvp['arena']['chestspawn'][@i]['loc'], '0:0'))
		}
	}

	_remove_region_entities(@pvp['arena']['region'])

	if(array_index_exists(@pvp['arena'], 'rsoutput'), 
		set_block_at(@pvp['arena']['rsoutput'], '69:6'))

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
}
