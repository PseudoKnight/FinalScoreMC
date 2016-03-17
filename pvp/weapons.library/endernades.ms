array_push(@pvp['binds'], @id.'endernades')
bind(player_teleport, array('id': @id.'endernades'), array('type': 'ENDER_PEARL'), @e, @id) {
	@pvp = import('pvp'.@id);
	if(!array_index_exists(@pvp['players'], player()), die());

	cancel();
	bind(entity_damage, array('id': 'endernade'), array('cause': 'ENTITY_EXPLOSION', 'type': 'PLAYER'), @e, @damager = @e['player'], @pvp) {
		_stats_damage(@damager, @e['player'], @e['amount'], @pvp);
	}
	explosion(@e['to'], 2, true);
	unbind('endernade');
}

array_push(@pvp['binds'], @id.'endernadesreload')
bind(player_interact, array('id': @id.'endernadesreload', 'priority': 'highest'), array('item': 368, 'button': 'right'), @e, @id) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()) || pinfo(player(), 6) != @e['item']) {
		die();
	}
	cancel()
	shoot_projectile(player(), 'ENDER_PEARL')
	play_sound(ploc(), array('sound': 'SHOOT_ARROW', 'pitch': 0.5))
	_weapon_cooldown(player(), 2500, 'MAGMA_CREAM', closure(){
		play_sound(ploc(), array('sound': 'IRONGOLEM_THROW'));
	});
}
