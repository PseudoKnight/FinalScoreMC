@requests = get_value('session.requests')
if(!@requests) {
	@requests = array()
} else {
	clear_value('session.requests')
}
export('requests', @requests)

# Teleport protection from falling through blocks
bind('player_teleport', null, null, @event) {
	if(_horizontal_distance(@event['to'], @event['from']) > 96) { # 7+ chunk view distance
		@loc = _relative(@event['to'], 'down')
		@block = get_block_at(@loc)
		if(@block[0] != '0') {
			set_timeout(1000, closure(){
				if(ploc()[1] < @loc[1]) {
					console('Adjusted '.player().'\'s location after teleport.')
					set_ploc(@loc)
				}
			})
		}
	}
}

bind('player_interact', null, array('item': 368, 'button': 'right'), @event) {
	if(pworld() == 'custom', cancel())
}