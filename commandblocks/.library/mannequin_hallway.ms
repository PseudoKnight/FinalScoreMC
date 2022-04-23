@loc = get_command_block();
@p = entities_in_radius(@loc, 20, 'PLAYER')[0];
set_interval(150, closure(){
	if(!ponline(@p) || !array_contains(sk_current_regions(@p), 'hallway')) {
		clear_task();
		die();
	}
	@loc = ploc(@p);
	foreach(@e in entities_in_radius(@loc, 16, 'ARMOR_STAND')) {
		try {
			@eLoc = entity_loc(@e);
			play_sound(@eLoc, array(sound: 'ENTITY_SILVERFISH_STEP', pitch: 0.5 + rand(), volume: 0.05));
			@dist = distance(@eLoc, @loc);
			@eLoc['yaw'] = get_yaw(@eLoc, @loc);
			set_entity_loc(@e, @eLoc);
			set_entity_spec(@e, array(poses: array(
				poseArmRight: array(
					max(-1.3, -0.25 - (16 / @dist) * 0.23),
					max(-0.2, 0 - (16 / @dist) * 0.035),
					-rand() * 0.1),
				poseHead: array(0.052, -0.012, rand() * 0.15),
				poseArmLeft: array(-0.328, -0.012, -rand() * 0.15)
			)));
		} catch (Exception @ex) {
			clear_task();
			die();
		}
	}
});