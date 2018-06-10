bind('player_interact_entity', null, array('clicked': 'MINECART'), @event) {
	if(!sk_can_build(entity_loc(@event['id'])) || !psneaking()) {
		die();
	}
	cancel();
	@item = pinv(player(), null);
	@minecart = entity_spec(@event['id']);
	if(is_null(@item)) {
		@posing = import(player().'posing');
		if(@posing) {
			die();
		}

		export(player().'posing', true);
		
		@originalPitch = pfacing()[1];
		@originalOffset = @minecart['offset'];
		
		set_interval(50, closure(){
			if(!ponline(player()) || !psneaking() || !entity_exists(@event['id'])) {
				clear_task();
				export(player().'posing', null);
				return();
			}
			
			@newPitch = pfacing()[1];
			set_entity_spec(@event['id'], array('offset': integer(@originalOffset - (@newPitch - @originalPitch))));
		});
		
	} else if(@minecart['block'] == 'AIR' && material_info(@item['type'], 'isBlock')) {
		if(!@item['meta'] && @item['data'] == 0) {
			@item['qty'] -= 1;
			set_entity_spec(@event['id'], array('block': @item['name']));
			if(!@item['qty']) {
				@item = null;
			}
			set_pinv(player(), null, @item);
		} else {
			play_effect(entity_loc(@event['id']), 'SMOKE', array('id': 4));
		}
	}
}

bind('vehicle_destroy', array('priority': 'MONITOR'), array('vehicletype': 'MINECART'), @event) {
	if(!is_cancelled()) {
		@minecart = entity_spec(@event['vehicle']);
		if(@minecart['block'] != 'AIR') {
			// make sure no plugin has cancelled this
			set_timeout(50, closure(){
				if(!entity_exists(@event['vehicle'])) {
					drop_item(location_shift(@event['location'], 'up', @minecart['offset'] / 20), array('name': @minecart['block']));
				}
			});
		}
	}
}
