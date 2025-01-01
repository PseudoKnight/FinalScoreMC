@loc = get_command_block();
@p = null;
foreach(@p in entities_in_radius(@loc, 20, 'PLAYER')){
	if(pmode(@p) != 'SPECTATOR') {
		 break();
	}
}
if(!@p) {
	die();
}
@loc = location_shift(@loc, 'up', 3);
@husk = spawn_entity('HUSK', 1, @loc, closure(@entity) {
	set_entity_saves_on_unload(@entity, false);
	set_entity_persistence(@entity, false);
	set_entity_invulnerable(@entity, true);
	set_mob_equipment(@entity, array(boots: null, leggings: null, chestplate: null, helmet: null));
	set_entity_silent(@entity, true);
	set_mob_effect(@entity, 'speed', 0, 9999, true, false);
})[0];
set_interval(1000, closure(){
	if(!entity_exists(@husk)) {
		clear_task();
		die();
	}
	if(!ponline(@p)) {
		clear_task();
		die();
	}
	@loc = entity_loc(@husk);
	if(distance(ploc(@p), @loc) > 32) {
		clear_task();
		die();
	}
	set_mob_target(@husk, puuid(@p));
	if(!rand(3)) {
		play_sound(@loc, array(sound: 'ENTITY_HUSK_AMBIENT', pitch: 0.5, volume: 0.5));
	}
	spawn_particle(location_shift(@loc, 'up'), 'CAMPFIRE_SIGNAL_SMOKE');
	spawn_particle(location_shift(@loc, 'up', 2),'CAMPFIRE_SIGNAL_SMOKE');
});