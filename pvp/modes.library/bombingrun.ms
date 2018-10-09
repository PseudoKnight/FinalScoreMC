proc _pvp_bomb_spawn(@id, @loc) {
	@pvp = import('pvp'.@id);
	if(!@pvp['running']) {
		return();
	}
	if(!is_array(@loc)) {
		@loc = @pvp['arena']['bombloc'];
	}
	if(!array_index_exists(@pvp, 'bomb') || !entity_exists(@pvp['bomb'])) {
		@pvp['bomb'] = drop_item(@loc, array('name': @pvp['arena']['bomb']), 0);
	}
	queue_delay('30000', @id.'bomb');
	queue_push(closure(_pvp_bomb_spawn(@id)), @id.'bomb');
}

proc _is_bomb(@id, @item) {
	@pvp = import('pvp'.@id);
	if(!@pvp['running']) {
		return();
	}
	if(!is_null(@item)) {
		if(@item['name'] == @pvp['arena']['bomb']) {
			return(true);
		}
	}
	return(false);
}

_pvp_bomb_spawn(@id);
@pvp['bombholder'] = null;

@pvp['binds'][] = @id.'bombpickup';
bind('item_pickup', array('id': @id.'bombpickup'), null, @event, @id, @pvp) {
	if(array_index_exists(@pvp['players'], player())
	&& _is_bomb(@id, @event['item'])) {
		queue_clear(@id.'bomb');
		@pvp['bombholder'] = player();
		set_pinv(player(), array(-106: @event['item'], 102: array('name': 'GOLDEN_CHESTPLATE')));
		modify_event('item', null);
	}
}

@pvp['binds'][] = @id.'protectdrops';
bind('entity_damage', array('id': @id.'protectdrops'), array('type': 'DROPPED_ITEM'), @event, @pvp) {
	if(array_contains(sk_regions_at(entity_loc(@event['id'])), @pvp['arena']['region'])
	&& entity_spec(@event['id'])['itemstack']['name'] == @pvp['arena']['bomb']) {
		cancel();
	}
}

@pvp['binds'][] = @id.'bombdrop';
bind('item_drop', array('id': @id.'bombdrop'), array('itemname': @pvp['arena']['bomb']), @event, @pvp) {
	if(array_contains(sk_current_regions(), @region)) {
		@pvp['bomb'] = @event['id'];
		@pvp['bombholder'] = null;
	}
}

@pvp['binds'][] = @id.'firedancer';
bind('player_move', array('id': @id.'firedancer'), null, @event, @pvp, @id) {
	if(@pvp['bombholder'] == @event['player']) {
		@regions = sk_current_regions(@event['player']);
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
				explosion(location_shift(@event['to'], 'up'), 3, true);
				@pvp['team'][@team]['score']++;
				set_pscore('bombs', @pvp['arena']['team'][@team]['name'], @pvp['team'][@team]['score'], @id);
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
			spawn_particle(location_shift(@event['to'], 'up'), array('particle': 'FLAME', 'speed': 0.1));
		}
	}
}
