array_push(@pvp['binds'], @id.'fireball')
bind('player_interact', array('id': @id.'fireball'), array('item': 385, 'button': 'right'), @e, @id) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()) || pinfo(player(), 6) != @e['item']) {
		die();
	}
	cancel()
	@entity = shoot_projectile(player(), 'FIREBALL');

	play_sound(ploc(), array('sound': 'ENTITY_GHAST_SHOOT', 'volume': 2));
	_weapon_cooldown(player(), 1000, 'FIREWORK_CHARGE', closure(){
		play_sound(ploc(), array('sound': 'BLOCK_FIRE_EXTINGUISH', 'pitch': 1.5));
	});
}
