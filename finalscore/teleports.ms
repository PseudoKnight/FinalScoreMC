@requests = get_value('session.requests')
if(!@requests, @requests = array(), clear_value('session.requests'))
export('requests', @requests)

# Teleport protection from falling through blocks
bind('player_teleport', null, null, @event,
	if(_horizontal_distance(@event['to'], @event['from']) > 96) { # 7+ chunk view distance
		@loc = _relative(@event['to'], 'down')
		@block = get_block_at(@loc)
		if(@block != '0:0') {
			set_timeout(1000, closure(
				if(ploc()[1] < @loc[1]) {
					set_ploc(@loc)
					console('Adjusted '.player().'\'s location after teleport.')
				}
			))
		}
	}
)

# Outworld message
bind('world_changed', null, null, @e,
	if(@e['to'] == 'outworld'
	&& !array_contains(array('outworld_nether', 'outworld', 'outworld_the_end'), @e['from'])) {
		msg(color('k').'XX'.color('r').color('gold').color('bold').' Welcome to the outworld! '.color('r').color('k').'XX\n'
		.color('red').'This is a temporary world. Do not build or store anything permanent.')
	}
	if(phas_flight(), set_pflight(false))
)


bind('player_interact', null, array('item': 368, 'button': 'right'), @e,
	if(pworld() == 'custom', cancel())
)