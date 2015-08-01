@requests = get_value('session.requests');
if(!@requests) {
	@requests = array();
} else {
	clear_value('session.requests');
}
export('requests', @requests);

# Main teleport handler
bind(player_teleport, null, null, @event) {
	@teleportHorse = false;
	if(_is_survival_world(@event['from']['world'])) {
		if(!_is_survival_world(@event['to']['world'])) {
			if(phas_item(425)) {
				cancel();
				die(color('red').'Banner metadata is not saved when leaving survival.'
					.' Please store them in a chest.');
			}
			foreach(@item in penderchest()) {
				if(!is_null(@item) && @item['type'] == 425) {
					cancel();
					die(color('red').'Banner metadata is not saved when leaving survival.'
						.' Please move them from your enderchest to another chest.');
				}
			}
			
		# Teleport horses along with rider if its crossworld
		} else if(@event['to']['world'] != @event['from']['world']) {
			try( # sometimes entity does not exist and causes an exception in get_entity_vehicle()
				@vehicle = get_entity_vehicle(puuid());
				if(entity_type(@vehicle) == 'HORSE') {
					set_timeout(50, closure(){
						set_entity_loc(@vehicle, @event['to']);
						set_timeout(50, closure(){
							set_entity_rider(@vehicle, puuid());
						});
					});
					die();
				}
			);
		}
	}
	
	@loc = _relative(@event['to'], 'down');
	@block = get_block_at(@loc); # loads chunk to help prevent players falling through floor
	
	if(@block[0] != '0' && # don't run this if the [to] location is in the air
	(@event['to']['world'] != @event['from']['world']
	|| _horizontal_distance(@event['to'], @event['from']) > 112)) { # 7+ chunk view distance
		set_timeout(1000, closure(){
		
			# workaround for player's falling through floors on teleport
			if(ploc()[1] < @loc[1]) {
				console('Adjusted '.player().'\'s location after teleport.');
				set_ploc(@loc);
			}
			
		});
	}
}

# Block enderpearls
bind(player_interact, null, array('item': 368, 'button': 'right'), @event) {
	if(pworld() == 'custom', cancel())
}

# Main world_changed handler
bind(world_changed, null, null, @event) {
	set_timeout(200, closure(){
		# if teleporting to Frog Park
		if(@event['from'] != 'custom'
		&& @event['to'] == 'custom') {
			_equip_park();
		}
	});
}