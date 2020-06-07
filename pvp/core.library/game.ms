# BASE
include('utils.ms');
include('spectator.ms');
include('player.ms');
include('stats.ms');
include('weapons.ms');

# ARENA
@arenaScript = '../arenas.library/'.@id.'.ms';
if(file_exists(@arenaScript)){
	include(@arenaScript);
}

# CLASSES
if(array_index_exists(@pvp['arena'], 'classes')) {
	include('class.ms');
}

# CORE
proc _pvp_start_match(@id) {
	@pvp = import('pvp'.@id);
	@arena = @pvp['arena'];
	if(array_index_exists(@arena, 'rsoutput')) {
		set_block(@arena['rsoutput'], 'REDSTONE_TORCH');
	}
	if(array_index_exists(@arena, 'time')) {
		set_world_time(@arena['lobby'][3], @arena['time']);
	}

	if(array_index_exists(@arena, 'chestspawn')) {
		@pvp['chestspawn'] = array();
		for(@i = 0, @i < array_size(@arena['chestspawn']), @i++) {
			if(array_index_exists(@arena['chestspawn'][@i], 'cooldown')) {
				if(@arena['chestspawn'][@i]['start'] === 'true') {
					@pvp['chestspawn'][@i] = 0;
				} else {
					@pvp['chestspawn'][@i] = time();
					set_block(@arena['chestspawn'][@i]['loc'], 'AIR');
				}
			} else if(array_index_exists(@arena, 'chestgroup')) {
				if(get_block(@arena['chestspawn'][@i]['loc']) != 'CHEST') {
					set_block(@arena['chestspawn'][@i]['loc'], 'CHEST');
				}
				@r = rand(array_size(@arena['chestgroup'][@arena['chestspawn'][@i]['group']]));
				for(@y = 0, @y < 27, @y++) {
					@item = get_inventory_item(@arena['chestgroup'][@arena['chestspawn'][@i]['group']][@r], @y);
					set_inventory_item(@arena['chestspawn'][@i]['loc'], @y, @item);
				}
			}
		}
	}

	if(array_index_exists(@arena, 'itemspawn')) {
		@pvp['itemspawn'] = array();
		for(@i = 0, @i < array_size(@arena['itemspawn']), @i++) {
			@time = time();
			if(@arena['itemspawn'][@i]['start']) {
				@time = 0;
			}
			@pvp['itemspawn'][@i] = array('', @time);
		}
	}

	if(array_index_exists(@arena, 'mobspawn')) {
		@pvp['mobspawn'] = array();
		for(@i = 0, @i < array_size(@arena['mobspawn']), @i++) {
			@time = time();
			if(@arena['mobspawn'][@i]['start']) {
				@time = 0;
			}
			@pvp['mobspawn'][@i] = @time;
		}
	}

	if(@arena['respawnmode'] == 'mob') {
		foreach(@team: @locations in @arena['respawn']) {
			@pvp['team'][@team]['respawns'] = array();
			@type = null;
			if(@team == 0) {
				@type = array('type': 'VILLAGER', 'tags': array('profession': 'FARMER'));
			} else {
				@type = array('type': 'VILLAGER', 'tags': array('profession': 'BUTCHER'));
			 }
			foreach(@loc in @locations) {
				@loc[1] += 1;
				if(!get_block_info(@loc, 'solid')) {
					@uuid = _spawn_entity(@type, @loc);
					@pvp['team'][@team]['respawns'][] = @uuid;
				}
			}
		}
	}

	if(array_index_exists(@arena, 'timer')) {
		@pvp['starttime'] = time() / 1000;
	}

	_remove_region_entities(@arena['region'], array('DROPPED_ITEM', 'EXPERIENCE_ORB'), @arena['lobby'][3]);
	_pvp_initialize_players(@id, array_keys(@pvp['players']));

	if(array_index_exists(@arena, 'captain')) {
		_pvp_msg(@pvp, color('gray').'[PVP] '.@arena['team'][0]['color']
			.@pvp['team'][0]['captain']. ' is the captain of '.@arena['team'][0]['name'].'.');
		_pvp_msg(@pvp, color('gray').'[PVP] '.@arena['team'][1]['color']
			.@pvp['team'][1]['captain']. ' is the captain of '.@arena['team'][1]['name'].'.');
	}

	if(array_index_exists(@arena, 'mobprotect')) {
		queue_push(closure(){
			foreach(@team: @mob in @arena['mobprotect']) {
				get_block(@mob['loc']); // loads chunk
				@entityid = _spawn_entity(@mob['type'], @mob['loc']);
				set_mob_name(@entityid, @arena['team'][@team]['color'].@arena['team'][@team]['name']);
				@pvp['team'][@team]['mobprotect'] = @entityid;
			}
		}, @id);
	}

	# MODES
	@modeScript = '../modes.library/'.@arena['mode'].'.ms';
	if(file_exists(@modeScript)) {
		include(@modeScript);
	}

	# WEAPONS
	if(array_index_exists(@arena, 'weapons')) {
		foreach(@weapon in @arena['weapons']) {
			include('../weapons.library/'.@weapon.'.ms');
		}
	}

	# ARENA
	if(array_contains(@arena['flags'], 'script')){
		_load_events(@id);
	}

	include('events.ms');

	@pvp['interval'] = set_interval(1000, closure(){
		@check = false;

		if(array_index_exists(@arena, 'timer')) {
			@totalsecsleft = ceil((@arena['timer'][1] * 60) - ((time() / 1000) - @pvp['starttime']));
			if(@totalsecsleft < 0) {
				_pvp_end_match(@id, @pvp['team'][@arena['timer'][0]]['players']);
				die();
			}
			@minleft = floor(@totalsecsleft / 60);
			@secsleft = mod(@totalsecsleft, 60);
			@timeleft = @minleft.':'.if(@secsleft < 10, '0').@secsleft;
			// @percentage = round((@totalsecsleft / (@arena['timer'][1] * 60)) * 100);
			if(extension_exists('CHNaughty')) {
				foreach(@p in array_merge(array_keys(@pvp['players']), @pvp['spectators'])) {
					action_msg(@p, @timeleft);
				}
			}
		}

		foreach(@player: @p in @pvp['players']) {
			if(array_index_exists(@arena, 'respawntime') && @p['respawn'] != 0) {
				if(!array_contains(sk_current_regions(@player), @arena['region'])) {
					if(pmode(@player) != 'SPECTATOR') {
						_pvp_msg(@pvp, colorize('&7[PVP] '.@p['color'].@player.'&r left the arena.'));
						if(array_index_exists(@arena, 'resourcepack')) {
							send_resourcepack(@player, 'http://mc.finalscoremc.com:25966/resourcepacks/default.zip');
						}
						_player_remove(@player, @id);
					} else {
						set_ploc(@player, @arena['spawn'][0][0]);
					}
				} else if(@p['respawn'] < time()) {
					@loc = array();
					if(array_index_exists(@arena, 'captain')) {
						if(@pvp['team'][@p['team']]['captain'] === '') {
							continue();
						}
						@loc = ploc(@pvp['team'][@p['team']]['captain']);
						play_sound(ploc(@player), array('sound': 'ENTITY_GHAST_SHOOT'));
						make_effect(location_shift(ploc(@player), 'up'), 'MOBSPAWNER_FLAMES');
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

					if(array_contains(@arena['flags'], 'build')) {
						set_pmode(@player, 'SURVIVAL');
					} else {
						set_pmode(@player, 'ADVENTURE');
					}
					if(array_index_exists(@pvp['players'][@player], 'class')) {
						_class('load', @player, @pvp['players'][@player]['class'], @pvp);
					}
					preset_time(@player);
					_player_equip(@id, @player);
					@p['respawn'] = 0;
					close_pinv(@player);
				} else {
					@timeleft = ceil((@p['respawn'] - time()) / 1000);
					title(@player, @timeleft, null, 0, 20, 0);
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
					tmsg(@player, color('gray').'[PVP] '.color('r').'You exited the combat region.');
					set_timeout(50, closure(){
						if(!_is_survival_world(pworld(@player))) {
							pkill(@player);
						}
					});
				}
			}

		} else {
			@check = true;
		}

		foreach(@i: @p in @pvp['spectators']) {
			try {
				if(!array_contains(sk_current_regions(@p), @arena['region'])) {
					_spectator_remove(@p, @pvp);
				}
			} catch(PlayerOfflineException @ex) {
				array_remove(@pvp['spectators'], @i);
			}
		}

		if(array_index_exists(@arena, 'itemspawn')) {
			foreach(@i: @item in @arena['itemspawn']) {
				@itemspawn = @pvp['itemspawn'][@i];
				if(@itemspawn[0]) {
					try {
						@loc = location_shift(entity_loc(@itemspawn[0]), 'up', 0.4);
						@itemspawn[1] = time();
						@players = array_merge(@pvp['spectators'], array_keys(@pvp['players']));
						spawn_particle(@loc, 'FIREWORKS_SPARK', @players);
						continue();
					} catch(BadEntityException @ex) {
						// item drop was picked up or is unloaded
					}
				}
				if(@itemspawn[1] + (@item['cooldown'] * 1000) < time()) {
					@id = drop_item(@item['loc'], @item['item'], false);
					try {
						set_entity_velocity(@id, array(0, 0, 0));
						play_sound(@item['loc'], array('sound': 'ENTITY_ENDERMAN_TELEPORT', 'pitch': 1.5));
						make_effect(@item['loc'], 'ENDER_SIGNAL');
						@itemspawn[0] = @id;
						@itemspawn[1] = time();
					} catch(BadEntityException @ex) {
						// chunk might not be loaded, so try again next tick
						@itemspawn[0] = '';
					}
				}
			}
		}

		if(array_index_exists(@arena, 'mobspawn')) {
			foreach(@i: @mob in @arena['mobspawn']) {
				if((@pvp['mobspawn'][@i] + (@mob['respawn'] * 1000)) < time()) {
					_spawn_entity(@mob['type'], @mob['loc']);
					@pvp['mobspawn'][@i] = time();
				}
			}
		}

		if(array_index_exists(@arena, 'chestspawn')) {
			foreach(@i: @chest in @arena['chestspawn']) {
				if(array_index_exists(@pvp['chestspawn'], @i)
				&& (@pvp['chestspawn'][@i] + (@chest['cooldown'] * 1000)) < time()) {
					if(get_block(@chest['loc']) === 'AIR') {
						set_block(@chest['loc'], 'CHEST');
						for(@y = 0, @y < array_size(@chest['items']), @y++) {
							set_inventory_item(@chest['loc'], @y, @chest['items'][@y]);
						}
						@pvp['chestspawn'][@i] = time();
					}
				}
			}
		}

		if(array_index_exists(@arena, 'blockbreak') && @pvp['blockcheck']) {
			foreach(@team in array(0, 1)) {
				foreach(@index: @loc in @arena['blockbreak'][@team]) {
					if(get_block(@loc) == 'AIR') {
						array_remove(@arena['blockbreak'][@team], @index);
						@count = array_size(@arena['blockbreak'][@team]);
						set_pscore('blocks', @arena['team'][@team]['name'], @count, @id);
						if(@count < 1) {
							_pvp_end_match(@id, @pvp['team'][if(@team, 0, 1)]['players']);
							die();
						}
						play_sound(@loc, array('sound': 'ENTITY_ZOMBIE_VILLAGER_CONVERTED', 'volume': 5), @pvp['team'][@team]['players']);
					}
				}
			}
			@pvp['blockcheck'] = false;
		}

		// Mode specific code
		_interval(@pvp, @id);

		if(@check) {
			_pvp_check_objectives(@id);
		}
	});

}

proc _pvp_check_objectives(@id) {
	@pvp = import('pvp'.@id);

	if(!@pvp || @pvp['running'] != 2) {
		return();
	}

	@arena = @pvp['arena'];

	#check player counts
	if(array_index_exists(@pvp, 'team')) {
		@teamcount = array(0, 0);
		@winner = -1;
		foreach(@player in @pvp['players']) {
			if(!array_index_exists(@arena, 'captain')
			|| !array_index_exists(@arena, 'respawntime')
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
	if(@arena['mode'] == 'dm' && array_index_exists(@arena, 'score')) {
		@scoreTarget = @arena['score'];
		if(!array_index_exists(@pvp, 'team')) {
			foreach(@player: @data in @pvp['players']) {
				if(get_pscore('score', @player, @id) >= @scoreTarget) {
					_pvp_end_match(@id, array(@player));
					die();
				}
			}
		} else {
			if(get_pscore('score', @arena['team'][0]['name'], @id) >= @scoreTarget) {
				_pvp_end_match(@id, @pvp['team'][0]['players']);
			} else if(get_pscore('score', @arena['team'][1]['name'], @id) >= @scoreTarget) {
				_pvp_end_match(@id, @pvp['team'][1]['players']);
			}
		}
	}

	#check team scores
	if(@arena['mode'] === 'ctf' || @arena['mode'] === 'bombingrun'
	&& (@pvp['team'][0]['score'] >= @arena['score'] || @pvp['team'][1]['score'] >= @arena['score'])) {
		if(@pvp['team'][0]['score'] >= @arena['score']) {
			@topteam = 0;
		} else {
			@topteam = 1;
		}
		_pvp_end_match(@id, @pvp['team'][@topteam]['players']);
		die();
	}

}

proc _pvp_end_round(@id, @winners) {
	@pvp = import('pvp'.@id);
	if(array_index_exists(@pvp, 'round') && @pvp['arena']['rounds'] < @pvp['round']) {
		@pvp['round']++;
	} else {
		_pvp_end_match(@id, @winners);
	}
}

proc _pvp_end_match(@id, @winners) {
	@pvp = import('pvp'.@id);
	@arena = @pvp['arena'];
	@world = @arena['lobby'][3];

	if(@pvp['running'] != 2) {
		return();
	}

	foreach(array_keys(@pvp['players']), @player) {
		if(array_contains(@winners, @player)) {
			@leader = @player;
			if(ponline(@player) && @pvp['coins'] >= 1) {
				_acc_add(@player, @pvp['coins']);
			}
		}
	}

	// Make sure we don't assign them to the same solo team twice in a row
	@lastSolo = '';
	if(array_index_exists(@arena, 'teamratio')) {
		@teams = array_indexes(@arena['teamratio'], 1);
		if(array_size(@teams) == 1) {
			@team = @teams[0];
			@lastSolo = array_implode(@pvp['team'][@team]['players']);
		}
	}

	queue_delay(100, @id); // timing ensures players are alive or in spec
	queue_push(closure(){
		if(array_index_exists(@pvp, 'stats')) {
			@table = _stats_table();
			@a = @table[0];
			@b = @table[1];
			@c = @table[2];
			@d = @table[3];
			_pvp_msg(@pvp, colorize('&7&m|------------------------------&7&l[ &f&lTHE FINAL SCORE&7&l ]&7&m--|'));
			_pvp_msg(@pvp, colorize(replace('--&7'.to_upper(@a[0]).' &8:&7 '.to_upper(@b[0]).' &8:&7 '.to_upper(@c[0]).' &8:&7 '.to_upper(@d[0]), '-', ' ')));
			_pvp_msg(@pvp, colorize('&7&m|----------------------------------------------------|'));
			foreach(@player: @stats in @pvp['stats']) {
				_pvp_msg(@pvp, replace('----'
					._stat_pad(@stats[@a[0]], @a[1]).@a[2]
					._stat_pad(@stats[@b[0]], @b[1]).@b[2]
					._stat_pad(@stats[@c[0]], @c[1]).@c[2]
					._stat_pad(integer(@stats[@d[0]]), @d[1]).@d[2]
					.if(array_contains(@winners, @player),
						color('gold').color('bold').@player.if(@pvp['coins'] > 0, ' +'.@pvp['coins']),
						@player)
					.'-', '-', ' '));
			}
			_pvp_msg(@pvp, colorize('&7&m|----------------------------------------------------|'));
		} else if(array_index_exists(@pvp, 'team') && array_size(@winners) > 0) {
			_worldmsg(@world, color('gray').'[PVP] '
				.@pvp['players'][@leader]['color'].color('bold')
				.@arena['team'][@pvp['players'][@leader]['team']]['name'].' win!\n'
				.@pvp['players'][@leader]['color'].array_implode(@winners, ' '));
		} else if(array_size(@winners) > 0) {
			_worldmsg(@world, color('gray').'[PVP] '.color('r').array_implode(@winners, ' and ').' wins!');

		} else {
			_worldmsg(@world, color('gray').'[PVP] '.color('r').'Nobody wins! Wait.. what?!');
		}
	}, @id);

	queue_push(closure(){
		if(array_index_exists(@pvp, 'stats')) {
			_store_stats(@winners, @pvp);
		}
	}, @id);

	if(array_index_exists(@arena, 'chestspawn')) {
		for(@i = 0, @i < array_size(@arena['chestspawn']), @i++) {
			if(get_block(@arena['chestspawn'][@i]['loc']) === 'CHEST') {
				set_block(@arena['chestspawn'][@i]['loc'], 'AIR');
			}
		}
	}

	try {

		if(array_index_exists(@arena, 'rsoutput')) {
			set_block(@arena['rsoutput'], 'TORCH');
		}

		if(@arena['mode'] === 'ctf') {
			queue_clear(@id.'0flag');
			queue_clear(@id.'1flag');
		} else if(@arena['mode'] === 'bombingrun') {
			queue_clear(@id.'bomb');
		}

		if(array_index_exists(@arena, 'captain')) {
			queue_clear(@id.'0hat');
			queue_clear(@id.'1hat');
		}

		@chests = get_virtual_inventories();
		foreach(@chest in @chests) {
			if(@chest === @id.'0'
			|| @chest === @id.'1') {
				delete_virtual_inventory(@chest);
			} else if(@chest === @id.'options') {
				delete_virtual_inventory(@chest);
				unbind(@chest);
			}
		}

		if(array_index_exists(@pvp, 'interval')) {
			clear_task(@pvp['interval']);
		}

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
					_class('unload', @player, @pvp['players'][@player]['class'], @pvp);
					array_remove(@pvp['players'][@player], 'class');
				}
				if(ponline(@player)) {
					close_pinv(@player);
					if(array_index_exists(@arena, 'resourcepack')) {
						send_resourcepack(@player, 'http://mc.finalscoremc.com:25966/resourcepacks/default.zip');
					}
					_player_remove(@player, @id);
					if(array_index_exists(@arena, 'podium') && array_contains(@winners, @player)) {
						set_ploc(@player, @arena['podium']);
					}
				}
			} catch(Exception @ex) {
				console(@ex, false);
			}
		}
		foreach(@bind in @pvp['binds']) {
			unbind(@bind);
		}
		foreach(@p in @pvp['spectators']) {
			_spectator_remove(@p, @pvp);
		}
		_remove_region_entities(@arena['region'], array(), @world);

		if(array_index_exists(@arena, 'restore')) {
			broadcast(color('YELLOW').'Restoring PVP arena...');
			foreach(@region in @arena['restore']) {
				skcb_load(@region);
				skcb_paste(array(0, 0, 0, @world), array('origin': true));
			}
		}
		queue_push(closure(){
			remove_scoreboard(@id);

			# Reset
			@pvp = array('players': associative_array(), 'running': 0, 'id': @pvp['id']);
			if(@lastSolo) {
				@pvp['lastsolo'] = @lastSolo;
			}
			export('pvp'.@id, @pvp);
			_remove_activity('pvp'.@id);
			_menu_refresh_pvp();
		}, @id);

	}, @id);
}
