proc _pvp_bomb_spawn(@id, @loc) {
	@pvp = import('pvp'.@id);
	if(!@pvp['running']) {
		return();
	}
	if(!is_array(@loc)) {
		@loc = @pvp['arena']['bombloc'];
	}
	if(!array_index_exists(@pvp, 'bomb') || !entity_exists(@pvp['bomb'])) {
		@pvp['bomb'] = drop_item(@loc, array('name': @pvp['arena']['bomb']), false);
		set_timeout(50, closure(set_entity_velocity(@pvp['bomb'], null)));
	}
	queue_delay('15000', @id.'bomb');
	queue_push(closure(_pvp_bomb_spawn(@id)), @id.'bomb');
}

proc _is_bomb(@id, @item) {
	@pvp = import('pvp'.@id);
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

@pvp['binds'][] = @id.'bombpickup';
bind('item_pickup', array('id': @id.'bombpickup'), null, @event, @id, @pvp) {
	if(array_index_exists(@pvp['players'], player())
	&& _is_bomb(@id, @event['item'])) {
		queue_clear(@id.'bomb');
		@pvp['bombholder'] = player();
		set_pinv(player(), array(-106: @event['item'], 102: array('name': 'GOLDEN_CHESTPLATE')));
		modify_event('item', null);
		play_sound(ploc(player()), array('sound': 'ENTITY_ENDERMAN_TELEPORT', 'pitch': 2), player());
		set_peffect(player(), 'GLOWING', 0, 9999, true, false);
		title('', 'Take the bomb to the enemy base!', 0, 20, 20);
	}
}

@pvp['binds'][] = @id.'itemdamage';
bind('entity_damage', array('id': @id.'itemdamage'), array('type': 'DROPPED_ITEM'), @event, @pvp) {
	if(array_index_exists(@pvp, 'bomb')
	&& @event['id'] == @pvp['bomb']) {
		array_remove(@pvp, 'bomb');
		_pvp_bomb_spawn(@pvp['id']);
	}
}

@pvp['binds'][] = @id.'bombdrop';
bind('item_drop', array('id': @id.'bombdrop'), array('itemname': @pvp['arena']['bomb']), @event, @pvp) {
	if(array_contains(sk_current_regions(), @pvp['arena']['region'])) {
		@pvp['bomb'] = @event['id'];
		@pvp['bombholder'] = null;
	}
}

@pvp['binds'][] = @id.'bombspawn';
bind('item_spawn', array('id': @id.'bombspawn'), array('itemname': @pvp['arena']['bomb']), @event, @pvp) {
	if(array_contains(sk_regions_at(@event['location']), @pvp['arena']['region'])) {
		set_entity_glowing(@event['id'], true);
	}
}

@pvp['binds'][] = @id.'firedancer';
bind('player_move', array('id': @id.'firedancer'), null, @event, @pvp, @id) {
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
			if(@item && @item['name'] == @pvp['arena']['bomb'] || ptake_item(array('name': @pvp['arena']['bomb']))) {
				set_pinv(player(), -106, null);
				@bind = bind('entity_damage', null, array(type: 'PLAYER'), @event, @damager = player(), @pvp) {
					if(array_index_exists(@pvp['players'], @event['player'])) {
						_stats_damage(@damager, @event['player'], @event['amount'], @pvp);
					}
				}
				explosion(location_shift(@event['to'], 'up'), 3, true);
				unbind(@bind);
				@pvp['team'][@team]['score']++;
				set_pscore('bombs', @pvp['arena']['team'][@team]['name'], @pvp['team'][@team]['score'], @id);
				@pvp['stats'][player()]['scores']++;
				_pvp_msg(@pvp, color('gray').'[PVP] '
					.@pvp['arena']['team'][@team]['color'].player().color('r').' blew up the target!');
				if(array_index_exists(@pvp['arena'], 'rsoutputscore')) {
					set_block(@pvp['arena']['rsoutputscore'][@team], 'REDSTONE_TORCH');
					set_timeout(1000, closure(){
						set_block(@pvp['arena']['rsoutputscore'][@team], 'TORCH');
					})
				}
				_pvp_bomb_spawn(@id);
				_pvp_check_objectives(@id);
			}
			@pvp['bombholder'] = null;
			set_pinv(player(), 102, array('name': 'IRON_CHESTPLATE', 'meta': array('enchants': array('fire_protection': array('elevel': 1)))));
		} else {
			spawn_particle(location_shift(@event['to'], 'up'),'CAMPFIRE_COSY_SMOKE');
		}
	}
}

proc _stats_table() {
	return(array(
		array('kills', 2, '-------'),
		array('deaths', 2, '---------'),
		array('scores', 2, '--------'),
		array('damage', 3, '------')
	));
}

_pvp_bomb_spawn(@id);
@pvp['bombholder'] = null;