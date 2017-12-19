switch(@action) {
case 'load':
	bind(entity_damage, array('id': @player.'damage'), array('type': 'PLAYER', 'cause': 'ENTITY_ATTACK'), @e, @p = @player) {
		if(@e['damager'] == @p) {
			@weapon = pinv(@p, null);
			if(@weapon && @weapon['name'] == 'STONE_HOE') {
				modify_event('amount', 2);
				set_mob_effect(@e['id'], 20, 1, 7);
			}
		}
	}

	bind(player_interact, array('id': @player.'web'), array('player': @player, 'button': 'right', 'item': 291), @e, @pvp) {
		spawn_falling_block(_relative(ploc(), 'up', 2), 30, _get_vector(pfacing(), 1.5, 0));
	}
	
	bind(entity_change_block, array('id': @player.'webhit'), array('from': 0, 'to': 30), @event, @pvp) {
		cancel();
		consume();
		@loc = @event['location'];
		foreach(@player in array_merge(array_keys(@pvp['players']), @pvp['spectators'])) {
			psend_block_change(@player, @loc, 30);
		}
	}
	
	bind(item_pickup, array('id': @player.'webpickup'), array('item': 30), @event) {
		set_peffect(player(), 2, 1, 3);
	}

case 'unload':
	unbind(@player.'damage');
	unbind(@player.'web');
	unbind(@player.'webhit');
	unbind(@player.'webpickup');

}
