proc _spawn_seat() {
	@seatLoc = location_shift(ploc(), 'up', 1.6)
	@seatLoc['yaw'] += 90;
	@seatLoc['pitch'] = 0;
	@seat = spawn_entity('ITEM_DISPLAY', 1, @seatLoc, closure(@e){
		set_entity_spec(@e, array(item: array(name: 'ANVIL')));
		set_entity_saves_on_unload(@e, false);
		set_display_entity(@e, array(
			transformation: array(
				scale: array(x: 0.6, y: 0.6, z: 0.6),
				translation: array(x: 0.0, y: -0.3, z: 0.0))));
	})[0];
	set_entity_rider(@seat, puuid());
	return(@seat);
}