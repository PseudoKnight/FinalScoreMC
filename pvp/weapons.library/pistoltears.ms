array_push(@pvp['binds'], @id.'pistoltears')
bind(player_interact, array('id': @id.'pistoltears'), array('item': 370, 'button': 'right'), @e, @id) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()) || pinfo(player(), 6) != @e['item']) {
		die();
	}
	@entity = shoot_projectile(player(), 'ARROW')
	play_sound(ploc(), array('sound': 'ZOMBIE_WOOD', 'pitch': 2, 'volume': 2));
	_weapon_cooldown(player(), 2000, 'GOLD_NUGGET', closure(){
		play_sound(ploc(), array('sound': 'DOOR_OPEN', 'pitch': 2));
	});
}
