array_push(@pvp['binds'], @id.'pistoltears')
bind(player_interact, array('id': @id.'pistoltears'), array('item': 370, 'button': 'right'), @e, @id) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()), die())
	@entity = shoot_projectile(player(), 'ARROW')
	@v = entity_velocity(@entity)
	set_entity_velocity(@entity, array(@v['x'] * 3, @v['y'] * 3, @v['z'] * 3))
	play_sound(ploc(), array('sound': 'ZOMBIE_WOOD', 'pitch': 2, 'volume': 2));
	_weapon_cooldown(player(), 2000, 'GOLD_NUGGET', closure(){
		play_sound(ploc(), array('sound': 'DOOR_OPEN', 'pitch': 2));
	});
}