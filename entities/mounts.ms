proc _direct_vehicle() {
	@vehicleType = entity_type(pvehicle());
	set_interval(250, closure(){
		try {
			@vehicle = pvehicle();
			if(!@vehicle || @vehicleType !== entity_type(@vehicle)) {
				clear_task();
				die();
			}
			@item = pinv(player(), null);
			if(@item && @item['name'] === 'CARROT_ON_A_STICK') {
				@vector = get_vector(ploc(), 2);
				@loc = entity_loc(@vehicle);
				@loc['x'] += @vector['x'];
				@loc['z'] += @vector['z'];
				set_mob_destination(@vehicle, @loc, 1.5);
			}
		} catch (PlayerOfflineException @ex) {
			clear_task();
		}
	});
}

/*
	Sitting on some (mostly) non-hostile animals.
 */
bind('player_interact_entity', null, array(hand: 'main_hand', clicked: '/(COW|MUSHROOM_COW|PANDA|POLAR_BEAR|SHEEP|SNIFFER|CHICKEN)/'), @event) {
	@item = pinv(player(), null);
	if(!pblocking() && @item && @item['name'] === 'CARROT_ON_A_STICK' && !get_leashholder(@event['id'])) {
		set_entity_rider(@event['id'], puuid());
		_direct_vehicle();
	}
}

/*
	Workaround for touch interface on bedrock clients, since these do not send interact entity packets for all entity types.
	Requires using an emote, which typically activates the geyser item swap workaround.
	If a valid entity is targeted, it'll ride that entity instead.
 */
 if(extension_exists('chgeyser')) {
	bind('item_swap', null, null, @event) {
		if(geyser_connected()) {
			@trace = ray_trace(4);
			if(@trace['entities']) {
				@entityTypes = array('COW', 'MUSHROOM_COW', 'PANDA', 'POLAR_BEAR', 'SHEEP', 'SNIFFER');
				foreach(@entity in @trace['entities']) {
					if(array_contains(@entityTypes, entity_type(@entity['uuid']))) {
						set_entity_rider(@entity['uuid'], puuid());
						_direct_vehicle();
						cancel();
						return();
					}
				}
			}
		}
	}
 }