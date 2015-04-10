include('class.ms');
include('spectator.ms');
include('player.ms');
include('stats.ms');

proc _pvp_start_match(@id) {
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
			array_set(@pvp['itemspawn'], @i, array(0, @time))
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
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.@pvp['arena']['team'][0]['color']
					.@pvp['team'][0]['captain']. ' is the captain of '.@pvp['arena']['team'][0]['name'].'.')
			}
			if(@pvp['team'][1]['captain'] == '') {
				drop_item(_relative(@pvp['arena']['spawn'][1][0], 'up', 2), @pvp['team'][1]['captainhat'], false)
			} else {
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.@pvp['arena']['team'][1]['color']
					.@pvp['team'][1]['captain']. ' is the captain of '.@pvp['arena']['team'][1]['name'].'.')
			}
		}, @id)
	}

	if(@pvp['arena']['mode'] == 'ctf') {
		_pvp_flag_spawn(@id, 0)
		_pvp_flag_spawn(@id, 1)
	}
	
	if(array_index_exists(@pvp['arena'], 'mobprotect')) {
		queue_push(closure(){
			foreach(@team: @mob in @pvp['arena']['mobprotect']) {
				 @entityid = _spawn_mob(@mob['type'], 1, @mob['loc'])[0]
				 set_mob_name(@entityid, @pvp['arena']['team'][@team]['color'].@pvp['arena']['team'][@team]['name'])
				 @pvp['team'][@team]['mobprotect'] = entity_uuid(@entityid)
			}
		}, @id)
	}

	include('events.ms');

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

		foreach(@player in array_keys(@pvp['players'])) {
			if(pinfo(@player, 5) <= 0, continue())
			# if(array_index_exists(@pvp['arena'], 'timer')) {
				# if(function_exists('premove_bar')) {
					# premove_bar(@player)
				# }
				# if(function_exists('set_bar_message')) {
					# set_bar_message(@player, @timeleft, @percentage)
				# }
			# }
			if(array_index_exists(@pvp['arena'], 'respawntime')
			&& @pvp['players'][@player]['respawn'] != 0) {
				if(!array_contains(sk_current_regions(@player), @pvp['arena']['broadcast'])) {
					_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
						.@pvp['players'][@player]['color'].@player
						.color('r').' left the arena.')
					if(array_index_exists(@pvp['players'][@player], 'class')) {
						_class('unload', @player, @pvp['players'][@player]['class'], @pvp)
					}
					# if(array_index_exists(@pvp['arena'], 'timer')) {
						# if(function_exists('premove_bar')) {
							# premove_bar(@player)
						# }
					# }
					if(array_index_exists(@pvp['arena'], 'resourcepack')) {
						send_resourcepack(@player, 'http://mc.finalscoremc.com:25966/resourcepacks/default.zip')
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
							_pvp_equip(@id, @player)
							@pvp['players'][@player]['respawn'] = 0
							close_pinv(@player)
						}
					} else {
						if(array_index_exists(@pvp['players'], 'team')) {
							@r = rand(0, array_size(@pvp['arena']['spawn'][@pvp['players'][player()]['team']]))
							set_ploc(@player, @pvp['arena']['spawn'][@pvp['players'][@player]['team']][@r])
						} else {
							@r = rand(0, array_size(@pvp['arena']['spawn'][0]))
							set_ploc(@player, @pvp['arena']['spawn'][0][@r])
						}
						_pvp_equip(@id, @player)
						@pvp['players'][@player]['respawn'] = 0
						close_pinv(@player)
					}
				}
			} else if(!array_contains(sk_current_regions(@player), @pvp['arena']['region'])) {
				tmsg(@player, color('gray').'[PVP] '.color('r').'You exited the combat region.')
				queue_push(closure(){
					pkill(@player)
				})
			} else if(@pvp['arena']['mode'] == 'koth' 
			&& array_contains(sk_current_regions(@player), @pvp['arena']['kothregion'])) { 
				@king = @player
				@hillcount++
			}
			
		}
		
		foreach(@p in @pvp['spectators']) {
			if(!array_contains(sk_current_regions(@p), @pvp['arena']['region'])) {
				_remove_spectator(@id, @p, @pvp)
			}
		}
		
		if(@pvp['arena']['mode'] == 'koth' && @hillcount == 1) {
			@score = get_pscore('seconds', @king, @id)
			set_pscore('seconds', @king, @score - 1, @id)
			@check = true
		}
		
		if(array_index_exists(@pvp['arena'], 'mobprotect')) {
			foreach(@team: @data in @pvp['arena']['mobprotect']) {
				try(@health = ceil(get_entity_health(entity_id(@pvp['team'][@team]['mobprotect'])))
				, @health = 0)
				set_pscore('mobhealth', @pvp['arena']['team'][@team]['name'], @health, @id)
				if(@health <= 0) {
					if(@team == 0) {
						_pvp_end_match(@id, @pvp['team'][1]['players'])
					} else {
						_pvp_end_match(@id, @pvp['team'][0]['players'])
					}
				}
			}
		}
		
		if(array_index_exists(@pvp['arena'], 'itemspawn')) {
			for(@i = 0, @i < array_size(@pvp['arena']['itemspawn']), @i++) {
				if(entity_exists(@pvp['itemspawn'][@i][0])) {
					@pvp['itemspawn'][@i][1] = time()
				} else if(@pvp['itemspawn'][@i][1] + (@pvp['arena']['itemspawn'][@i]['cooldown'] * 1000) < time()) {
					@id = drop_item(@pvp['arena']['itemspawn'][@i]['loc'], @pvp['arena']['itemspawn'][@i]['item'], false)
					try(
						set_entity_velocity(@id, array())
						play_sound(@pvp['arena']['itemspawn'][@i]['loc'], array('sound': 'ENDERMAN_TELEPORT', 'pitch': 1.5))
						make_effect(@pvp['arena']['itemspawn'][@i]['loc'], 'ENDER_SIGNAL')
						@pvp['itemspawn'][@i][0] = @id
						@pvp['itemspawn'][@i][1] = time()
					, @exception,
						console('Entity not found after being spawned. ('.@exception.')')
					, array('BadEntityException')
					)
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

		if(@check, 
			_pvp_check_objectives(@id))
	})
	
}

proc _pvp_flag_spawn(@id, @team, @loc) {
	@pvp = import('pvp'.@id);
	if(!is_array(@loc)) {
		@loc = @pvp['arena']['ctfflag'][@team];
	}
	if(!entity_exists(@pvp['team'][@team]['flag'])) {
		@pvp['team'][@team]['flag'] = drop_item(@loc, array('type': 425, 'data': if(@team == 0, '1', '4')), 0)
	} else if(_horizontal_distance(entity_loc(@pvp['team'][@team]['flag']), @pvp['arena']['ctfflag'][@team]) > 3) {
		@pvp['team'][@team]['flag'] = drop_item(@loc, array('type': 425, 'data': if(@team == 0, '1', '4')), 0)
	}
	queue_delay('30000', @id.@team.'flag');
	queue_push(closure(_pvp_flag_spawn(@id, @team)), @id.@team.'flag');
}

proc _flag(@item) {
	if(!is_null(@item) && @item['type'] == 425) {
		if(@item['data'] == 4) {
			return(1);
		} else if(@item['data'] == 1) {
			return(0);
		}
	}
	return(null);
}

proc _pvp_hat_spawn(@id, @team, @loc) {
	@pvp = import('pvp'.@id)
	@hat = drop_item(@loc, @pvp['team'][@team]['captainhat'])
	set_entity_velocity(@hat, array())
}

proc _squared_distance_to_segment(@p1, @p2a, @p2b) {
	@vx = @p2b['x'] - @p2a['x'];
	@vy = @p2b['y'] - @p2a['y'];
	@vz = @p2b['z'] - @p2a['z'];

	@wx = @p1['x'] - @p2a['x'];
	@wy = @p1['y'] - @p2a['y'];
	@wz = @p1['z'] - @p2a['z'];

	@c1 = @wx * @vx + @wy * @vy + @wz * @vz;
	if(@c1 <= 0) {
		return(((@p1['x'] - @p2a['x']) ** 2) + ((@p1['y'] - @p2a['y']) ** 2) + ((@p1['z'] - @p2a['z']) ** 2));
	}

	@c2 = @vx * @vx + @vy * @vy + @vz * @vz;
	if(@c2 <= @c1) {
		return(((@p1['x'] - @p2b['x']) ** 2) + ((@p1['y'] - @p2b['y']) ** 2) + ((@p1['z'] - @p2b['z']) ** 2));
	}

	@b = @c1 / @c2;
	@bx = @p2a['x'] + @b * @vx;
	@by = @p2a['y'] + @b * @vy;
	@bz = @p2a['z'] + @b * @vz;
	return(((@p1['x'] - @bx) ** 2) + ((@p1['y'] - @by) ** 2) + ((@p1['z'] - @bz) ** 2));
}

proc _pvp_check_objectives(@id) {
	@pvp = import('pvp'.@id)

	#check total player count
	if(array_size(@pvp['players']) < 1) {
		_pvp_end_match(@id, array())
		die()
	}

	if(array_contains(array('dm', 'koth', 'tntrun'), @pvp['arena']['mode']) 
	&& array_size(@pvp['players']) <= 1) {
		_pvp_end_match(@id, array_keys(@pvp['players']))
		die()
	}

	#check team player counts
	if(array_index_exists(@pvp, 'team')) {
		@teamcount = array(0, 0)
		foreach(@player in @pvp['players']) {
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
		foreach(@player: @data in @pvp['players']) {
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

proc _pvp_end_match(@id, @winners) {
	@pvp = import('pvp'.@id)
	
	if(@pvp['running'] != 2, return())

	try(
	
		foreach(array_keys(@pvp['players']), @player) {
			# if(array_index_exists(@pvp['arena'], 'timer')) {
				# if(function_exists('premove_bar')) {
					# premove_bar(@player)
				# }
			# }
			if(array_contains(@winners, @player)) {
				@leader = @player
				if(ponline(@player) && @pvp['coins'] >= 1) {
					_acc_add(@player, @pvp['coins'])
					tmsg(@player, color('gold').'+ '.@pvp['coins'].if(@pvp['coins'] >= 2, ' coins', ' coin'))
				}
			}
		}
		
		if(array_index_exists(@pvp, 'team') && array_size(@winners) > 0) {
			_worldmsg('custom', color('gray').'[PVP] '
				.@pvp['players'][@leader]['color'].color('bold')
				.@pvp['arena']['team'][@pvp['players'][@leader]['team']]['name'].' win!\n'
				.@pvp['players'][@leader]['color'].array_implode(@winners, ' '))
		} else if(array_size(@winners) > 0) {
			_worldmsg('custom', color('gray').'[PVP] '.color('r').array_implode(@winners, ' and ').' wins!')

		} else {
			_worldmsg('custom', color('gray').'[PVP] '.color('r').'Nobody wins! Wait.. what?!')
		}
		
		if(array_index_exists(@pvp, 'stats')) {
			_regionmsg(@pvp['arena']['broadcast'], 
				color('gray').'|--'.color('bold').'[ STATS ]'.color('gray').'-------------|\n'
				.color('gray').' Kills : Damage : Deaths\n'
				.'|------------------------|')
			foreach(@player: @stats in @pvp['stats']) {
				_regionmsg(@pvp['arena']['broadcast'], ' '.@stats['kills'].' : '.round(@stats['damage']).' : '.@stats['deaths'].' - '.@player)
			}
			_regionmsg(@pvp['arena']['broadcast'], color('gray').'|------------------------|')
		}
		
		if(array_index_exists(@pvp['arena'], 'chestspawn')) {
			for(@i = 0, @i < array_size(@pvp['arena']['chestspawn']), @i++) {
				if(get_block_at(@pvp['arena']['chestspawn'][@i]['loc']) == '54:0', 
					set_block_at(@pvp['arena']['chestspawn'][@i]['loc'], '0:0'))
			}
		}
	
	)

	try(
	
		if(array_index_exists(@pvp['arena'], 'rsoutput'), 
			set_block_at(@pvp['arena']['rsoutput'], '69:6'))

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

		clear_task(@pvp['interval'])
	
	, return())
	
	@pvp['running'] = 3

	set_timeout(4000, closure(){
		foreach(array_keys(@pvp['players']), @player) {
			try(
				if(array_index_exists(@pvp['players'][@player], 'class')) {
					_class('unload', @player, @pvp['players'][@player]['class'], @pvp)
				}
				if(ponline(@player) && pinfo(@player, 5) > 0) {
					close_pinv(@player)
					if(array_index_exists(@pvp['arena'], 'resourcepack')) {
						send_resourcepack(@player, 'http://mc.finalscoremc.com:25966/resourcepacks/default.zip')
					}
					set_entity_fall_distance(pinfo(@player, 13), 0);
					set_ploc(@player, @pvp['arena']['lobby']);
					_equip_park(@player);
					_clear_peffects(@player);
				}
			)
		}
		foreach(@bind in @pvp['binds']) {
			unbind(@bind)
		}
		foreach(@p in @pvp['spectators']) {
			_remove_spectator(@id, @p, @pvp)
		}
		_remove_region_entities(@pvp['arena']['region'])
		if(array_index_exists(@pvp['arena'], 'restore')) {
			set_timeout(3000, closure(){
				foreach(@player in all_players('custom')) {
					if(ponline(@player)) {
						broadcast(color('gray').'[PVP] '.color(6).'RESTORING '.to_upper(@id).'...')
						scriptas(@player,
							foreach(@region in @pvp['arena']['restore']) {
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
		

		# if(!array_index_exists(@pvp['arena'], 'flags') || !array_contains(@pvp['arena']['flags'], 'debug')) {
			# @arena = get_value('arena', @id)
			# if(array_index_exists(@arena, 'played')) {
				# @arena['played'] += 1
			# } else {
				# @arena['played'] = 1
			# }
		# }
		
		remove_scoreboard(@id);
		@pvp = array('players': array(), 'running': 0);
		export('pvp'.@id, @pvp);
		export('currently', null);

	})
}
