# Handle player portal travel between dimensions
bind(player_portal_travel, null, null, @event) {
	if(!_is_survival_world(@event['from']['world'])) {
		cancel();
	} else if(@event['type'] == 'END_PORTAL') {
		@world = 'world_the_end';
		if(@event['from']['world'] == 'outworld') {
			@world = 'outworld_the_end';
		} else if(reg_match('_the_end$', @event['from']['world'])) {
			@world = 'world';
		}
		@loc = get_spawn(@world);
		// workaround credits screen bug
		if(@event['from']['world'] == 'world_the_end') {
			modify_event('to', @loc);
		} else {
			cancel();
		}
		// workaround spigot "moved wrongly" bug
		set_timeout(50, closure(){
			set_ploc(@loc);
		});
	} else if(@event['type'] == 'NETHER_PORTAL') {
		if(@match = reg_match('^(.*)_nether$', @event['from']['world'])) {
			@l = @event['from'];
			@l['x'] *= 8;
			@l['z'] *= 8;
			@l['world'] = @match[1];
			modify_event('to', @l);
		} else {
			@l = @event['from'];
			@l['x'] /= 8;
			@l['z'] /= 8;
			@l['world'] = @l['world'].'_nether';
			modify_event('to', @l);
		}
	}
}

# Handle entity portal travel between dimensions
bind(entity_portal_travel, null, null, @event) {
	@from = @event['from'];
	@to = @event['to'];
	if(!_is_survival_world(@from['world'])) {
		cancel();
		entity_remove(@event['id']);
	} else if(@to['world'] == 'world_nether') {
		@l = @from;
		@l['x'] /= 8;
		@l['z'] /= 8;
		@l['world'] = @from['world'].'_nether';
		modify_event('to', @l);
	} else if(@match = reg_match('^(.*)_nether$', @from['world'])) {
		@l = @from;
		@l['x'] *= 8;
		@l['z'] *= 8;
		@l['world'] = @match[1];
		modify_event('to', @l);
	} else if(@to['world'] == 'world_the_end') {
		cancel();
		if(@match = reg_match('^(.*)_the_end$', @from['world'])) {
			set_entity_loc(@event['id'], get_spawn(@match[1]));
		} else {
			set_entity_loc(@event['id'], get_spawn(@from['world'].'_the_end'));
		}
	}
}
