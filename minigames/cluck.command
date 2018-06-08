/*
	A chicken shooting arcade game.
	
	REQUIREMENTS:
	- WorldGuard plugin and SKCompat extension for regions.
	- _regionmsg() proc for messaging players within regions.
	- _clear_pinv() proc for clearing the inventory of a player.
	- _equip_kit() proc for resetting player inventory after they're done with the game.
	- _acc_add() proc for rewarding players with coins.
	- _remove_region_entities() proc for removing all entities within the given region.
*/
register_command('cluck', array(
	'description': 'A game of shooting chickens.',
	'usage': '/cluck [start] [player]',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			@scores = get_value('cluck');
			@top = @scores['top'];
			msg(color('bold').'TOP '.array_size(@top).' CLUCK PLAYERS (beta)');
			msg(color('gray').'Since '.@scores['date']);
			for(@i = 0, @i < array_size(@top), @i++) {
				msg(if(length(@top[@i]['score']) < 2, '0').@top[@i]['score'].' - '.@top[@i]['name']);
			}
		} else if(@args[0] == 'start') {
			if(!get_command_block()) {
				die();
			}
			@player = @args[1];
			
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
				));
			}
			
			proc _cluck_start(@cluck) {
				@cluck['state'] = 1;
				clear_pinv(@cluck['player']);
				set_pinv(@cluck['player'], array(0: array('name': 'BOW'), 1: array('name': 'ARROW', 'qty': 10)));
				set_plevel(@cluck['player'], 0);
				_cluck_startround(@cluck);
			}
			
			proc _cluck_end(@cluck) {
				queue_clear('cluck');
				_equip_kit(@cluck['player']);
				export('cluck', _cluck_defaults());
				unbind('cluckdamage');
				unbind('cluckclose');
			}
			
			proc _cluck_startround(@cluck) {;
				_regionmsg('cluck', 'Round '.@cluck['round']);
				bind(entity_damage, array('id': 'cluckdamage'), array('cause': 'PROJECTILE', 'type': 'CHICKEN', 'world': @cluck['world']), @event, @cluck) {
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
			
				set_block_at(@cluck['sound']['startround'], '69:13');
				set_timeout(100, closure(set_block_at(@cluck['sound']['startround'], '69:5')));
			
				queue_delay(2000, 'cluck');
				@spawn = closure(){
					@offset =  rand(10);
					@adult = rand(10);
					@angle = rand(100);
					@loc = @cluck['spawnloc'][];
					@loc[2] += @offset;
					@entityid = spawn_mob('CHICKEN', 1, @loc)[0];
					if(@adult) {
						play_sound(@loc, array('sound': 'CHICKEN_EGG_POP'));
					} else {
						set_mob_age(@entityid, -24000);
						play_sound(@loc, array('sound': 'CHICKEN_EGG_POP', 'pitch': 2));
					}
					set_entity_velocity(@entityid, array(0, 1.1, (@angle - 12.5 * @offset) * (@cluck['round'] / 1000)));
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
			
				# Did we not meet the required hit chickens? (or round 10)
				if(@cluck['hit'] < @cluck['count'] / 2 || @cluck['round'] == 10) {
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
			
					set_block_at(@cluck['sound']['gameover'], '69:13');
					set_timeout(100, closure(set_block_at(@cluck['sound']['gameover'], '69:5')));
			
				} else {
					set_block_at(@cluck['sound']['winround'], '69:13');
					set_timeout(100, closure(set_block_at(@cluck['sound']['winround'], '69:5')));
				}
			
				_remove_region_entities('cluck', array('DROPPED_ITEM', 'EXPERIENCE_ORB'));
				# Reset for the next round.
				if(!@cluck['player'] || @cluck['gameover'] || @cluck['round'] == 10) {
					@cluck = _cluck_defaults();
				} else {
					@cluck['round']++;
					@cluck['chickens'] = array();
					@cluck['hit'] = 0;
					bind(projectile_hit, array('id': 'cluckstart'), array('type': 'ARROW'), @event, @cluck) {
						if(@event['shooter'] == puuid(@cluck['player'])) {
							unbind();
							_cluck_startround(@cluck);
						}
					}
				}
				export('cluck', @cluck);
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
