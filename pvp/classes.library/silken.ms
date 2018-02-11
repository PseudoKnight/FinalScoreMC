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
		@item = pinv(player(), null);
		if(@item && pcooldown(@item['name']) == 0) {
			spawn_falling_block(location_shift(ploc(), 'up', 2), 30, get_vector(ploc(), 1.5));
			set_pcooldown(@item['name'], 8);
		}
	}
	
	bind(entity_change_block, array('id': @player.'webhit'), array('to': 30), @event, @pvp) {
		cancel();
		consume();
		if(@event['from'] == '0') {
			@loc = @event['location'];
			foreach(@player in array_merge(array_keys(@pvp['players']), @pvp['spectators'])) {
				psend_block_change(@player, @loc, 30);
			}
		}
	}
	
	bind(item_spawn, array('id': @player.'webdrop'), array('item': 30), @event, @pvp) {
		cancel();
		if(get_block_at(@event['location']) == '0:0') {
			foreach(@player in array_merge(array_keys(@pvp['players']), @pvp['spectators'])) {
				psend_block_change(@player, @event['location'], 30);
			}
		}
	}

case 'unload':
	unbind(@player.'damage');
	unbind(@player.'web');
	unbind(@player.'webhit');
	unbind(@player.'webdrop');

}
