switch(@action) {
case 'load':
	bind('vehicle_leave', array(id: @player.'dismount'), array(vehicletype: 'HORSE'), @e, @player) {
		if(@player == @e['player']) {
			set_timeout(1, closure(){
				try {
					entity_remove(@e['vehicle']);
					set_pinv(@player, 1, array(name: 'HORSE_SPAWN_EGG', meta: array(display: 'STEED')));
				} catch(BadEntityException @e) {
					# horse die?
				}
			});
		}
	}

case 'unload':
	unbind(@player.'dismount');

}
