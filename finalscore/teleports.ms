@requests = get_value('session.requests')
if(!@requests, @requests = array(), clear_value('session.requests'))
export('requests', @requests)

# Teleport protection from falling through blocks
bind('player_teleport', null, null, @event,
	if(_horizontal_distance(@event['to'], @event['from']) > 96) { # 7+ chunk view distance
		set_timeout(50, closure(
			refresh_chunk(@event['to'][3], @event['to'])
			set_ploc(array(@event['to'][0], @event['to'][1] - 1, @event['to'][2], @event['to'][3]))
			set_timeout(950, closure(
				if((@event['to'][1] - 1) > ploc()[1]) {
					set_ploc(array(@event['to'][0], @event['to'][1] - 1, @event['to'][2], @event['to'][3]))
					console('Adjusted '.player().'\'s location after teleport.')
				}
			))
		))
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