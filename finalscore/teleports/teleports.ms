@requests = get_value('session.requests');
if(!@requests) {
	@requests = associative_array();
} else {
	clear_value('session.requests');
}
export('requests', @requests);

# Main teleport handler
bind(player_teleport, null, null, @event) {
	if(@event['to']['world'] != @event['from']['world']
	&& _is_survival_world(@event['from']['world'])
	&& _is_survival_world(@event['to']['world'])) {
		try( # sometimes entity does not exist and causes an exception in get_entity_vehicle()
			@vehicle = get_entity_vehicle(puuid());
			if(entity_type(@vehicle) === 'HORSE') {
				set_timeout(1, closure(){
					try(
						set_entity_loc(@vehicle, @event['to']);
						set_timeout(50, closure(){
							set_entity_rider(@vehicle, puuid());
						});
					, # catch
						msg('Failed to teleport your horse with you. The chunk may have unloaded too quickly.');
						console('Failed to teleport horse.');
					);
				});
				die();
			}
		);
	}
	
	@loc = _relative(@event['to'], 'down');
	@block = get_block_at(@loc); # loads chunk to help prevent players falling through floor
	
	# take the rest off the overloaded teleportation event
	set_timeout(50, closure(){
		if(@block[0] !== '0' && # don't run this if the [to] location is in the air
		(@event['to']['world'] != @event['from']['world']
		|| _horizontal_distance(@event['to'], @event['from']) > 112)) { # 7+ chunk view distance
			# delay enough to compensate for a lag spike
			set_timeout(900, closure(){
				# workaround for player's falling through floors on teleport
				if(ploc()[1] < @loc[1]) {
					console('Adjusted '.player().'\'s location after teleport.');
					set_ploc(@loc);
				}
			});
		}
	});
}

# Block enderpearls
bind(player_interact, null, array('item': 368, 'button': 'right'), @event) {
	if(pworld() === 'custom', cancel())
}

# Main world_changed handler
bind(world_changed, null, null, @event) {
	if(@event['from'] !== 'custom'
	&& @event['to'] === 'custom') {
		# if teleporting to Frog Park
		set_timeout(200, closure(){
			_equip_park();
		});
	}
}