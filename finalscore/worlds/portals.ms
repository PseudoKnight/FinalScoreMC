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

# Prevent undesireable interdimensional travel
bind(entity_enter_portal, null, array('type': 'ENDER_DRAGON'), @event) {
	cancel();
}

# Prevent items/entities from being thrown through non-survival portals
bind(entity_enter_portal, null, array('type': '/^(?!PLAYER)\\w*/', 'world': '/(dev|custom)/'), @event) {
	entity_remove(@event['id']);
}
