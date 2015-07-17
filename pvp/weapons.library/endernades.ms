array_push(@pvp['binds'], @id.'endernades')
bind(player_teleport, array('id': @id.'endernades'), array('type': 'ENDER_PEARL'), @e, assign(@id, @id)) {
	@pvp = import('pvp'.@id);
	if(!array_index_exists(@pvp['players'], player()), die());
	
	cancel();
	bind(entity_damage, array('id': 'endernade'), array('cause': 'ENTITY_EXPLOSION'), @e, @damage = @e['player'], @pvp = @pvp) {
		if(!is_null(@player = get_player_from_entity_id(@e['id']))) {
			_stats_damage(@damager, @player, @e['amount'], @pvp);
		}
	}
	explosion(@e['to'], 2, true);
	unbind('endernade');
}

array_push(@pvp['binds'], @id.'endernadesreload')
bind(player_interact, array('id': @id.'endernadesreload', 'priority': 'highest'), array('item': 368, 'button': 'right'), @e, assign(@id, @id)) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()), die())
	cancel()
	shoot_projectile(player(), 'ENDER_PEARL')
	play_sound(ploc(), array('sound': 'SHOOT_ARROW', 'pitch': 0.5))
	@item = pinv(player(), null)
	@item['qty'] -= 1
	if(@item['qty'] == 0) {
		set_pinv(array('null': null))
	} else {
		@item['type'] = 378
		@item['name'] = 'MAGMA_CREAM'
		set_pinv(array('null': @item))
		@slot = pinfo(player(), 15)
		set_timeout(1200, closure(){
				@item = pinv(player(), @slot)
				if(!is_null(@item) && @item['type'] == 378) {
				play_sound(ploc(), array('sound': 'IRONGOLEM_THROW'))
				@inv = array()
				@item['type'] = 368
				@item['name'] = 'ENDER_PEARL'
				@inv[@slot] = @item
				set_pinv(@inv)
			}
		})
	}
}