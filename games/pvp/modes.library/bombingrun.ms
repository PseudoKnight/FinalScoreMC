proc _interval(@pvp, @id) {
	_pvp_bomb_spawn(@pvp);
}

proc _pvp_bomb_spawn(@pvp, @loc) {
	if(!@loc) {
		@loc = @pvp['arena']['bombloc'];
	}
	if(!@pvp['bombholder'] && (!array_index_exists(@pvp, 'bomb') || !entity_exists(@pvp['bomb']))) {
		@pvp['bomb'] = drop_item(@loc, array(name: @pvp['arena']['bomb']), false);
		set_timeout(1, closure(try(set_entity_velocity(@pvp['bomb'], null))));
	}
}

proc _is_bomb(@pvp, @item) {
	if(!@pvp['running']) {
		return(false);
	}
	if(!is_null(@item)) {
		if(@item['name'] == @pvp['arena']['bomb']) {
			return(true);
		}
	}
	return(false);
}

// Override
proc _stats_table() {
	return(array(
		array('kills', 2, '-------'),
		array('deaths', 2, '---------'),
		array('scores', 1, '--------'),
		array('damage', 3, '------')
	));
}

proc _load_mode(@pvp) {
	@pvp['binds'][] = bind('item_pickup', null, null, @event, @pvp) {
		if(array_index_exists(@pvp['players'], player())
		&& _is_bomb(@pvp, @event['item'])) {
			@pvp['bombholder'] = player();
			set_pinv(player(), array(-106: @event['item'], 102: array(name: 'GOLDEN_CHESTPLATE')));
			modify_event('item', null);
			play_sound(ploc(player()), array(sound: 'ENTITY_ENDERMAN_TELEPORT', pitch: 2), player());
			set_peffect(player(), 'GLOWING', 0, 9999, true, false);
			title('', 'Take the bomb to the enemy target!', 0, 20, 20);
		}
	}

	@pvp['binds'][] = bind('entity_damage', null, array(type: 'DROPPED_ITEM'), @event, @pvp) {
		if(array_index_exists(@pvp, 'bomb')
		&& @event['id'] == @pvp['bomb']) {
			// ensure it is destroyed before spawning a new one
			set_timeout(100, closure() {
				if(!entity_exists(@event['id'])) {
					array_remove(@pvp, 'bomb');
				}
			});
		}
	}

	@pvp['binds'][] = bind('item_drop', null, array(itemname: @pvp['arena']['bomb']), @event, @pvp) {
		if(array_contains(sk_current_regions(), @pvp['arena']['region'])) {
			@pvp['bomb'] = @event['id'];
			@pvp['bombholder'] = null;
		}
	}

	@pvp['binds'][] = bind('item_spawn', null, array(itemname: @pvp['arena']['bomb']), @event, @pvp) {
		if(sk_region_contains(@pvp['arena']['region'], @event['location'])) {
			set_entity_glowing(@event['id'], true);
		}
	}

	@pvp['binds'][] = bind('player_move', null, null, @event, @pvp) {
		if(@pvp['bombholder'] == player()) {
			@regions = sk_current_regions();
			@team = null;
			if(array_contains(@regions, @pvp['arena']['bombtarget'][0])) {
				@team = 1;
			} else if(array_contains(@regions, @pvp['arena']['bombtarget'][1])) {
				@team = 0;
			}
			if(!is_null(@team)) {
				@item = pinv(player(), -106);
				if(@item && @item['name'] == @pvp['arena']['bomb'] || ptake_item(array(name: @pvp['arena']['bomb']))) {
					set_pinv(player(), -106, null);
					@bind = bind('entity_damage', null, array(type: 'PLAYER'), @event, @damager = player(), @pvp) {
						if(array_index_exists(@pvp['players'], @event['player'])) {
							set_entity_killer(@event['id'], @event['player']);
							_stats_damage(@damager, @event['player'], @event['amount'], @pvp);
						}
					}
					explosion(location_shift(@event['to'], 'up'), 3, true);
					unbind(@bind);
					@pvp['team'][@team]['score']++;
					set_pscore('bombs', @pvp['arena']['team'][@team]['name'], @pvp['team'][@team]['score'], @pvp['id']);
					if(@team != @pvp['players'][player()]['team']) {
						@pTeam = @pvp['players'][player()]['team'];
						_pvp_msg(@pvp, color('gray').'[PVP] '
							.@pvp['arena']['team'][@pTeam]['color'].player().color('r').' blew up the wrong target?!');
					} else {
						@pvp['stats'][player()]['scores']++;
						_pvp_msg(@pvp, color('gray').'[PVP] '
							.@pvp['arena']['team'][@team]['color'].player().color('r').' blew up the target!');
					}
					if(array_index_exists(@pvp['arena'], 'rsoutputscore')) {
						set_block(@pvp['arena']['rsoutputscore'][@team], 'REDSTONE_TORCH');
						set_timeout(1000, closure(){
							set_block(@pvp['arena']['rsoutputscore'][@team], 'TORCH');
						});
					}
					_pvp_check_objectives(@pvp['id']);
				}
				@pvp['bombholder'] = null;
				set_pinv(player(), 102, array(name: 'IRON_CHESTPLATE', meta: array(enchants: array(fire_protection: array(elevel: 1)))));
			} else {
				spawn_particle(location_shift(@event['to'], 'up'),'CAMPFIRE_COSY_SMOKE');
			}
		}
	}

	@pvp['bombholder'] = null;
}