switch(@action) {
case 'load':
	bind(entity_damage, array('id': @player.'damage'), array('type': 'PLAYER', 'cause': 'ENTITY_ATTACK'), @e, @p = @player) {
		if(@e['damager'] == @p) {
			@weapon = pinv(@p, null);
			if(@weapon && @weapon['type'] == 291) {
				modify_event('amount', 2);
				set_mob_effect(@e['id'], 20, 1, 7);
			}
		}
	}

	bind(player_interact, array('id': @player.'web'), array('player': @player, 'button': 'right', 'item': 291), @e, @pvp) {
		@loc = ptarget_space();
		foreach(@player in array_merge(array_keys(@pvp['players']), @pvp['spectators'])) {
			psend_block_change(@player, @loc, 30);
		}
	}

case 'unload':
	unbind(@player.'damage');
	unbind(@player.'web');

}
