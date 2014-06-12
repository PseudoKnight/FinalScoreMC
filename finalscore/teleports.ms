@requests = get_value('session.requests')
if(!@requests) {
	@requests = array()
} else {
	clear_value('session.requests')
}
export('requests', @requests)

# Teleport protection from falling through blocks
# Clear 'custom' world's player inventory
bind('player_teleport', null, null, @event) {
	@loc = _relative(@event['to'], 'down')
	@block = get_block_at(@loc)
	if(@block[0] != '0' 
	&& (@event['to']['world'] != @event['from']['world']
	|| _horizontal_distance(@event['to'], @event['from']) > 96)) { # 6+ chunk view distance
		set_timeout(1000, closure(){
			if(ploc()[1] < @loc[1]) {
				console('Adjusted '.player().'\'s location after teleport.')
				set_ploc(@loc)
			}
			if(@event['from']['world'] != 'custom'
			&& pworld() == 'custom') {
				_equip_park()
			}
		})
	}
}

bind('player_interact', null, array('item': 368, 'button': 'right'), @event) {
	if(pworld() == 'custom', cancel())
}