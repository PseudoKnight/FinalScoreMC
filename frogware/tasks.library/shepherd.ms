proc _fw_start_task(@secs) {
	@colors = reflect_pull('enum', 'DyeColor');
	@color = array_get_rand(@colors);
	_fw_msg(array(
		@color.color('r').' is the new black',
		'Shear the '.@color.color('r').' ones!',
		'I could use a new '.@color.color('r').' wool coat.',
		'Farmer bob needs your help. Get the '.@color.color('r').' wool.',
	));
	@count = min(_fw_totalplayers() * 24, 200);
	@region = sk_region_info('frogware', 'custom', 0);
	for(@i = 0, @i < @count, @i++) {
		spawn_entity('SHEEP', 1, _fw_loc(), closure(@entity) {
			set_entity_spec(@entity, array(color: array_get_rand(@colors)));
		});
	}
	if(!rand(4)) {
		_fw_mobs('wolf', 8);
	}
	bind('item_pickup', array(id: 'fwtask'), null, @e, @color) {
		if(_fw_player(@e['player']) && @e['item']['name'] == @color.'_WOOL') {
			if(_fw_changeteam(player(), 'winners')) {
				play_sound(ploc(), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), player());
			}
		}
	}
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			pgive_item(@p, array(name: 'SHEARS'));
		}
	}
	if(!rand(5)) {
		set_timeout(1000, closure(){
			@loc = _fw_loc();
			play_sound(@loc, array(sound: 'entity_witch_ambient', volume: 4, pitch: 1.2));
			foreach(@e in entities_in_radius(@loc, 20, 'SHEEP')) {
				set_mob_effect(@e, 'levitation', 1, 10);
			}
		});
	}
}

proc _fw_end_task(@secs) {
	_remove_region_entities('frogware');
}