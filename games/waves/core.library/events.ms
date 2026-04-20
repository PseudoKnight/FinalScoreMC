proc _bind_events(@waves) {
	@waves['binds'][] = bind('player_death', null, null, @event, @waves) {
		if(!array_contains(@waves['players'], player())) {
			die();
		}
		if(array_index_exists(@waves['config'], 'respawn')) {
			modify_event('keep_inventory', true);
			modify_event('drops', array());
		}
		if(array_index_exists(@waves['config'], 'coins')) {
			@waves['config']['coins'] /= 2;
		}
		@loc = ploc();
		if(@loc['y'] < -63) {
			@loc['y'] = -63;
		}
		export(player().'spawn', @loc);
		set_pmode('SPECTATOR');
	}

	@waves['binds'][] = bind('player_spawn', null, null, @event, @waves) {
		if(!array_contains(@waves['players'], player())) {
			die();
		}
		consume();
		@loc = import(player().'spawn');
		if(@loc) {
			modify_event('location', location_shift(@loc, 'up'));
			export(player().'spawn', null);
		}
	}

	@waves['binds'][] = bind('player_quit', null, null, @event, @waves) {
		if(array_contains(@waves['players'], player())) {
			set_ploc(@waves['arena']['lobby']);
			_waves_remove_player(player(), @waves);
		}
	}

	@waves['binds'][] = bind('player_teleport', null, null, @event, @waves) {
		if((@event['type'] === 'PLUGIN' || @event['type'] === 'SPECTATE')
		&& (@waves['world'] === @event['to']['world'] || @waves['world'] === @event['from']['world'])) {
			@from = sk_region_contains(@waves['region'], @event['from']);
			@to = sk_region_contains(@waves['region'], @event['to']);
			if(@from && !@to) {
				if(array_contains(@waves['players'], player())) {
					_waves_remove_player(player(), @waves);
				}
			} else if(@to && !array_contains(@waves['players'], player())) {
				if(!_waves_add_player(player(), @waves)) {
					cancel();
				} else if(@waves['wave'] > 1) {
					set_pmode('SPECTATOR');
				}
			}
		}
	}

	@waves['binds'][] = bind('creature_spawn', null, null, @event, @waves, @entities = @waves['entities']) {
		if(@event['type'] !== 'ARMOR_STAND' && sk_region_contains(@waves['world'], @waves['region'], @event['location'])) {
			if(!@waves['bounty'] && array_size(@entities) == 1) {
				@waves['bounty'] = @event['id'];
			} else if(get_mob_name(@event['id']) === color('green').'BOUNTY') {
				set_mob_name(@event['id'], '');
			}
			@entities[] = @event['id'];
			@waves['mobCount']++;
		}
	}

	@waves['binds'][] = bind('entity_damage', null, null, @event, @entities = @waves['entities'], @waves) {
		if(array_contains(@entities, @event['id'])) {
			if(array_index_exists(@event, 'damager') && array_contains(@entities, @event['damager'])
			&& (array_index_exists(@waves['config'], 'teamDamage') && !@waves['config']['teamDamage'])) {
				modify_event('amount', 0.0);
			} else if(@waves['bossbar']) {
				set_timeout(0, closure(){
					@health = 0.0;
					foreach(@i: @e in @entities) {
						try {
							@health += get_entity_health(@e);
						} catch (BadEntityException @ex) {
							array_remove(@entities, @i);
						}
					}
					if(@entities) {
						@health /= @waves['mobCount'];
						@health /= 100;
						try(update_bar('waves'.@waves['region'], double(@health)))
					} else {
						try(update_bar('waves'.@waves['region'], 0.0))
					}
				});
			}
		}
	}

	@waves['binds'][] = bind('entity_death', null, null, @event, @entities = @waves['entities'], @waves) {
		if(@waves['bounty'] && entity_exists(@waves['bounty'])) {
			if(@event['id'] === @waves['bounty']) {
				if(get_mob_name(@waves['bounty']) === color('green').'BOUNTY') {
					@event['drops'][] = array(name: 'EMERALD');
					modify_event('drops', @event['drops']);
				}
			} else {
				set_mob_name(@waves['bounty'], '');
			}
		}
		array_remove_values(@entities, @event['id']);
	}

	@waves['binds'][] = bind('player_interact_entity', null, array(clicked: 'WOLF'), @event, @entities = @waves['entities']) {
		if(get_mob_owner(@event['id'])) {
			array_remove_values(@entities, @event['id']);
		}
	}

	@waves['binds'][] = bind('player_interact_at_entity', array(priority: 'HIGHEST'), array(clicked: 'ARMOR_STAND'), @event, @waves) {
		if(sk_region_contains(@waves['world'], @waves['region'], entity_loc(@event['id']))) {
			if(entity_spec(@event['id'])['visible']) {
				cancel();
				@equipment = get_mob_equipment(@event['id']);
				@loc = location_shift(entity_loc(@event['id']), 'up');
				entity_remove(@event['id']);
				foreach(@item in @equipment) {
					drop_item(@loc, @item);
				}
			}
		}
	}

	@waves['binds'][] = bind('player_interact', null, array(button: 'right', itemname: 'NETHER_STAR'), @event, @waves) {
		if(sk_region_contains(@waves['world'], @waves['region'], ploc())) {
			foreach(@p in @waves['players']) {
				if(pmode(@p) === 'SPECTATOR') {
					set_ploc(@p, ploc());
					set_pmode(@p, 'ADVENTURE');
					ptake_item(array(name: 'NETHER_STAR'));
					die();
				}
			}
			msg('No spectator to resurrect!');
		}
	}
}