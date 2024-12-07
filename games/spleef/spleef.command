<!
	description: Spleef is a game where players must be the last player standing above the floor to win.
	Players are given pickaxes to dig out blocks underneath other players to win.
	Features player-configurable floor blocks and various player-toggleable options.
	Relevant locations are hard-coded in the @cfg.;

	requiredExtensions: SKCompat;
	requiredProcs: _add_activity() and _remove_activity() procedures to keep a list of all current activities on server.
		_regionmsg() proc to broadcast to players only within a region.
		_acc_add() proc to reward players with coins.;
>
register_command('spleef', array(
	description: 'Starts, joins, or sets the floor of a Spleef game.',
	usage: '/spleef <join|start|floor>',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			@chars = @args[-1];
			return(array_filter(array('join', 'floor', 'start'), closure(@index, @string) {
				return(length(@chars) <= length(@string) && equals_ic(@chars, substr(@string, 0, length(@chars))));
			}));
		}
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}

		@world = 'custom';
		@cfg = array(
			'region': array(
				'wrapper': 'spleef',
				'arena': 'spleef-arena',
				'floor': 'spleef-floor',
				'material': 'spleef-materials'
			),
			'warp': array(
				'lobby': array(-482.5, 53, -646, @world),
				'material': array(-490, 53, -634, @world)
			),
			'sign': array(
				array(-487, 56, -646, @world),
				array(-487, 55, -646, @world),
				array(-487, 56, -647, @world),
				array(-487, 55, -647, @world)
			),
			'option': array(
				'knockback': array(-488, 56, -656, @world),
				'platforming': array(-488, 56, -654, @world),
				'obstacles': array(-488, 56, -652, @world),
				'speed': array(-488, 56, -658, @world),
				'jump': array(-488, 56, -660, @world),
				'material': array(-488, 54, -642, @world),
				'material_alt': array(-488, 54, -638, @world),
				'snake': array(-488, 56, -662, @world),
				'checkered': array(-488, 56, -664, @world),
				'rooms': array(-488, 56, -666, @world),
				'creepers': array(-488, 56, -668, @world),
			)
		);


		if(pworld() != @world){
			die(color('gold').'You can only run this on '.@world.'.');
		}

		switch(@args[0]) {
			case 'join':
				@nextspleef = import('nextspleef');
				if(!@nextspleef) {
					@nextspleef = array();
				}
				if(array_index_exists(@nextspleef, player())) {
					die(color('green').'[Spleef] '.color('r').'You are already in the next Spleef match.');
				}
				@nextspleef[player()] = 1;
				export('nextspleef', @nextspleef);
				set_sign_text(@cfg['sign'][0], array_keys(@nextspleef));
				if(array_size(@nextspleef) > 4) {
					set_sign_text(@cfg['sign'][1], array_keys(@nextspleef)[cslice(4, array_size(@nextspleef) - 1)]);
				}
				if(array_size(@nextspleef) > 8) {
					set_sign_text(@cfg['sign'][2], array_keys(@nextspleef)[cslice(8, array_size(@nextspleef) - 1)]);
				}
				if(array_size(@nextspleef) > 12) {
					set_sign_text(@cfg['sign'][3], array_keys(@nextspleef)[cslice(12, array_size(@nextspleef) - 1)]);
				}

			case 'floor':
				@key = 'material';
				if(array_size(@args) == 2 && @args[1] == 'alt') {
					@key = 'material_alt';
				}
				set_ploc(@cfg['warp']['material']);
				msg(color('yellow').'Pick a block.');
				bind('player_interact', null, array('player': player()), @event, @cfg, @key) {
					if(@event['block'] && sk_region_contains(@cfg['region']['material'], @event['location'])) {
						@blocktype = get_block(@event['location']);
						@blockdata = get_blockdata_string(@event['location']);
						set_blockdata_string(@cfg['option'][@key], @blockdata);
						msg(color('green').'[Spleef] '.color('r').'You have selected '.color('6').@blocktype.'.');
						cancel();
						unbind();
						set_ploc(@cfg['warp']['lobby']);
					}
				}

			case 'start':
				@nextspleef = import('nextspleef');
				@currentspleef = import('currentspleef');
				if(!@nextspleef) {
					@nextspleef = array();
				}
				if(!@currentspleef) {
					@currentspleef = array();
				} else {
					die(color('green').'[Spleef] '.color('r').'Match currently in progress.');
				}

				foreach(@player in array_keys(@nextspleef)) {
					if(!ponline(@player) || !array_contains(sk_current_regions(@player), @cfg['region']['wrapper'])) {
						array_remove(@nextspleef, @player);
					}
				}

				if(array_size(@nextspleef) < 2 && player() !== 'PseudoKnight') {
					die(color('green').'[Spleef] '.color('r').'There are not enough players in this match!');
				}


				@reward = array_size(@nextspleef) - 1;
				@currentspleef = @nextspleef;
				@nextspleef = array();
				@spleefsettings = array('counter': 0);
				export('reward', @reward);
				export('nextspleef', @nextspleef);
				export('currentspleef', @currentspleef);
				export('spleefsettings', @spleefsettings);
				_add_activity('currentspleef', 'Classic Spleef');
				set_sign_text(@cfg['sign'][0], array());
				set_sign_text(@cfg['sign'][1], array());
				set_sign_text(@cfg['sign'][2], array());
				set_sign_text(@cfg['sign'][3], array());

				_regionmsg(@cfg['region']['wrapper'], color('green').'[Spleef] '.color('r').'Match starting in 3 seconds...');
				@region = sk_region_info(@cfg['region']['floor'], @world)[0];

				@mat = get_blockdata_string(@cfg['option']['material']);
				@matAlt = get_blockdata_string(@cfg['option']['material_alt']);
				@knockback = reg_match('lit\\=true', get_blockdata_string(@cfg['option']['knockback']));
				@platforming = reg_match('lit\\=true', get_blockdata_string(@cfg['option']['platforming']));
				@obstacles = reg_match('lit\\=true', get_blockdata_string(@cfg['option']['obstacles']));
				@speed = reg_match('lit\\=true', get_blockdata_string(@cfg['option']['speed']));
				@jump = reg_match('lit\\=true', get_blockdata_string(@cfg['option']['jump']));
				@snake = reg_match('lit\\=true', get_blockdata_string(@cfg['option']['snake']));
				@checkered = reg_match('lit\\=true', get_blockdata_string(@cfg['option']['checkered']));
				@rooms = reg_match('lit\\=true', get_blockdata_string(@cfg['option']['rooms']));
				@creepers = reg_match('lit\\=true', get_blockdata_string(@cfg['option']['creepers']));

				#Given two blocks, iterates through all the blocks inside the cuboid, and calls the
				#user defined function on them. The used defined procedure should accept 3 parameters,
				#the x, y, and z coordinates of the block.
				proc _iterate_cuboid(@b1, @b2, @proc_name, @world, @mat, @matAlt) {
					for(@x = min(@b1[0], @b2[0]), @x <= max(@b1[0], @b2[0]), @x++) {
						for(@y = min(@b1[1], @b2[1]), @y <= max(@b1[1], @b2[1]), @y++) {
							for(@z = min(@b1[2], @b2[2]), @z <= max(@b1[2], @b2[2]), @z++) {
								call_proc(@proc_name, @x, @y, @z, @world, @mat, @matAlt);
							}
						}
					}
				}

				set_timeout(1000, closure(){
					if(@rooms) {
						#dungeon rooms
						@dungeonOptions = array(
							default: array(
								roof: false,
								empty: 'air',
								divider: 'air',
								maxRoomHeight: 2,
								extraDoorChance: 1.0,
								wall: @matAlt,
								column: if(@obstacles, @matAlt, 'air'),
								floor: if(@platforming, array(@mat, 'air'), @mat)),
							floors: if(@checkered, 
								array(array(roomTypes: array(one: array(chance: 0.5), two: array(chance: 0.5)))),
								array(array(roomTypes: associative_array()))),
							rooms: array(
								one: associative_array(),
								two: array(
									floor: if(@platforming, array(@matAlt, 'air'), @matAlt),
									wall: @mat,
									column: if(@obstacles, @mat, 'air'))));
						_generator_create('dungeon', @dungeonOptions, 'spleef-dungeon', @world, 0, closure(@start, @end, @spawns) {
							@cfg['spawns'] = @spawns[0];
							foreach(@spawn in @spawns[0]) {
								set_blockdata(location_shift(@spawn, 'down'), @mat);
							}
						});
						return();
					} else if(@platforming) {
						#platforming
						if(@checkered) {
							proc _setfloor(@x, @y, @z, @world, @mat, @matAlt) {
								if(rand(2)) {
									@chosenMat = @mat;
									if((floor(abs(@x) / 6) + floor(abs(@z) / 6)) % 2 == 0) {
										@chosenMat = @matAlt;
									}
									set_blockdata_string(array(@x, @y, @z, @world), @chosenMat,  false);
								} else {
									set_block(array(@x, @y, @z, @world), 'AIR', false);
								}
							}
						} else {
							proc _setfloor(@x, @y, @z, @world, @mat, @matAlt) {
								if(rand(2)) {
									set_blockdata_string(array(@x, @y, @z, @world), @mat,  false);
								} else {
									set_block(array(@x, @y, @z, @world), 'AIR', false);
								}
							}
						}
					}  else {
						#regular floor
						if(@checkered) {
							proc _setfloor(@x, @y, @z, @world, @mat, @matAlt) {
								@chosenMat = @mat;
								if((floor(abs(@x) / 6) + floor(abs(@z) / 6)) % 2 == 0) {
									@chosenMat = @matAlt;
								}
								set_blockdata_string(array(@x, @y, @z, @world), @chosenMat, false);
							}
						} else {
							proc _setfloor(@x, @y, @z, @world, @mat, @matAlt) {
								set_blockdata_string(array(@x, @y, @z, @world), @mat, false);
							}
						}
					}
					_iterate_cuboid(@region[0], @region[1], '_setfloor', @world, @mat, @matAlt);
				});

				set_timeout(2000, closure(){
					foreach(@player in array_keys(@currentspleef)) {
						set_pmode(@player, 'SURVIVAL');
					}
					#random obstacles
					if(@rooms) {
						return();
					} else if(@obstacles) {
						proc _setwalls(@x, @y, @z, @world) {
							@rand = rand(100);
							if(@rand < 5) {
								set_block(array(@x, @y, @z, @world), 'STONE_BRICKS', false);
								set_block(array(@x, @y + 1, @z, @world), 'STONE_BRICKS', false);
							} else if(@rand < 6) {
								set_block(array(@x, @y, @z, @world), 'MOSSY_STONE_BRICKS', false);
								set_block(array(@x, @y + 1, @z, @world), 'MOSSY_STONE_BRICKS', false);
							} else if(@rand < 7) {
								set_block(array(@x, @y, @z, @world), 'CRACKED_STONE_BRICKS', false);
								set_block(array(@x, @y + 1, @z, @world), 'CRACKED_STONE_BRICKS', false);
							} else if(get_block(array(@x, @y, @z, @world)) !== 'AIR') {
								set_block(array(@x, @y, @z, @world), 'AIR', false);
								set_block(array(@x, @y + 1, @z, @world), 'AIR', false);
							}
						}
						#clear walls if random obstacles is turned off
					} else {
						proc _setwalls(@x, @y, @z, @world) {
							if(get_block(array(@x, @y, @z, @world)) !== 'AIR') {
								set_block(array(@x, @y, @z, @world), 'AIR', false);
								set_block(array(@x, @y + 1, @z, @world), 'AIR', false);
							}
						}
					}
					// uh this might not be the right variable order... where is @mat
					_iterate_cuboid(array(@region[0][0], @region[0][1] + 1, @region[0][2]), array(@region[1][0], @region[1][1] + 1, @region[1][2]), '_setwalls', @world);
				});

				set_timeout(3000, closure(){
					foreach(@i: @player in array_keys(@currentspleef)){
						if(!ponline(@player) || !array_contains(sk_current_regions(@player), @cfg['region']['wrapper'])) {
							array_remove(@currentspleef, @player);
							continue();
						}
						if(array_index_exists(@cfg, 'spawns')) {
							set_ploc(@player, @cfg['spawns'][(@i + 1) % array_size(@cfg['spawns'])]);
						} else {
							@location = array(@region[0][0] - rand(sqrt((@region[0][0] - @region[1][0]) ** 2)), @region[0][1], @region[0][2] - rand(sqrt((@region[0][2] - @region[1][2]) ** 2)));
							# check if they are spawning into a block
							if(get_block(array(@location[0], @location[1] + 1, @location[2], @world)) !== 'AIR') {
								set_block(array(@location[0], @location[1] + 1, @location[2], @world), 'AIR', false);
								set_block(array(@location[0], @location[1] + 2, @location[2], @world), 'AIR', false);
							}
							# check if they are spawning over air
							if(get_block(array(@location[0], @location[1], @location[2], @world)) === 'AIR') {
								set_blockdata_string(array(@location[0], @location[1], @location[2], @world), @mat, false);
							}
							set_ploc(@player, array(@location[0] + 0.5, @location[1] + 0.5, @location[2] + 0.5, @world));
						}
						set_pinv(@player, 0,
							array('name': 'DIAMOND_PICKAXE', 'qty': 1, 'meta': array(
								'enchants': array('efficiency': 40),
								'display': color('green').'SUPERPICK',
							))
						);
						if(@speed) {
							set_peffect(@player, 'SPEED', 1, 9999, true, false);
						}
						if(@jump) {
							set_peffect(@player, 'JUMP_BOOST', 3, 9999, true, false);
						}
					}

					if(@creepers) {
						@creeperLoc = @region[0][];
						@creeperLoc[0] -= 20;
						@creeperLoc[1] += 3;
						@creeperLoc[2] -= 20;
						foreach(@i in range(24)) {
							_spawn_entity('speedycreeper', @creeperLoc)
						}
					}

					if(@knockback) {
						sk_region_flag(@world, 'spleef-arena', 'pvp', 'allow');
					} else {
						sk_region_flag(@world, 'spleef-arena', 'pvp', 'deny');
					}

					proc _fall_block(@loc) {
						@block = get_block(@loc);
						@entityLoc = @loc[];
						@entityLoc[0] += 0.5;
						@entityLoc[2] += 0.5;
						if(@block != 'AIR') {
							set_block(@loc, 'AIR');
							spawn_falling_block(@entityLoc, @block);
						}
						@entityLoc[1] += 1;
						spawn_particle(@entityLoc, array('particle': 'CLOUD', 'count': 4, 'speed': 0.01));
						play_sound(@entityLoc, array('sound': 'ENTITY_CREEPER_PRIMED', 'pitch': 2));
					}

					@worminterval = '';
					if(@snake) {
						@wormLoc = @region[0][];
						@wormLoc[0] -= 20;
						@wormLoc[2] -= 20;
						@targetLoc = array();
						@wormSleep = array(array_size(@currentspleef) - 2);
						@worminterval = set_interval(200, closure(){
							@count = array_size(@currentspleef);
							if(!@count) {
								clear_task();
							} else if(!@targetLoc) {
								@player = array_rand(@currentspleef, 1)[0];
								@targetLoc[0] = array_normalize(ploc(@player))[0..3];
								@targetLoc[0][0] = round(@targetLoc[0][0]);
								@targetLoc[0][1] = @wormLoc[1];
								@targetLoc[0][2] = round(@targetLoc[0][2]);
							} else if(@wormSleep[0] > 0) {
								@wormSleep[0]--;
							} else {
								@wormSleep[0] = @count - 2;
								@xDist = abs(@targetLoc[0][0] - @wormLoc[0]);
								@zDist = abs(@targetLoc[0][2] - @wormLoc[2]);
								if(@xDist == 0 && @zDist == 0) {
									// eat all surrounding blocks and clear target
									@targetLoc[0][0] -= 1;
									_fall_block(@targetLoc[0]);
									@targetLoc[0][2] -= 1;
									_fall_block(@targetLoc[0]);
									@targetLoc[0][0] += 1;
									_fall_block(@targetLoc[0]);
									array_remove(@targetLoc, 0);
								} else {
									if(@xDist > @zDist) {
										if(@wormLoc[0] > @targetLoc[0][0]) {
											@wormLoc[0] -= 1;
										} else {
											@wormLoc[0] += 1;
										}
									} else {
										if(@wormLoc[2] > @targetLoc[0][2]) {
											@wormLoc[2] -= 1;
										} else {
											@wormLoc[2] += 1;
										}
									}
									_fall_block(@wormLoc);
								}
							}
						});
					}

					@spleefinterval = set_interval(500, closure(){
						@spleefsettings = import('spleefsettings');
						@currentspleef = import('currentspleef');
						@reward = import('reward');
						@spleefsettings['counter']++;

						foreach(@player in array_keys(@currentspleef)){
							if(!ponline(@player) || pworld(@player) != @world || !array_contains(sk_current_regions(@player), @cfg['region']['arena'])) {
								array_remove(@currentspleef, @player);
								export('currentspleef', @currentspleef);
								if(ponline(@player) && pworld() == @world) {
									_regionmsg(@cfg['region']['wrapper'], color('green').'[Spleef] '.display_name(@player).color('r').' was knocked out.');
									set_ploc(@player, @cfg['warp']['lobby']);
									clear_peffects(@player);
									_equip_kit(@player);
								}
							}
						}

						if(array_size(@currentspleef) <= 1 && (!array_index_exists(@currentspleef, 'PseudoKnight') || psneaking('PseudoKnight') == true)) {
							@winner = array_implode(array_keys(@currentspleef));
							if(@winner !== '') {
								_regionmsg(@cfg['region']['wrapper'], color('a').'[Spleef] '.display_name(@winner).color('r').' is the winner!');
								set_timeout(3000, closure(set_ploc(@winner, @cfg['warp']['lobby'])));
								clear_peffects(@winner);
								clear_pinv(@winner);
								set_pmode(@winner, 'ADVENTURE');
								_acc_add(@winner, @reward);
								tmsg(@winner, color('a').'[Spleef] '.color('r').@reward.' coins!');
							} else if(@snake) {
								_regionmsg(@cfg['region']['wrapper'], color('a').'[Spleef] '.color('r').'Snekey Sneke wins.');
							} else {
								_regionmsg(@cfg['region']['wrapper'], color('a').'[Spleef] '.color('r').'No one wins.');
							}
							unbind('spleef_break');
							@currentspleef = array();
							export('currentspleef', @currentspleef);
							_remove_activity('currentspleef');
							if(@worminterval) {
								clear_task(@worminterval);
							}
							clear_task();
							die();
						}

						foreach(@player in all_players(@world)){
							if(array_index_exists(@currentspleef, @player)) {
								continue();
							}
							if(ponline(@player) && pmode(@player) != 'SPECTATOR' && array_contains(sk_current_regions(@player), @cfg['region']['arena'])) {
								set_ploc(@player, @cfg['warp']['lobby']);
								tmsg(@player, color('green').'[Spleef] '.color('r').'Please do not interfere with a spleef match in progress.');
							}
						}
						export('spleefsettings', @spleefsettings);
					});

					bind('block_break', array('id': 'spleef_break'), null, @event, @cfg) {
						@currentspleef = import('currentspleef');
						if(array_index_exists(@currentspleef, player()) && !sk_region_contains(@cfg['region']['floor'], @event['location'])) {
							cancel();
						}
					}

				});

			default:
				msg(color('green').'[Spleef] Spleef is a game where you break blocks underneath other players so that they fall out of the arena. Last man standing wins.')
				msg(color('green').'[Spleef] '.color('r').'/spleef join '.color('gray').'Join the next match')
				msg(color('green').'[Spleef] '.color('r').'/spleef start '.color('gray').'Start the match')
				msg(color('green').'[Spleef] '.color('r').'/spleef floor '.color('gray').'Select the floor block')
		}
	}
));
