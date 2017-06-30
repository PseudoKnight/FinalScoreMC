array_push(@pvp['binds'], @id.'shotgunshoot');
bind(player_interact, array('id': @id.'shotgunshoot'), array('item': 332, 'button': 'right'), @e, @id) {
	@pvp = import('pvp'.@id);
	if(!array_index_exists(@pvp['players'], player()) || pinfo(player(), 6) != @e['item']) {
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
	set_timeout(300, closure(){
		foreach(@snowball in @entities) {
			try {
				entity_remove(@snowball);
			} catch(BadEntityException @ex) {
				// this ball hit something
			}
		}
	});
	play_sound(ploc(), array('sound': 'ZOMBIE_WOOD', 'pitch': 1.5, 'volume': 2));
	play_sound(ploc(), array('sound': 'EXPLODE', 'pitch': 2, 'volume': 2));
	_weapon_cooldown(player(), 1000, 'SLIME_BALL', closure(){
		play_sound(ploc(), array('sound': 'PISTON_RETRACT', 'pitch': 1.5));
	});
}
array_push(@pvp['binds'], @id.'shotgundamage');
bind(entity_damage, array('id': @id.'shotgundamage'), array('type': 'PLAYER', 'cause': 'PROJECTILE'), @e, @id) {
	if(array_index_exists(@e, 'shooter') // missing in special cases
	&& length(@e['shooter']) < 17) {
		@pvp = import('pvp'.@id);
		if(array_index_exists(@pvp['players'], @e['shooter'])) {
			@weapon = pinv(@e['shooter'], null);
			if(!is_null(@weapon) && @weapon['type'] == 341) {
				modify_event('amount', 7);
			}
		}
	}
}
