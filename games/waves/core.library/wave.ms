proc _waves_prepare_next(@waves) {
	@waveNum = @waves['wave'];
	@p = null;
	foreach(@p in @waves['players']) {
		if(pmode(@p) !== 'SPECTATOR') {
			if(@waveNum > 1 && array_index_exists(@waves['config'], 'shop')) {
				set_plevel(@p, plevel(@p) + 1);
				action_msg(@p, colorize('&e+1 level'));
				@waves['allplayers'][@p]['wave']++;
			}
		}
		if(array_index_exists(@waves['config'], 'sounds', 'wave_end')) {
			play_sound(ploc(@p), @waves['config']['sounds']['wave_end'], @p);
		}
	}
	if(array_index_exists(@waves['config'], 'respawn') && @waves['config']['respawn'] === 'WAVE_END') {
		foreach(@p in @waves['players']) {
			if(pmode(@p) === 'SPECTATOR') {
				@loc = import(@p.'spawn');
				if(!@loc) {
					@loc = array_get_rand(@waves['arena']['center']);
				}
				set_ploc(@p, @loc);
				set_pmode(@p, 'ADVENTURE');
			}
		}
	}

	@wave = if(@waves['name'] === 'random',
			_get_random_wave(@waves, @waveNum, null),
			@waves['config']['waves'][@waveNum]);

	@waves['bounty'] = null;
	@waves['mobCount'] = 0;
	if(array_index_exists(@wave, 'title')) {
		@waves['title'] = @wave['title'];
	}
	if(array_index_exists(@wave, 'music')) {
		if(@waves['music']) {
			foreach(@p in @waves['players']) {
				stop_named_sound(@p, @waves['music'], 'RECORDS');
			}
		}
		@waves['music'] = @wave['music'];
		play_named_sound(ploc(@p), array(sound: @waves['music'], volume: 3, category: 'RECORDS'));
	}
	if(array_index_exists(@wave, 'items')) {
		foreach(@p in @waves['players']) {
			if(pmode(@p) !== 'SPECTATOR') {
				foreach(@item in @wave['items']) {
					drop_item(@p, @item);
				}
			}
		}
	}
	if(array_index_exists(@wave, 'effects')) {
		foreach(@p in @waves['players']) {
			if(pmode(@p) !== 'SPECTATOR') {
				foreach(@id: @effect in @wave['effects']) {
					set_peffect(@p, @id, @effect['strength'], @effect['seconds'],
						array_get(@effect, 'ambient', true),
						array_get(@effect, 'particles', true),
						array_get(@effect, 'icon', true));
				}
			}
		}
	}
	if(array_index_exists(@wave, 'subtitle')) {
		@waves['subtitle'] = @wave['subtitle'];
	}
	if(array_index_exists(@wave, 'duplicate')) {
		@waves['duplicate'] = @wave['duplicate'];
	} else if(@waves['name'] === 'random') {
		@waves['duplicate'] = array_size(@waves['players']);
	} else {
		@waves['duplicate'] = 1;
	}
	if(array_index_exists(@wave, 'trigger')
	&& array_index_exists(@waves['arena']['triggers'], @wave['trigger'])) {
		@triggerId = @wave['trigger'];
		@trigger = @waves['arena']['triggers'][@triggerId];
		set_block(@trigger, 'REDSTONE_BLOCK');
		@waves['trigger'] = @trigger;
	}

	@waves['mobs'] = @wave['mobs'];
	@waves['spawns'] = null;

	if(array_index_exists(@wave, 'bossbar')) {
		@waves['bossbar'] = @wave['bossbar'];
		update_bar('waves'.@waves['region'], array(
			percent: 0.0,
			visible: true,
			title: @waves['bossbar'],
			style: 'SEGMENTED_6',
		));
	} else {
		@waves['bossbar'] = '';
		update_bar('waves'.@waves['region'], array(visible: false));
	}
}

proc _waves_prepare_spawns(@waves, @secondsTillSpawn = 4) {
	@spawnGroups = associative_array();
	foreach(@mob in @waves['mobs']) {
		@spawnGroup = 'spawns';
		if(is_array(@mob) && array_index_exists(@mob, 'pos')) {
			@spawnGroup = @mob['pos'];
		}
		if(!array_index_exists(@spawnGroups, @spawnGroup)) {
			@spawnGroups[@spawnGroup] = 0;
		}
		if(is_array(@mob) && array_index_exists(@mob, 'count')) {
			@spawnGroups[@spawnGroup] += @mob['count'];
		} else {
			@spawnGroups[@spawnGroup]++;
		}
	}
	@spawns = associative_array();
	foreach(@spawnGroup: @count in @spawnGroups) {
		@spawns[@spawnGroup] = array_rand(@waves['arena'][@spawnGroup], min(@waves['duplicate'] * @count, array_size(@waves['arena'][@spawnGroup])), false);
	}
	foreach(@spawnGroup in @spawns) {
		foreach(@spawn in @spawnGroup) {
			spawn_entity('AREA_EFFECT_CLOUD', 1, @spawn, closure(@cloud) {
				set_entity_spec(@cloud, array(radius: 0.1, particle: 'LAVA', duration: (@secondsTillSpawn - 1) * 20));
			});
		}
	}
	@waves['spawns'] = @spawns;
}

proc _waves_spawn_mobs(@waves) {
	@waves['bounty'] = null;
	@spawns = @waves['spawns'];
	do {
		foreach(@i: @mob in @waves['mobs']) {
			if(is_array(@mob)) {
				@spawnGroup = 'spawns';
				if(array_index_exists(@mob, 'pos')) {
					@spawnGroup = @mob['pos'];
				}
				@count = 1;
				if(array_index_exists(@mob, 'count')) {
					@count = @mob['count'];
				}
				do {
					@loc = @spawns[@spawnGroup][(@waves['duplicate'] * (@i + @count)) % array_size(@spawns[@spawnGroup])];
					if(array_index_exists(@mob, 'custom')) {
						include('../../../entities/custom.library/'.@mob['custom'].'.ms');
						@temp = call_proc('_'.@mob['custom'].'_spawn', @loc, array(pauseTicks: 60));
						if(entity_type(@temp) === 'ARMOR_STAND') {
							set_entity_invulnerable(@temp, true);
							@waves['entities'][] = @temp;
							@waves['mobCount']++;
						}
					} else {
						_spawn_entity(@mob, @loc, null, closure(@e) {
							set_entity_saves_on_unload(@e, false);
							set_entity_ai(@e, false);
							set_mob_effect(@e, 'glowing', 0, 999, true, false);
							set_entity_invulnerable(@e, true);
						});
					}
				} while(--@count > 0)
			} else {
				@loc = @spawns['spawns'][(@waves['duplicate'] * (@i + 1)) % array_size(@spawns['spawns'])];
				spawn_entity(@mob, 1, @loc, closure(@e) {
					set_entity_saves_on_unload(@e, false);
					set_entity_ai(@e, false);
					set_mob_effect(@e, 'glowing', 0, 999, true, false);
					set_entity_invulnerable(@e, true);
				});
			}
		}
	} while(--@waves['duplicate'])
	@waves['mobs'] = array();
}

proc _waves_activate_mobs(@waves) {
	foreach(@e in @waves['entities']) {
		try {
			@vehicle = get_entity_vehicle(@e);
			if(!@vehicle || is_entity_living(@vehicle)) {
				set_entity_ai(@e, true);
			}
			set_mob_effect(@e, 'glowing', 0, 0);
			set_entity_invulnerable(@e, false);
			@randTarget = array_get_rand(@waves['players']);
			if(pmode(@randTarget) !== 'SPECTATOR') {
				try(set_mob_target(@e, puuid(@randTarget)))
			}
		} catch(BadEntityException @ex){
			console('Mob dead on round start.');
		}
	}
	if(@waves['bounty']) {
		set_mob_name(@waves['bounty'], color('green').'BOUNTY');
	}
}

proc _waves_tick_mobs(@waves) {
	// Check random entity if it is still in region
	@entities = @waves['entities'];
	@r = array_rand(@entities)[0];
	if(!entity_exists(@entities[@r]) || !sk_region_contains(@waves['region'], entity_loc(@entities[@r]))) {
		array_remove(@entities, @r);
	} else if(entity_type(@entities[@r]) !== 'ARMOR_STAND' && is_entity_living(@entities[@r])) {
		@target = get_mob_target(@entities[@r]);
		if(!@target) {
			@randTarget = array_get_rand(@waves['players']);
			if(pmode(@randTarget) !== 'SPECTATOR') {
				set_mob_target(@entities[@r], puuid(@randTarget));
			}
		}
	}
	if(@waves['bounty']
	&& entity_exists(@waves['bounty'])
	&& get_mob_name(@waves['bounty']) === color('green').'BOUNTY') {
		spawn_particle(location_shift(entity_loc(@waves['bounty']), 'up'), array(
			particle: 'VILLAGER_HAPPY',
			count: 2,
			xoffset: 0.5,
			zoffset: 0.5,
			yoffset: 1.0));
	}
}

proc _get_random_wave(@waves, @waveNum, @random) {
	@mobPool = @waves['mobPool'];
	@modifierPool = @waves['modifierPool'];
	@maxWaves = @waves['config']['maxWaves'];
	@free = false;
	if(!@random) {
		@random = res_create_resource('RANDOM', time());
		@free = true;
	}
	@wave = array(mobs: array(), subtitle: '');
	@numTypes = if(@waveNum >= 5 && @waveNum <= @maxWaves - 5, 2, 1);
	if(@waveNum == @maxWaves) {
		@mobData = @waves['config']['finalboss'];
		@mobData['count'] = 1;
		@wave['mobs'][] = @mobData;
		@numTypes = 0;
	}
	@passenger = false;
	@modifier = '';
	while(@numTypes > 0) {
		@tier = 1;
		@count = @waveNum % 5;
		if(@waveNum >= @maxWaves - 5) {
			@count += 5;
			@tier = 1 + integer(@waveNum / 5);
		} else if(!@count) {
			@tier = 2 + integer(@waveNum / 5);
			if(!array_index_exists(@mobPool, @tier)) {
				@tier -= 1;
			}
			@numTypes = 0;
		} else if(!@wave['mobs']) {
			@tier = 1 + integer(@waveNum / 5);
		} else if(array_size(@wave['mobs']) == 1) {
			@tier = max(1, integer(@waveNum / 5));
		}
		if(!@mobPool[@tier]) {
			@tier += 1;
		}
		@mobData = array_remove(@mobPool[@tier], integer(srand(@random) * array_size(@mobPool[@tier])));
		if(!@count) { // miniboss
			@mobData['count'] = 1;
		} else if(!@wave['mobs']) { // first tier
			@mobData['count'] = @count;
		} else { // second tier
			@mobData['count'] = @count + 4;
		}
		if(@modifierPool
		&& !@modifier
		&& array_index_exists(@mobData, 'type')
		&& @waveNum >= 5
		&& (@maxWaves - @waveNum) / array_size(@modifierPool) * srand(@random) < 1.0) {
			@modifier = array_remove(@modifierPool, integer(srand(@random) * array_size(@modifierPool)));
			switch(@modifier) {
				case 'tiny':
					@mobData['attributes'] = array(GENERIC_SCALE: 0.25);
				case 'small':
					@mobData['attributes'] = array(GENERIC_SCALE: 0.5);
				case 'big':
					@mobData['attributes'] = array(GENERIC_SCALE: 1.5);
				case 'huge':
					@mobData['attributes'] = array(GENERIC_SCALE: 2.0);
				case 'invisible':
					@mobData['effects'] = array(invisibility: array(strength: 0, seconds: -1, ambient: false));
				case 'infested':
					@mobData['effects'] = array(infested: array(strength: 0, seconds: -1, ambient: false));
				case 'oozing':
					@mobData['effects'] = array(oozing: array(strength: 0, seconds: -1, ambient: false));
				case 'weaving':
					@mobData['effects'] = array(weaving: array(strength: 0, seconds: -1, ambient: false));
				case 'wind_charged':
					@mobData['effects'] = array(wind_charged: array(strength: 0, seconds: -1, ambient: false));
				case 'fast':
					@mobData['effects'] = array(speed: array(strength: 0, seconds: -1, ambient: false));
				case 'silent':
					@mobData['silent'] = true;
				case 'passenger':
					if(@count) {
						@passenger = true;
					} else {
						@modifier = '';
					}
				case 'doubled':
					@mobData['count'] *= 2;
				case 'stacked':
					@count = max(2, array_remove(@mobData, 'count'));
					@clone = @mobData[];
					@vehicle = @mobData;
					while(@count > 1) {
						@rider = @clone[];
						@vehicle['rider'] = @rider;
						@vehicle = @rider;
						@count--;
					}
					@mobData['count'] = 1;
				case 'arrows':
					@mobData['targetnear'] = array(
						range: 16,
						projectile: 'ARROW',
						interval: rand(1000, 5000),
						count: rand(1, 8));
			}
		}
		if(@mobData['count'] < 3) {
			@mobData['pos'] = 'center';
		}
		if(@wave['mobs'] && @passenger) {
			@vehicle = @mobData[];
			@vehicle['rider'] = array_remove(@wave['mobs'], 0);
			@vehicle['count'] = @vehicle['rider']['count'];
			@mobData['count'] -= @vehicle['count'];
			@wave['mobs'][] = @vehicle;
		}
		@wave['mobs'][] = @mobData;
		@numTypes--;
	}

	@wave['effects'] = array(regeneration: array(strength: 1, seconds: 6));

	if(@waveNum == @maxWaves) {
		@wave['music'] = 'music_disc.tears';
	} else if(@waveNum == @maxWaves - 5) {
		@wave['music'] = 'music.credits';
	} else if(@waveNum % 5 == 0) {
		@wave['music'] = 'music.game';
	}

	@wave['bossbar'] = color('bold').'Wave '.@waveNum.' / '.@maxWaves
			.if(@modifier, ' "'._to_upper_camel_case(@modifier).'"', '');
	console(@wave['bossbar']);
	if(@waveNum == @maxWaves && @waves['config']['finalboss']['type'] === 'WITHER') {
		@wave['bossbar'] = '';
	}

	if(@free) {
		res_free_resource(@random);
	}
	return(@wave);
}