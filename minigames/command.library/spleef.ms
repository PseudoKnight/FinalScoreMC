register_command('spleef', array(
	'description': 'Starts, joins, or sets the floor of a Spleef game.',
	'usage': '/spleef <join|start|floor>',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('join', 'floor', 'start'), @args[-1]));
		}
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
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
				'material': array(-492, 53, -634, @world)
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
				'snake': array(-488, 56, -662, @world),
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
				set_ploc(@cfg['warp']['material']);
				msg(color('yellow').'Pick a block.');
				bind(player_interact, null, array('player': player()), @event, @cfg) {
					if(@event['block'] != 0 && array_contains(sk_regions_at(@event['location']), @cfg['region']['material'])) {
						@blocktype = get_block_at(@event['location']);
						set_block_at(@cfg['option']['material'], @blocktype);
						msg(color('green').'[Spleef] '.color('r').'You have selected '.color('6').data_name(@blocktype).'.');
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
				@mat = get_block_at(@cfg['option']['material']);
		
				#Given two blocks, iterates through all the blocks inside the cuboid, and calls the
				#user defined function on them. The used defined procedure should accept 3 parameters,
				#the x, y, and z coordinates of the block.
				proc _iterate_cuboid(@b1, @b2, @proc_name, @mat) {
					for(@x = min(@b1[0], @b2[0]), @x <= max(@b1[0], @b2[0]), @x++) {
						for(@y = min(@b1[1], @b2[1]), @y <= max(@b1[1], @b2[1]), @y++) {
							for(@z = min(@b1[2], @b2[2]), @z <= max(@b1[2], @b2[2]), @z++) {
								call_proc(@proc_name, @x, @y, @z, @mat);
							}
						}
					}
				}
		
				set_timeout(1000, closure(){
					if(get_block_at(@cfg['option']['platforming']) === '124:0') {
						#platforming
						proc _setfloor(@x, @y, @z, @mat) {
							if(rand(2)) {
								set_block_at(@x, @y, @z, @mat, 'custom', false);
							} else {
								set_block_at(@x, @y, @z, 0, 'custom', false);
							}
						}
					} else {
						#regular floor
						proc _setfloor(@x, @y, @z, @mat) {
							if(get_block_at(@x, @y, @z) != @mat) {
								set_block_at(@x, @y, @z, @mat, 'custom', false);
							}
						}
					}
					_iterate_cuboid(@region[0], @region[1], '_setfloor', @mat);
				});
		
				set_timeout(2000, closure(){
					#random obstacles
					if(get_block_at(@cfg['option']['obstacles']) ==  '124:0') {
						proc _setwalls(@x, @y, @z) {
							if(assign(@rand, rand(100)) < 5) {
								set_block_at(array(@x, @y, @z, 'custom'), '98:0', false);
								set_block_at(array(@x, @y + 1, @z, 'custom'), '98:0', false);
							} else if(@rand < 6) {
								set_block_at(array(@x, @y, @z, 'custom'), '98:1', false);
								set_block_at(array(@x, @y + 1, @z, 'custom'), '98:1', false);
							} else if(@rand < 7) {
								set_block_at(array(@x, @y, @z, 'custom'), '98:2', false);
								set_block_at(array(@x, @y + 1, @z, 'custom'), '98:2', false);
							} else if(get_block_at(@x, @y, @z)[0] !== '0') {
								set_block_at(array(@x, @y, @z, 'custom'), 0, false);
								set_block_at(array(@x, @y + 1, @z, 'custom'), 0, false);
							}
						}
						#clear walls if random obstacles is turned off
					} else {
						proc _setwalls(@x, @y, @z) {
							if(get_block_at(@x, @y, @z)[0] !== '0') {
								set_block_at(array(@x, @y, @z, 'custom'), '0:0', false);
								set_block_at(array(@x, @y + 1, @z, 'custom'), '0:0', false);
							}
						}
					}
					_iterate_cuboid(array(@region[0][0], @region[0][1] + 1, @region[0][2]), array(@region[1][0], @region[1][1] + 1, @region[1][2]), '_setwalls');
		
					foreach(@player in array_keys(@currentspleef)) {
						set_pmode(@player, 'SURVIVAL');
					}
				});
		
				set_timeout(3000, closure(){
					foreach(@player in array_keys(@currentspleef)){
						if(!ponline(@player) || !array_contains(sk_current_regions(@player), @cfg['region']['wrapper'])) {
							array_remove(@currentspleef, @player);
							continue();
						}
						@location = array(@region[0][0] - rand(sqrt((@region[0][0] - @region[1][0]) ** 2)), @region[0][1], @region[0][2] - rand(sqrt((@region[0][2] - @region[1][2]) ** 2)));
						#check if they're spawning into a block
						if(get_block_at(array(@location[0], @location[1] + 1, @location[2]))[0] !== '0') {
							set_block_at(@location[0], @location[1] + 1, @location[2], 0, 'custom', false);
							set_block_at(@location[0], @location[1] + 2, @location[2], 0, 'custom', false);
						}
						#check if they're spawning over air
						if(get_block_at(@location[0], @location[1], @location[2])[0] === '0') {
							set_block_at(@location[0], @location[1], @location[2], @mat, 'custom', false);
						}
						set_ploc(@player, array(@location[0] + 0.5, @location[1], @location[2] + 0.5, @world));
						set_pinv(@player, 0,
							array('type': 278, 'qty': 1, 'enchants': array(array('etype': 'DIG_SPEED', 'elevel': 40)), 'meta': array('display': color('green').'SUPERPICK'))
						);
						if(get_block_at(@cfg['option']['speed']) ==  '124:0') {
							set_peffect(@player, 1, 1, 9999, true, false);
						}
						if(get_block_at(@cfg['option']['jump']) ==  '124:0') {
							set_peffect(@player, 8, 3, 9999, true, false);
						}
					}
		
					if(get_block_at(@cfg['option']['knockback']) === '124:0') {
						sk_region_flag('custom', 'spleef-arena', 'pvp', 'allow');
					} else {
						sk_region_flag('custom', 'spleef-arena', 'pvp', 'deny');
					}
					
					proc _fall_block(@loc) {
						@block = get_block_at(@loc);
						@entityLoc = @loc[];
						@entityLoc[0] += 0.5;
						@entityLoc[2] += 0.5;
						if(@block != '0:0') {
							set_block_at(@loc, 0);
							spawn_falling_block(@entityLoc, @block);
						}
						@entityLoc[1] += 1;
						play_effect(@entityLoc, 'CLOUD', array('particleCount': 4, 'speed': 0.01));
						play_sound(@entityLoc, array('sound': 'FUSE', 'pitch': 2));
					}
					
					@worminterval = '';
					if(get_block_at(@cfg['option']['snake']) === '124:0') {
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
		
						if(array_size(@currentspleef) <= 1 && (!array_index_exists(@currentspleef, 'PseudoKnight') || psneaking('PseudoKnight') == true)) {
							@winner = array_implode(array_keys(@currentspleef));
							if(@winner !== '') {
								_regionmsg(@cfg['region']['wrapper'], color('a').'[Spleef] '.display_name(@winner).color('r').' is the winner!');
								set_ploc(@winner, @cfg['warp']['lobby']);
								set_peffect(@winner, 1, 0, 0);
								set_peffect(@winner, 8, 0, 0);
								_clear_pinv(@winner);
								set_pmode(@winner, 'ADVENTURE');
								_acc_add(@winner, @reward);
								tmsg(@winner, color('a').'[Spleef] '.color('r').@reward.' coins!');
							} else if(get_block_at(@cfg['option']['snake']) === '124:0') {
								_regionmsg(@cfg['region']['wrapper'], color('a').'[Spleef] '.color('r').'Snekey Sneke wins.');
							} else {
								_regionmsg(@cfg['region']['wrapper'], color('a').'[Spleef] '.color('r').'No one wins.');
							}
							unbind('spleef_break');
							@currentspleef = array();
							export('currentspleef', @currentspleef);
							_remove_activity('currentspleef');
							clear_task();
							if(@worminterval) {
								clear_task(@worminterval);
							}
						}
		
						foreach(@player in array_keys(@currentspleef)){
							if(!ponline(@player) || pworld(@player) != @world || !array_contains(sk_current_regions(@player), @cfg['region']['arena'])) {
								array_remove(@currentspleef, @player);
								export('currentspleef', @currentspleef);
								_regionmsg(@cfg['region']['wrapper'], color('green').'[Spleef] '.display_name(@player).color('r').' was knocked out.');
								if(ponline(@player) && pworld() == @world) {
									set_ploc(@player, @cfg['warp']['lobby']);
									set_peffect(@player, 1, 0, 0);
									set_peffect(@player, 8, 0, 0);
									_clear_pinv(@player);
									set_pmode(@player, 'ADVENTURE');
								}
							}
						}
		
						foreach(@player in all_players('custom')){
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
		
					bind(block_break, array('id': 'spleef_break'), null, @event, @cfg) {
						@currentspleef = import('currentspleef');
						if(array_index_exists(@currentspleef, player()) && !array_contains(sk_regions_at(@event['location']), @cfg['region']['floor'])) {
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
