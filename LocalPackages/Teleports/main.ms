# Teleport protection from falling through blocks
bind('player_teleport', null, null, @event,
  if(@event['to']['3'] != @event['from']['3']
    || _horizontal_distance(@event['to'], @event['from']) > 112) {
    set_timeout(500, closure(
      if((@event['to'][1] - 1) > ploc()[1])
      {
        set_ploc(array(@event['to'][0], @event['to'][1] - 1, @event['to'][2], @event['to'][3]))
        console('Adjusted '.player().'\'s location after teleport.')
      }
    ))
  }
)

# Outworld message
bind('world_changed', null, array('to': 'outworld'), @event,
  if(!array_contains(array('outworld_nether', 'outworld', 'outworld_the_end'), @event['from'])) {
    msg(color('k').'XX'.color('r').color('gold').color('bold').' Welcome to the outworld! '.color('r').color('k').'XX\n'
    .color('red').'This is a temporary world. Do not build or store anything permanent.')
  }
)


bind('player_interact', null, array('item': 368, 'button': 'right'), @e,
	if(pworld() == 'custom', cancel())
)