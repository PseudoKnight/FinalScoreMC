proc _class_load(@player, @pvp) {
	bind('vehicle_leave', array(id: @player.'dismount'), array(vehicletype: 'HORSE'), @e, @player) {
		if(@player == @e['player']) {
			set_timeout(1, closure(){
				try {
					entity_remove(@e['vehicle']);
					set_pcooldown(@player, 'HORSE_SPAWN_EGG', 2500 / 50);
					set_pinv(@player, 1, array(name: 'HORSE_SPAWN_EGG', meta: array(display: 'STEED')));
				} catch(BadEntityException @e) {
					# horse die?
				}
			});
		}
	}
}

proc _class_unload(@player, @pvp) {
	unbind(@player.'dismount');
}
