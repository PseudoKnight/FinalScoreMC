# BASE
include('utils.ms');
include('spectator.ms');
include('player.ms');
include('stats.ms');
include('weapons.ms');

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

	if(@pvp['arena']['respawnmode'] == 'mob') {
		@pvp['team'][@team]['respawns'] = array();
		foreach(@team: @locations in @pvp['arena']['respawn']) {
			foreach(@loc in @locations) {
				@type = if(@team == 0, 'VILLAGER:FARMER', 'VILLAGER:BUTCHER');
				@loc[1] += 1;
				@uuid = _spawn_mob(@type, 1, @loc)[0];
				@pvp['team'][@team]['respawns'][] = @uuid;
			}
		}
	}

	if(array_index_exists(@pvp['arena'], 'timer')) {
		@pvp['starttime'] = time() / 1000
	}

	_remove_region_entities(@pvp['arena']['region'], array('DROPPED_ITEM', 'EXPERIENCE_ORB'))
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
				 @entityid = _spawn_mob(@mob['type'], 1, @mob['loc'])[0]
				 set_mob_name(@entityid, @pvp['arena']['team'][@team]['color'].@pvp['arena']['team'][@team]['name'])
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
		@pvp = import('pvp'.@id)
		@check = false
		if(@pvp['arena']['mode'] === 'koth',
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
			if(extension_exists('CHNaughty')) {
				foreach(@p in array_keys(@pvp['players'])) {
					action_msg(@p, @timeleft);
				}
			}
		}

		foreach(@player in array_keys(@pvp['players'])) {
			if(pinfo(@player, 5) <= 0, continue())
			if(array_index_exists(@pvp['arena'], 'respawntime')
			&& @pvp['players'][@player]['respawn'] != 0) {
				if(!array_contains(sk_current_regions(@player), @pvp['arena']['broadcast']) && ploc(@player)['y'] < 256) {
					_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
						.@pvp['players'][@player]['color'].@player
						.color('r').' left the arena.')
					if(array_index_exists(@pvp['players'][@player], 'class')) {
						_class('unload', @player, @pvp['players'][@player]['class'], @pvp)
					}
					if(array_index_exists(@pvp['arena'], 'resourcepack')) {
						send_resourcepack(@player, 'http://mc.finalscoremc.com:25966/resourcepacks/default.zip')
					}
					array_remove(@pvp['players'], @player);
					dm_set_pvisible(@player, true);
					set_pflight(@player, false);
					preset_time(@player);
					set_pstorm(@player, null);
					_clear_pinv(@player)
					_clear_peffects(@player)
					@check = true
				} else if(@pvp['players'][@player]['respawn'] < time()) {
					@loc = array();
					if(array_index_exists(@pvp['arena'], 'captain')) {
						if(@pvp['team'][@pvp['players'][@player]['team']]['captain'] === '') {
							continue();
						}
						@loc = ploc(@pvp['team'][@pvp['players'][@player]['team']]['captain']);
						play_sound(ploc(@player), array('sound': 'GHAST_FIREBALL'));
						make_effect(_relative(ploc(@player), 'up'), 'MOBSPAWNER_FLAMES');
					} else {
						if(array_index_exists(@pvp['players'], 'team')) {
							@r = rand(0, array_size(@pvp['arena']['spawn'][@pvp['players'][@player]['team']]));
							@loc = @pvp['arena']['spawn'][@pvp['players'][@player]['team']][@r];
						} else {
							@r = rand(0, array_size(@pvp['arena']['spawn'][0]));
							@loc = @pvp['arena']['spawn'][0][@r];
						}
					}
					try(set_entity_fall_distance(puuid(@player), 0));
					set_ploc(@player, @loc);
					pfacing(@player, 0, 0);

					preset_time(@player);
					set_pstorm(@player, null);
					_pvp_equip(@id, @player);
					@pvp['players'][@player]['respawn'] = 0;
					close_pinv(@player);
				} else {
					@timeleft = ceil((@pvp['players'][@player]['respawn'] - time()) / 1000);
					title_msg(@player, @timeleft, null, 0, 20, 0);
				}
			} else if(!array_contains(sk_current_regions(@player), @pvp['arena']['region'])) {
				tmsg(@player, color('gray').'[PVP] '.color('r').'You exited the combat region.')
				queue_push(closure(){
					if(pworld(@player) === 'custom') {
						pkill(@player);
					}
				})
			} else if(@pvp['arena']['mode'] === 'koth'
			&& array_contains(sk_current_regions(@player), @pvp['arena']['kothregion'])) {
				@king = @player
				@hillcount++
			}

		}

		foreach(@p in @pvp['spectators']) {
			if(!array_contains(sk_current_regions(@p), @pvp['arena']['region'])) {
				_remove_spectator(@p, @pvp);
			}
		}

		if(@pvp['arena']['mode'] === 'koth' && @hillcount == 1) {
			@score = get_pscore('seconds', @king, @id)
			set_pscore('seconds', @king, @score - 1, @id)
			@check = true
		}

		if(array_index_exists(@pvp['arena'], 'itemspawn')) {
			foreach(@i: @item in @pvp['arena']['itemspawn']) {
				try(
					@loc = _relative(entity_loc(@pvp['itemspawn'][@i][0]), 'up', 0.4);
					@pvp['itemspawn'][@i][1] = time();
					if(extension_exists('CHSpigot')) {
						play_effect(@loc, 'FIREWORKS_SPARK', array('radius': 64, 'speed': 0));
					}
				, # doesn't exist
					if(@pvp['itemspawn'][@i][1] + (@item['cooldown'] * 1000) < time()) {
						@id = drop_item(@item['loc'], @item['item'], false);
						try( # maybe chunk isn't loaded?
							set_entity_velocity(@id, array(0, 0, 0));
							play_sound(@item['loc'], array('sound': 'ENDERMAN_TELEPORT', 'pitch': 1.5));
							make_effect(@item['loc'], 'ENDER_SIGNAL');
							@pvp['itemspawn'][@i][0] = @id;
							@pvp['itemspawn'][@i][1] = time();
						)
					}
				);
			}
		}

		if(array_index_exists(@pvp['arena'], 'mobspawn')) {
			foreach(@i: @mob in @pvp['arena']['mobspawn']) {
				if((@pvp['mobspawn'][@i] + (@mob['respawn'] * 1000)) < time()) {
					_spawn_mob(@mob['type'], @mob['qty'], @mob['loc']);
					@pvp['mobspawn'][@i] = time();
				}
			}
		}

		if(array_index_exists(@pvp['arena'], 'chestspawn')) {
			foreach(@i: @chest in @pvp['arena']['chestspawn']) {
				if(array_index_exists(@pvp['chestspawn'], @i)
				&& (@pvp['chestspawn'][@i] + (@chest['cooldown'] * 1000)) < time()) {
					if(get_block_at(@chest['loc'])[0] === '0') {
						set_block_at(@chest['loc'], '54:0');
						for(@y = 0, @y < array_size(@chest['items']), @y++,
							set_inventory_item(@chest['loc'], @y, @chest['items'][@y]);
						)
						@pvp['chestspawn'][@i] = time();
					}
				}
			}
		}

		if(@check,
			_pvp_check_objectives(@id))
	})

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
	if(@pvp['arena']['mode'] === 'koth') {
		foreach(@player: @data in @pvp['players']) {
			if(get_pscore('seconds', @player, @id)  <= 0) {
				_pvp_end_match(@id, array(@player))
				die()
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

	if(@pvp['running'] != 2, return())

	try(

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
				_regionmsg(@pvp['arena']['broadcast'], colorize('&7&m|------------------------------&7&l[ &f&lTHE FINAL SCORE&7&l ]&7&m--|'));
				_regionmsg(@pvp['arena']['broadcast'], colorize(replace('--&7KILLS &8:&7 DEATHS &8:&7 PICKUPS &8:&7 DAMAGE', '-', ' ')));
				_regionmsg(@pvp['arena']['broadcast'], colorize('&7&m|----------------------------------------------------|'));
				foreach(@player: @stats in @pvp['stats']) {
					_regionmsg(@pvp['arena']['broadcast'], replace('----'
						._pad_stat(@stats['kills'], 2).'-------'
						._pad_stat(@stats['deaths'], 2).'---------'
						._pad_stat(@stats['pickups'], 2).'--------'
						._pad_stat(round(@stats['damage']), 3).'------'
						.if(array_contains(@winners, @player), color('gold').color('bold').@player.' +'.@pvp['coins'], @player).'-', '-', ' '));
				}
				_regionmsg(@pvp['arena']['broadcast'], colorize('&7&m|----------------------------------------------------|'));
			} else if(array_index_exists(@pvp, 'team') && array_size(@winners) > 0) {
				_worldmsg('custom', color('gray').'[PVP] '
					.@pvp['players'][@leader]['color'].color('bold')
					.@pvp['arena']['team'][@pvp['players'][@leader]['team']]['name'].' win!\n'
					.@pvp['players'][@leader]['color'].array_implode(@winners, ' '));
			} else if(array_size(@winners) > 0) {
				_worldmsg('custom', color('gray').'[PVP] '.color('r').array_implode(@winners, ' and ').' wins!');

			} else {
				_worldmsg('custom', color('gray').'[PVP] '.color('r').'Nobody wins! Wait.. what?!');
			}
		}, @id);



		if(array_index_exists(@pvp['arena'], 'chestspawn')) {
			for(@i = 0, @i < array_size(@pvp['arena']['chestspawn']), @i++) {
				if(get_block_at(@pvp['arena']['chestspawn'][@i]['loc']) === '54:0',
					set_block_at(@pvp['arena']['chestspawn'][@i]['loc'], '0:0'))
			}
		}

	)

	try(

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

	, return())

	@pvp['running'] = 3

	queue_delay(4000, @id);
	queue_push(closure(){
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
					dm_set_pvisible(@player, true);
					set_entity_fall_distance(puuid(@player), 0);
					set_ploc(@player, @pvp['arena']['lobby']);
					set_pflight(@player, false);
					_equip_park(@player);
					_clear_peffects(@player);
				}
			)
		}
		foreach(@bind in @pvp['binds']) {
			unbind(@bind)
		}
		foreach(@p in @pvp['spectators']) {
			_remove_spectator(@p, @pvp);
		}
		_remove_region_entities(@pvp['arena']['region']);

		if(array_index_exists(@pvp['arena'], 'restore')) {
			foreach(@region in @pvp['arena']['restore']) {
				skcb_load(@region);
				skcb_paste(array(0, 0, 0, 'custom'), array('origin': true));
			}
		}

		remove_scoreboard(@id);

		# Store stats
		if(!array_index_exists(@pvp['arena'], 'flags') || !array_contains(@pvp['arena']['flags'], 'debug')) {
			@arena = get_value('arena.'.@id);
			if(!array_index_exists(@arena, 'played')) {
				@arena['played'] = 1;
			} else {
				@arena['played'] += 1;
			}
			if(array_index_exists(@pvp['arena'], 'classes')) {
				@arena['classes'] = @pvp['arena']['classes'];
			}
			store_value('arena.'.@id, @arena);
		}

		# Reset
		@pvp = array('players': associative_array(), 'running': 0);
		export('pvp'.@id, @pvp);
		_remove_activity('pvp'.@id);

	}, @id);
}
