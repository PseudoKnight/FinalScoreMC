@requests = get_value('session.requests')
if(!@requests) {
	@requests = array()
} else {
	clear_value('session.requests')
}
export('requests', @requests)

# Teleport protection from falling through blocks
# Clear 'custom' world's player inventory
bind(player_teleport, null, null, @event) {
	if(_is_survival_world(@event['from']['world'])
	&& !_is_survival_world(@event['to']['world'])) {
		foreach(@item in pinv()) {
			if(!is_null(@item) && (@item['type'] == 401 || @item['type'] == 425)) {
				cancel()
				die(color('red').'Banner and firework metadata is not saved when leaving survival.'
					.' Please store them in a chest.')
				return()
			}
		}
		foreach(@item in penderchest()) {
			if(!is_null(@item) && (@item['type'] == 401 || @item['type'] == 425)) {
				cancel()
				die(color('red').'Banner and firework metadata is not saved when leaving survival.'
					.' Please move them from your enderchest to another chest.')
			}
		}
	}

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

bind(player_interact, null, array('item': 368, 'button': 'right'), @event) {
	if(pworld() == 'custom', cancel())
}

# Set player's bed spawn to their home in that world
bind(world_changed, null, null, @event) {
	set_timeout(150, closure(){
		@pdata = get_value('players', to_lower(@event['player']))
		if(array_index_exists(@pdata, 'homes')
		&& array_index_exists(@pdata['homes'], @event['to'])) {
			set_pbed_location(@pdata['homes'][@event['to']])
		} else {
			set_pbed_location(get_spawn(@event['to']))
		}
	})
}