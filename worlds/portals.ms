# Handle player portal travel between dimensions
bind('player_portal_travel', null, null, @event) {
	@from = @event['from'];
	if(!_is_survival_world(@from['world'])) {
		cancel();
	} else if(@event['type'] == 'END_PORTAL') {
		if(@from['world'] == 'outworld') {
			cancel();
			set_timeout(50, closure(){
				set_ploc(location_shift(get_spawn('outworld_the_end'), 'down'));
			});
		} else if(@from['world'] == 'outworld_the_end') {
			cancel();
			set_timeout(50, closure(){
				set_ploc(location_shift(get_spawn('outworld'), 'down'));
			});
		} else if(!string_ends_with(@from['world'], '_the_end')) {
			modify_event('to', location_shift(get_spawn('world_the_end'), 'up'));
			modify_event('creationallowed', false);
		}
	} else if(@event['type'] == 'NETHER_PORTAL') {
		if(@match = reg_match('^(.*)_nether$', @from['world'])) {
			@from['x'] *= 8;
			@from['z'] *= 8;
			@from['world'] = @match[1];
			modify_event('to', @from);
		} else {
			@from['x'] /= 8;
			@from['z'] /= 8;
			@from['world'] = @from['world'].'_nether';
			modify_event('to', @from);
		}
	}
}

# Handle entity portal travel between dimensions
bind('entity_portal_travel', null, null, @event) {
	@from = @event['from'];
	@to = @event['to'];
	if(!_is_survival_world(@from['world'])) {
		cancel();
		entity_remove(@event['id']);
	} else if(@to['world'] == 'world_nether') { // through nether portal
		if(@match = reg_match('^(.*)_nether$', @from['world'])) { // from nether
			@l = @from;
			@l['x'] *= 8;
			@l['z'] *= 8;
			@l['world'] = @match[1];
			modify_event('to', @l);
		} else { // to nether
			@l = @from;
			@l['x'] /= 8;
			@l['z'] /= 8;
			@l['world'] = @from['world'].'_nether';
			modify_event('to', @l);
		}
	} else if(@to['world'] == 'world_the_end') { // through end portal
		cancel();
		if(@match = reg_match('^(.*)_the_end$', @from['world'])) { // from end
			cancel();
			set_entity_loc(@event['id'], get_spawn(@match[1]));
		} else { // to end
			if(@from['world'] == 'outworld'){
				set_entity_loc(@event['id'], get_spawn('outworld_the_end'));
			} else {
				set_entity_loc(@event['id'], get_spawn('world_the_end'));
			}
		}
	}
}
