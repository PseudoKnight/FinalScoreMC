@pvp['binds'][] = bind('player_interact', null, array(itemname: 'SNOWBALL', button: 'right'), @e, @pvp) {
	if(!array_index_exists(@pvp['players'], player()) || pinfo(player(), 6) != @e['item']['name']) {
		die();
	}
	cancel();
	@entities = array();
	for(@i = 0, @i < 8, @i++) {
		@entities[@i] = shoot_projectile(player(), 'SNOWBALL');
		@v = entity_velocity(@entities[@i]);
		@v['x'] = ((@v['x'] / @v['magnitude']) * 3.2) + ((rand() * 1.6) - 0.8);
		@v['y'] = ((@v['y'] / @v['magnitude']) * 3.2) + ((rand() * 1.6) - 0.8);
		@v['z'] = ((@v['z'] / @v['magnitude']) * 3.2) + ((rand() * 1.6) - 0.8);
		set_entity_velocity(@entities[@i], @v);
	}
	set_timeout(250, closure(){
		foreach(@snowball in @entities) {
			try {
				entity_remove(@snowball);
			} catch(BadEntityException @ex) {
				// this ball hit something
			}
		}
	});
	play_sound(ploc(), array(sound: 'ENTITY_ZOMBIE_ATTACK_WOODEN_DOOR', pitch: 1.5, volume: 2));
	play_sound(ploc(), array(sound: 'ENTITY_GENERIC_EXPLODE', pitch: 2, volume: 2));
	_weapon_cooldown(player(), 1100, 'SLIME_BALL', closure(){
		play_sound(ploc(), array(sound: 'BLOCK_PISTON_CONTRACT', pitch: 1.5));
	});
}
@pvp['binds'][] = bind('entity_damage', null, array(type: 'PLAYER', cause: 'PROJECTILE'), @e, @pvp) {
	if(array_index_exists(@e, 'shooter') // missing in special cases
	&& length(@e['shooter']) < 17) {
		if(array_index_exists(@pvp['players'], @e['shooter'])) {
			@weapon = pinv(@e['shooter'], null);
			if(!is_null(@weapon) && (@weapon['name'] == 'SNOWBALL' || @weapon['name'] == 'SLIME_BALL')) {
				modify_event('amount', 7);
			}
		}
	}
}
