array_push(@pvp['binds'], @id.'shotgunshoot')
bind(player_interact, array('id': @id.'shotgunshoot'), array('item': 332, 'button': 'right'), @e, @id) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()), die())
	cancel()
	@entities = array()
	for(@i = 0, @i < 8, @i++) {
		@entities[@i] = shoot_projectile(player(), 'SNOWBALL')
		@v = entity_velocity(@entities[@i])
		set_entity_velocity(@entities[@i], array(@v['x'] * 3.4 + ((rand(3) - 1)), @v['y'] * 3.4 + ((rand(3) - 1)), @v['z'] * 3.4 + ((rand(3) - 1))))
	}
	set_timeout(300, closure(){
		foreach(@snowball in @entities) {
			try(entity_remove(@snowball));
		}
	});
	play_sound(ploc(), array('sound': 'ZOMBIE_WOOD', 'pitch': 1.5, 'volume': 2));
	play_sound(ploc(), array('sound': 'EXPLODE', 'pitch': 2, 'volume': 2));
	_weapon_cooldown(player(), 1000, 'SLIME_BALL', closure(){
		play_sound(ploc(), array('sound': 'PISTON_RETRACT', 'pitch': 1.5));
	});
}
array_push(@pvp['binds'], @id.'shotgundamage')
bind(entity_damage, array('id': @id.'shotgundamage'), array('type': 'PLAYER', 'cause': 'PROJECTILE', 'world': 'custom'), @e, @id) {
	if(ponline(@e['shooter'])) {
		@pvp = import('pvp'.@id)
		if(array_index_exists(@pvp['players'], @e['shooter'])) {
			@weapon = pinv(@e['shooter'], null);
			if(!is_null(@weapon) && @weapon['type'] == 341) {
				modify_event('amount', 8);
			}
		}
	}
}