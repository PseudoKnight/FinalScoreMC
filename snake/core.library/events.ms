proc _snake_bind_events(@game) {
	bind(player_interact, array('id': 'snake-interact'), null, @event, @game) {
		if(array_index_exists(@game['snakes'], player())) {
			@snake = @game['snakes'][player()];
			if(!@snake['click']) {
				@turn = _snake_turn(@snake['top'], @snake['dir']);
				@snake['dir'] = array_get(@turn, if(@event['button'] == 'right', 1, 0));
				@snake['click'] = true;
			}
		}
	}

	bind(item_swap, array('id': 'snake-swap'), null, @event, @game) {
		if(array_index_exists(@game['snakes'], player())) {
			cancel();
			_snake_ability(player(), @game);
		}
	}

	bind(entity_explode, array('id': 'snake-explode'), array('type': 'PRIMED_TNT'), @event, @game) {
		if(array_contains(sk_regions_at(@event['location']), 'snake')) {
			array_remove_values(@game['tnt'], @event['id']);
			foreach(@block in @event['blocks']) {
				if(split(':', get_block_at(@block))[0] == '159') {
					foreach(@player: @snake in @game['snakes']) {
						if(@snake['loc'][0] == @block[0] && @snake['loc'][1] == @block[1] && @snake['loc'][2] == @block[2]) {
							_snake_kill(@player, @game);
						} else {
							set_block_at(@block, 0, false);
						}
					}
				}
			}
		}
	}
	
	bind(inventory_open, array('id': 'snake-inventory'), null, @event, @game) {
		if(array_index_exists(@game['snakes'], player())) {
			cancel();
		}
	}
}

proc _snake_unbind_events() {
	unbind('snake-interact');
	unbind('snake-swap');
	unbind('snake-explode');
	unbind('snake-inventory');
}
