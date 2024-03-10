<!
	description: A chicken shooting arcade game.;

	requiredExtensions: SKCompat, CHRegionChange;
	requiredProcs: _regionmsg() proc for messaging players within regions.
		_add_activity() and _remove_activity() procedures to keep a list of all current activities on server.
		_equip_kit() proc for resetting player inventory after they're done with the game.
		_acc_add() proc for rewarding players with coins.
		_remove_region_entities() proc for removing all entities within the given region.
>
register_command('cluck', array(
	description: 'A game of shooting chickens.',
	usage: '/cluck [start]',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			@scores = get_value('cluck');
			@top = @scores['top'];
			msg(color('bold').'TOP '.array_size(@top).' CLUCK PLAYERS (beta)');
			msg(color('gray').'Since '.@scores['date']);
			for(@i = 0, @i < array_size(@top), @i++) {
				msg(if(length(@top[@i]['score']) < 2, '0').@top[@i]['score'].' - '.@top[@i]['name']);
			}

		} else if(@args[0] == 'start') {
			@loc = get_command_block();
			if(!@loc) {
				die();
			}
			@player = _get_nearby_player(@loc, 3);
			if(!@player) {
				die();
			}
			
			proc _cluck_defaults() {
				@world = 'custom';
				return(array(
					'world': @world,
					'state': 0,
					'round': 1,
					'count': 10, # of chicken spawns
					'chickens': array(), # chicken entity ids to check if they're alive at round end
					'hit': 0, # num chickens hit
					'player': '',
					'gameover': 0,
					'score': 0, # cumulative hit chickens
					'sound': array(
						'gameover': array(-563, 55, -323, @world),
						'winround': array(-563, 58, -323, @world),
						'startround': array(-563, 52, -323, @world),
					),
					'spawnloc': array(-573.5, 63, -331.5, @world),
					'targetloc': array(-574, 66, -328, @world),
					'dispensers': array(
						array(-573.5, 70.5, -323.5, @world, -180, 0),
						array(-573.5, 70.5, -330.5, @world, 0, 0)
					),
					'target': null,
				));
			}
			
			proc _cluck_start(@cluck) {
				_add_activity('cluck', 'Cluck');
				@cluck['state'] = 1;
				clear_pinv(@cluck['player']);
				set_pinv(@cluck['player'], array(0: array('name': 'BOW'), 1: array('name': 'ARROW', 'qty': 10)));
				set_plevel(@cluck['player'], 0);

				bind('region_change', array(id: 'cluckregion'), null, @event, @cluck) {
					if(@event['player'] == @cluck['player'] && array_contains(@event['fromRegions'], 'cluck')) {
						_cluck_end(@cluck);
					}
				}

				bind('item_pickup', array(id: 'cluckpickup'), array(player: @cluck['player']), @event) {
					cancel();
				}

				_cluck_startround(@cluck);
			}
			
			proc _cluck_end(@cluck) {
				_remove_activity('cluck');
				queue_clear('cluck');
				_equip_kit(@cluck['player']);
				if(@cluck['target']) {
					set_block(@cluck['target'], 'AIR');
				}
				export('cluck', _cluck_defaults());
				unbind('cluckdamage');
				unbind('cluckstart');
				unbind('cluckregion');
				unbind('cluckpickup');
			}
			
			proc _cluck_startround(@cluck) {
				_regionmsg('cluck', 'Round '.@cluck['round']);
				bind('entity_damage', array('id': 'cluckdamage'), array('cause': 'PROJECTILE', 'type': 'CHICKEN', 'world': @cluck['world']), @event, @cluck) {
					if(array_contains(@cluck['chickens'], @event['id']) && @event['finalamount'] > 0) {
						if(@event['shooter'] != @cluck['player']) {
							cancel();
						} else {
							@cluck['score']++;
							@cluck['hit']++;
							pgive_item(@event['shooter'], array('name': 'ARROW'));
							set_plevel(@event['shooter'], @cluck['score']);
							array_remove_values(@cluck['chickens'], @event['id']);
						}
					}
				}
			
				set_block(@cluck['sound']['startround'], 'REDSTONE_TORCH');
				set_timeout(100, closure(set_block(@cluck['sound']['startround'], 'TORCH')));
			
				queue_delay(2000, 'cluck');
				@spawn = closure(){
					@adult = rand(10);
					@loc = null;
					@angle = null;
					@offset = null;
					@dispensed = false;
					if(rand() < 0.1) {
						@loc = array_get_rand(@cluck['dispensers']);
						@dispensed = true;
					} else {
						@offset =  rand(10);
						@angle = rand(100);
						@loc = @cluck['spawnloc'][];
						@loc[2] += @offset;
					}
					@entityid = spawn_entity('CHICKEN', 1, @loc)[0];
					if(@adult) {
						play_sound(@loc, array('sound': 'ENTITY_CHICKEN_EGG'));
					} else {
						set_mob_age(@entityid, -24000);
						play_sound(@loc, array('sound': 'ENTITY_CHICKEN_EGG', 'pitch': 2));
					}
					if(@dispensed) {
						set_entity_velocity(@entityid, get_vector(@loc, 0.5));
					} else {
						set_entity_velocity(@entityid, array(0, 1.1, (@angle - 12.5 * @offset) * (@cluck['round'] / 1000)));
					}
					set_entity_health(@entityid, 25);
					@cluck['chickens'][] = @entityid;
				}
				for(@i = @cluck['count'], @i > 0, @i--) {
					queue_delay(400 * rand(1, 12 - @cluck['round']), 'cluck');
					queue_push(@spawn, 'cluck');
				}
				queue_delay(5000, 'cluck');
				queue_push(closure(_cluck_endround(@cluck)), 'cluck');
			}
			
			proc _cluck_endround(@cluck) {
				unbind('cluckdamage');
				foreach(@chicken in @cluck['chickens']) {
					try {
						entity_remove(@chicken);
					} catch(BadEntityException @ex) {
						// ignore
					}
				}
				@player = @cluck['player'];
				@score = @cluck['score'];
			
				_regionmsg('cluck', color('yellow').@player.' hit '.@cluck['hit'].' chickens.');
			
				# Check for a round fail state
				# Did we not meet the required hit chickens? Is it final round? Are there not enough arrows left?
				if(@cluck['hit'] < @cluck['count'] / 2 || @cluck['round'] == 10 || phas_item(@player, array(name: 'ARROW')) < 2) {
					_regionmsg('cluck', color('yellow').color('bold').to_upper(@player).' GAMEOVER! Score: '.@score);
					@cluck['gameover'] = @cluck['round'];
					
					if(ponline(@player) && pworld(@player) === @cluck['world']) {
						clear_pinv(@player);
					}
			
					/*
						STATS
					*/
					@scores = get_value('cluck');
					@uuid = puuid(@player);
					@best = 0;
					if(array_index_exists(@scores, @uuid)) {
						@best = @scores[@uuid];
					}
					if(@score > @best) {
						if(@best > 0) {
							_regionmsg('cluck', color('bold').'You beat your personal best of '.@best.'!');
						}
						tmsg(@player, color('gold').'+ '.(@score - @best).' coins');
						_acc_add(@player, @score - @best);
						@scores[@uuid] = @score;
						@top = false;
						for(@i = 0, @i < 20, @i++) {
							if(@top && array_index_exists(@scores['top'], @i) && @scores['top'][@i]['uuid'] == @uuid) {
								array_remove(@scores['top'], @i);
							} else if(!@top && (!array_index_exists(@scores['top'], @i) || @scores['top'][@i]['score'] < @score)) {
								_regionmsg('cluck', color('bold').'Top 20 Score!');
								array_insert(@scores['top'], array('name': @player, 'score': @score, 'uuid': @uuid), @i);
								@top = true;
							}
						}
						if(array_size(@scores['top']) > 20) {
							array_remove(@scores['top'], 20);
						}
						store_value('cluck', @scores);
					}
					// END STATS
			
					set_block(@cluck['sound']['gameover'], 'REDSTONE_TORCH');
					set_timeout(100, closure(set_block(@cluck['sound']['gameover'], 'TORCH')));
			
				} else {
					set_block(@cluck['sound']['winround'], 'REDSTONE_TORCH');
					set_timeout(100, closure(set_block(@cluck['sound']['winround'], 'TORCH')));
				}
			
				_remove_region_entities('cluck', array('DROPPED_ITEM', 'EXPERIENCE_ORB'));
				# Reset for the next round.
				if(@cluck['gameover'] || @cluck['round'] == 10) {
					_cluck_end(@cluck);
				} else {
					@cluck['round']++;
					@cluck['chickens'] = array();
					@cluck['hit'] = 0;
					@loc = @cluck['spawnloc'][];
					@loc[1] += 3 + rand(3);
					@loc[2] += rand(10);
					set_block(@loc, 'TARGET');
					@cluck['target'] = @loc;
					bind('projectile_hit', array('id': 'cluckstart'), array(type: 'ARROW', hittype: 'BLOCK'), @event, @cluck, @loc) {
						if(@event['shooter'] == puuid(@cluck['player'])) {
							cancel();
							unbind();
							if(get_block(@event['hit']) == 'TARGET') {
								_cluck_startround(@cluck);
							} else {
								_cluck_end(@cluck);
							}
							set_block(@loc, 'AIR');
							spawn_particle(_center(@loc), 'EXPLOSION_LARGE');
							play_sound(@loc, array(sound: 'ENTITY_CHICKEN_EGG', pitch: 0.5));
							try(entity_remove(@event['id']))
						}
					}
				}
			}
		
			@cluck = import('cluck');
			if(!@cluck) {
				@cluck = _cluck_defaults();
				export('cluck', @cluck);
			} else if(@cluck['state']) {
				die();
			}
			
			@cluck['player'] = @player;
			_cluck_start(@cluck);

		} else if(@args[0] == 'reset') {
			if(!has_permission('group.moderator')) {
				die(color('gold').'No permission.');
			}
			store_value('cluck', array(
				'top': array(),
				'date': simple_date('MMM d'),
			));

		} else {
			return(false);
		}
	}
));
