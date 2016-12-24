# BASE
include('utils.ms');
include('spectator.ms');
include('player.ms');
include('stats.ms');
include('weapons.ms');

# ARENA
if(array_contains(@pvp['arena']['flags'], 'script')){
	include('../arenas.library/'.@id.'.ms');
}

# CLASSES
if(array_index_exists(@pvp['arena'], 'classes')) {
	include('class.ms');
}

# CORE
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
				if(@pvp['arena']['chestspawn'][@i]['start'] === 'true') {
					@pvp['chestspawn'][@i] = 0
				} else {
					@pvp['chestspawn'][@i] = time()
					set_block_at(@pvp['arena']['chestspawn'][@i]['loc'], '0:0')
				}
			} else if(array_index_exists(@pvp['arena'], 'chestgroup')) {
				if(get_block_at(@pvp['arena']['chestspawn'][@i]['loc'])[0] === '0',
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
			if(@pvp['arena']['itemspawn'][@i]['start'] === 'true') {
				@time = 0
			} else {
				@time = time()
			}
			array_set(@pvp['itemspawn'], @i, array('', @time))
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

	if(@pvp['arena']['respawnmode'] == 'mob') {
		foreach(@team: @locations in @pvp['arena']['respawn']) {
			@pvp['team'][@team]['respawns'] = array();
			foreach(@loc in @locations) {
				@type = if(@team == 0, 'VILLAGER:FARMER', 'VILLAGER:BUTCHER');
				@loc[1] += 1;
				load_chunk(@loc);
				@uuid = _spawn_mob(@type, 1, @loc)[0];
				@pvp['team'][@team]['respawns'][] = @uuid;
			}
		}
	}

	if(array_index_exists(@pvp['arena'], 'timer')) {
		@pvp['starttime'] = time() / 1000
	}

	_remove_region_entities(@pvp['arena']['region'], array('DROPPED_ITEM', 'EXPERIENCE_ORB'), @pvp['arena']['lobby'][3])
	_pvp_initialize_players(@id, array_keys(@pvp['players']))

	if(array_index_exists(@pvp['arena'], 'captain')) {
		_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.@pvp['arena']['team'][0]['color']
			.@pvp['team'][0]['captain']. ' is the captain of '.@pvp['arena']['team'][0]['name'].'.')
		_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.@pvp['arena']['team'][1]['color']
			.@pvp['team'][1]['captain']. ' is the captain of '.@pvp['arena']['team'][1]['name'].'.')
	}

	if(array_index_exists(@pvp['arena'], 'mobprotect')) {
		queue_push(closure(){
			foreach(@team: @mob in @pvp['arena']['mobprotect']) {
				load_chunk(@mob['loc']);
				@entityid = _spawn_mob(@mob['type'], 1, @mob['loc'])[0];
				set_mob_name(@entityid, @pvp['arena']['team'][@team]['color'].@pvp['arena']['team'][@team]['name']);
				@pvp['team'][@team]['mobprotect'] = @entityid;
			}
		}, @id)
	}

	# MODES
	if(@pvp['arena']['mode'] !== 'dm') {
		include('../modes.library/'.@pvp['arena']['mode'].'.ms');
	}

	# WEAPONS
	if(array_index_exists(@pvp['arena'], 'weapons')) {
		foreach(@weapon in @pvp['arena']['weapons']) {
			include('../weapons.library/'.@weapon.'.ms');
		}
	}

	include('events.ms');

	@pvp['interval'] = set_interval(1000, closure(){
		@pvp = import('pvp'.@id);
		@arena = @pvp['arena'];
		@check = false;

		if(array_index_exists(@arena, 'timer')) {
			@totalsecsleft = ceil((@arena['timer'][1] * 60) - ((time() / 1000) - @pvp['starttime']))
			if(@totalsecsleft < 0) {
				_pvp_end_match(@id, @pvp['team'][@arena['timer'][0]]['players']);
				die();
			}
			@minleft = floor(@totalsecsleft / 60);
			@secsleft = mod(@totalsecsleft, 60);
			@timeleft = @minleft.':'.if(@secsleft < 10, '0').@secsleft;
			// @percentage = round((@totalsecsleft / (@pvp['arena']['timer'][1] * 60)) * 100)
			if(extension_exists('CHNaughty')) {
				foreach(@p in array_keys(@pvp['players'])) {
					action_msg(@p, @timeleft);
				}
			}
		}
		
		foreach(@player: @p in @pvp['players']) {
			if(pinfo(@player, 5) <= 0) {
				// dead
			 	continue();
			}
			if(array_index_exists(@arena, 'respawntime') && @p['respawn'] != 0) {
				if(!array_contains(sk_current_regions(@player), @arena['broadcast']) && ploc(@player)['y'] < 256) {
					_regionmsg(@arena['broadcast'], colorize('&7[PVP] '.@p['color'].@player.'&r left the arena.'));
					if(array_index_exists(@p, 'class')) {
						_class('unload', @player, @p['class'], @pvp);
					}
					if(array_index_exists(@arena, 'resourcepack')) {
						send_resourcepack(@player, 'http://mc.finalscoremc.com:25966/resourcepacks/default.zip');
					}
					array_remove(@pvp['players'], @player);
					dm_set_pvisible(@player, true);
					set_pflight(@player, false);
					preset_time(@player);
					set_pstorm(@player, null);
					_clear_pinv(@player);
					_clear_peffects(@player);
					@check = true;
				} else if(@p['respawn'] < time()) {
					@loc = array();
					if(array_index_exists(@arena, 'captain')) {
						if(@pvp['team'][@p['team']]['captain'] === '') {
							continue();
						}
						@loc = ploc(@pvp['team'][@p['team']]['captain']);
						play_sound(ploc(@player), array('sound': 'GHAST_FIREBALL'));
						make_effect(_relative(ploc(@player), 'up'), 'MOBSPAWNER_FLAMES');
					} else {
						if(array_index_exists(@pvp, 'team')) {
							@r = rand(0, array_size(@arena['spawn'][@p['team']]));
							@loc = @arena['spawn'][@p['team']][@r];
						} else {
							@r = rand(0, array_size(@arena['spawn'][0]));
							@loc = @arena['spawn'][0][@r];
						}
					}
					try {
						set_entity_fall_distance(puuid(@player), 0);
					} catch(BadEntityException @ex) {
						// this happened once... wat
					}
					set_ploc(@player, @loc);
					pfacing(@player, 0, 0);

					preset_time(@player);
					_pvp_equip(@id, @player);
					@p['respawn'] = 0;
					close_pinv(@player);
				} else {
					@timeleft = ceil((@p['respawn'] - time()) / 1000);
					title_msg(@player, @timeleft, null, 0, 20, 0);
					if(@timeleft == 3) {
						set_pstorm(@player, false);
					}
				}
			} else if(!array_contains(sk_current_regions(@player), @arena['region'])) {
				if(array_contains(@arena['flags'], 'exitrespawn')) {
					set_entity_fall_distance(puuid(@player), 0);
					if(array_index_exists(@pvp, 'team')) {
						@team = @pvp['players'][@player]['team'];
						set_ploc(@player, @arena['spawn'][@team][0]);
					} else {
						set_ploc(@player, @arena['spawn'][0][0]);
					}
				} else {
					tmsg(@player, color('gray').'[PVP] '.color('r').'You exited the combat region.')
					set_timeout(50, closure(){
						if(!_is_survival_world(pworld(@player)) && pinfo(@player, 5) > 0) {
							pkill(@player);
						}
					});
				}
			}

		} else {
			@check = true;
		}

		foreach(@p in @pvp['spectators']) {
			if(!array_contains(sk_current_regions(@p), @arena['region'])) {
				_remove_spectator(@p, @pvp);
			}
		}

		if(array_index_exists(@arena, 'itemspawn')) {
			foreach(@i: @item in @arena['itemspawn']) {
				if(@pvp['itemspawn'][@i][0]) {
					try {
						@loc = _relative(entity_loc(@pvp['itemspawn'][@i][0]), 'up', 0.4);
						@pvp['itemspawn'][@i][1] = time();
						if(extension_exists('CHSpigot')) {
							play_effect(@loc, 'FIREWORKS_SPARK', array('radius': 64, 'speed': 0));
						}
						continue();
					} catch(BadEntityException @ex) {
						// item drop was picked up or is unloaded
					}
				}
				if(@pvp['itemspawn'][@i][1] + (@item['cooldown'] * 1000) < time()) {
					@id = drop_item(@item['loc'], @item['item'], false);
					try {
						set_entity_velocity(@id, array(0, 0, 0));
						play_sound(@item['loc'], array('sound': 'ENDERMAN_TELEPORT', 'pitch': 1.5));
						make_effect(@item['loc'], 'ENDER_SIGNAL');
						@pvp['itemspawn'][@i][0] = @id;
						@pvp['itemspawn'][@i][1] = time();
					} catch(BadEntityException @ex) {
						// chunk might not be loaded, so try again next tick
						@pvp['itemspawn'][@i][0] = '';
					}
				}
			}
		}

		if(array_index_exists(@arena, 'mobspawn')) {
			foreach(@i: @mob in @arena['mobspawn']) {
				if((@pvp['mobspawn'][@i] + (@mob['respawn'] * 1000)) < time()) {
					_spawn_mob(@mob['type'], @mob['qty'], @mob['loc']);
					@pvp['mobspawn'][@i] = time();
				}
			}
		}

		if(array_index_exists(@arena, 'chestspawn')) {
			foreach(@i: @chest in @arena['chestspawn']) {
				if(array_index_exists(@pvp['chestspawn'], @i)
				&& (@pvp['chestspawn'][@i] + (@chest['cooldown'] * 1000)) < time()) {
					if(get_block_at(@chest['loc'])[0] === '0') {
						set_block_at(@chest['loc'], '54:0');
						for(@y = 0, @y < array_size(@chest['items']), @y++) {
							set_inventory_item(@chest['loc'], @y, @chest['items'][@y]);
						}
						@pvp['chestspawn'][@i] = time();
					}
				}
			}
		}
		
		// Mode specific code
		if(_interval(@pvp, @id)) {
			@check = true;
		}

		if(@check) {
			_pvp_check_objectives(@id);
		}
	})

}

proc _pvp_check_objectives(@id) {
	@pvp = import('pvp'.@id)

	#check player counts
	if(array_index_exists(@pvp, 'team')) {
		@teamcount = array(0, 0)
		@winner = -1;
		foreach(@player in @pvp['players']) {
			if(!array_index_exists(@pvp['arena'], 'captain')
			|| !array_index_exists(@pvp['arena'], 'respawntime')
			|| @player['respawn'] == 0) {
				@teamcount[@player['team']]++;
				@winner = @player['team'];
			}
		}
		if(@teamcount[0] == 0 || @teamcount[1] == 0) {
			if(@winner > -1) {
				_pvp_end_match(@id, @pvp['team'][@winner]['players']);
			} else {
				_pvp_end_match(@id, array());
			}
			die();
		}
	} else if(array_size(@pvp['players']) <= 1) {
		_pvp_end_match(@id, array_keys(@pvp['players']));
		die();
	}
	
	#check scores
	if(@pvp['arena']['mode'] == 'dm' && array_index_exists(@pvp['arena'], 'score')) {
		@scoreTarget = @pvp['arena']['score'];
		if(!array_index_exists(@pvp, 'team')) {
			foreach(@player: @data in @pvp['players']) {
				if(get_pscore('score', @player, @id) >= @scoreTarget) {
					_pvp_end_match(@id, array(@player));
					die();
				}
			}
		} else {
			if(get_pscore('score', @pvp['arena']['team'][0]['name'], @id) >= @scoreTarget) {
				_pvp_end_match(@id, @pvp['team'][0]['players']);
			} else if(get_pscore('score', @pvp['arena']['team'][1]['name'], @id) >= @scoreTarget) {
				_pvp_end_match(@id, @pvp['team'][1]['players']);
			}
		}
	}

	#check team scores
	if(@pvp['arena']['mode'] === 'ctf'
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
	@world = @pvp['arena']['lobby'][3];

	if(@pvp['running'] != 2, return())

	try {

		foreach(array_keys(@pvp['players']), @player) {
			if(array_contains(@winners, @player)) {
				@leader = @player;
				if(ponline(@player) && @pvp['coins'] >= 1) {
					_acc_add(@player, @pvp['coins']);
				}
			}
		}

		queue_push(closure(){
			if(array_index_exists(@pvp, 'stats')) {
				@table = _stats_table();
				@a = @table[0];
				@b = @table[1];
				@c = @table[2];
				@d = @table[3];
				@r = @pvp['arena']['broadcast'];
				_regionmsg(@r, colorize('&7&m|------------------------------&7&l[ &f&lTHE FINAL SCORE&7&l ]&7&m--|'));
				_regionmsg(@r, colorize(replace('--&7'.to_upper(@a[0]).' &8:&7 '.to_upper(@b[0]).' &8:&7 '.to_upper(@c[0]).' &8:&7 '.to_upper(@d[0]), '-', ' ')));
				_regionmsg(@pvp['arena']['broadcast'], colorize('&7&m|----------------------------------------------------|'));
				foreach(@player: @stats in @pvp['stats']) {
					_regionmsg(@r, replace('----'
						._pad_stat(@stats[@a[0]], @a[1]).@a[2]
						._pad_stat(@stats[@b[0]], @b[1]).@b[2]
						._pad_stat(@stats[@c[0]], @c[1]).@c[2]
						._pad_stat(integer(@stats[@d[0]]), @d[1]).@d[2]
						.if(array_contains(@winners, @player),
							color('gold').color('bold').@player.if(@pvp['coins'] > 0, ' +'.@pvp['coins']),
							@player)
						.'-', '-', ' '));
				}
				_regionmsg(@r, colorize('&7&m|----------------------------------------------------|'));
			} else if(array_index_exists(@pvp, 'team') && array_size(@winners) > 0) {
				_worldmsg(@world, color('gray').'[PVP] '
					.@pvp['players'][@leader]['color'].color('bold')
					.@pvp['arena']['team'][@pvp['players'][@leader]['team']]['name'].' win!\n'
					.@pvp['players'][@leader]['color'].array_implode(@winners, ' '));
			} else if(array_size(@winners) > 0) {
				_worldmsg(@world, color('gray').'[PVP] '.color('r').array_implode(@winners, ' and ').' wins!');

			} else {
				_worldmsg(@world, color('gray').'[PVP] '.color('r').'Nobody wins! Wait.. what?!');
			}
		}, @id);

		if(array_index_exists(@pvp['arena'], 'chestspawn')) {
			for(@i = 0, @i < array_size(@pvp['arena']['chestspawn']), @i++) {
				if(get_block_at(@pvp['arena']['chestspawn'][@i]['loc']) === '54:0',
					set_block_at(@pvp['arena']['chestspawn'][@i]['loc'], '0:0'))
			}
		}

	} catch(Exception @ex) {
		console(@ex, false);
	}

	try {

		if(array_index_exists(@pvp['arena'], 'rsoutput'),
			set_block_at(@pvp['arena']['rsoutput'], '69:6'))

		if(@pvp['arena']['mode'] === 'ctf') {
			queue_clear(@id.'0flag')
			queue_clear(@id.'1flag')
		}

		if(array_index_exists(@pvp['arena'], 'captain')) {
			queue_clear(@id.'0hat')
			queue_clear(@id.'1hat')
		}

		@chests = all_virtualchests();
		foreach(@chest in @chests) {
			if(@chest === @id.'0'
			|| @chest === @id.'1') {
				del_virtualchest(@chest);
			} else if(@chest === @id.'options') {
				del_virtualchest(@chest);
				unbind(@chest);
			}
		}

		clear_task(@pvp['interval'])

	} catch(Exception @ex) {
		console(@ex, false);
		return();
	}

	@pvp['running'] = 3

	queue_delay(4000, @id);
	queue_push(closure(){
		@pvp['running'] = 0;
		foreach(@player in array_keys(@pvp['players'])) {
			try {
				if(array_index_exists(@pvp['players'][@player], 'class')) {
					_class('unload', @player, @pvp['players'][@player]['class'], @pvp)
				}
				if(ponline(@player) && pinfo(@player, 5) > 0) {
					close_pinv(@player);
					set_pmode(@player, 'ADVENTURE');
					if(array_index_exists(@pvp['arena'], 'resourcepack')) {
						queue_push(closure(){
							send_resourcepack(@player, 'http://mc.finalscoremc.com:25966/resourcepacks/default.zip');
						}, @id);
					}
					dm_set_pvisible(@player, true);
					set_entity_fall_distance(puuid(@player), 0);
					if(array_index_exists(@pvp['arena'], 'podium') && array_contains(@winners, @player)) {
						set_ploc(@player, @pvp['arena']['podium']);
					} else {
						set_ploc(@player, @pvp['arena']['lobby']);
					}
					set_pflight(@player, false);
					_equip_kit(@player);
					_clear_peffects(@player);
				}
			} catch(Exception @ex) {
				console(@ex, false);
			}
		}
		foreach(@bind in @pvp['binds']) {
			unbind(@bind)
		}
		foreach(@p in @pvp['spectators']) {
			_remove_spectator(@p, @pvp);
		}
		_remove_region_entities(@pvp['arena']['region'], array(), @world);

		if(array_index_exists(@pvp['arena'], 'restore')) {
			foreach(@region in @pvp['arena']['restore']) {
				skcb_load(@region);
				skcb_paste(array(0, 0, 0, @world), array('origin': true));
			}
		}

		remove_scoreboard(@id);

		# Reset
		@pvp = array('players': associative_array(), 'running': 0);
		export('pvp'.@id, @pvp);
		_remove_activity('pvp'.@id);

	}, @id);
}
