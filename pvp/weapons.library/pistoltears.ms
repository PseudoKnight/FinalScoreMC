array_push(@pvp['binds'], @id.'pistoltears')
bind(player_interact, array('id': @id.'pistoltears'), array('item': 370, 'button': 'right'), @e, @id) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()) || pinfo(player(), 6) != @e['item']) {
		die();
	}
	@entity = shoot_projectile(player(), 'ARROW');
	@v = entity_velocity(@entity);
	@v['x'] = (@v['x'] / @v['magnitude']) * 4;
	@v['y'] = (@v['y'] / @v['magnitude']) * 4;
	@v['z'] = (@v['z'] / @v['magnitude']) * 4;
	set_entity_velocity(@entity, @v);
	set_arrow_damage(@entity, 1.25);
	play_sound(ploc(), array('sound': 'ZOMBIE_WOOD', 'pitch': 2, 'volume': 2));
	_weapon_cooldown(player(), 2000, 'GOLD_NUGGET', closure(){
		play_sound(ploc(), array('sound': 'DOOR_OPEN', 'pitch': 2));
	});
}
