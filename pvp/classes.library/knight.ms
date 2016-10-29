switch(@action) {
case 'load':
	bind(player_death, array('id': @player.'death'), array('player': @player), @event) {
		@horse = get_entity_vehicle(puuid())
		if(@horse && entity_type(@horse) == 'HORSE') {
			damage_entity(@horse, 20)
		}
	}

	bind(vehicle_leave, array('id': @player.'dismount'), array('vehicletype': 'HORSE'), @e, @player) {
		if(@player == @e['player']) {
			try {
				entity_remove(@e['vehicle']);
				set_pinv(@player, array(2: array('type': 383, 'data': 100, 'meta': array('display': 'STEED'))));
			} catch(BadEntityException @e) {
				# horse die?
			}
		}
	}

case 'unload':
	unbind(@player.'death');
	unbind(@player.'dismount');

}
