switch(@action) {
case 'load':
	bind(vehicle_leave, array('id': @player.'dismount'), array('vehicletype': 'HORSE'), @e, @player) {
		if(@player == @e['player']) {
			set_timeout(50, closure(){
				try {
					entity_remove(@e['vehicle']);
					set_pinv(@player, array(2: array('type': 383, 'data': 100, 'meta': array('display': 'STEED'))));
				} catch(BadEntityException @e) {
					# horse die?
				}
			});
		}
	}

case 'unload':
	unbind(@player.'dismount');

}
