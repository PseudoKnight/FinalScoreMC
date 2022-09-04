proc _snake_bind_events(@game) {
	bind('player_interact', array('id': 'snake-interact'), null, @event, @game) {
		if(array_index_exists(@game['snakes'], player())) {
			@snake = @game['snakes'][player()];
			if(!@snake['turned']) {
				@turn = _snake_turn(@snake['top'], @snake['dir']);
				@snake['dir'] = array_get(@turn, if(@event['button'] == 'right', 1, 0));
				@snake['turned'] = true;
			}
		}
	}

	bind('item_held', array('id': 'snake-held'), null, @event, @game) {
		if(array_index_exists(@game['snakes'], player())) {
			cancel();
			if(@game['snakes'][player()]['alive']) {
				@slot = @event['to'];
				if(@slot < 5) {
					_snake_ability(player(), @slot, @game);
				}
			}
		}
	}

	bind('entity_explode', array('id': 'snake-explode'), array('type': 'PRIMED_TNT'), @event, @game) {
		if(array_contains(sk_regions_at(@event['location']), @game['region'])) {
			array_remove_values(@game['tnt'], @event['id']);
			foreach(@block in @event['blocks']) {
				@id = get_block(@block);
				if(_is_snake_tail(@id)) {
					foreach(@player: @snake in @game['snakes']) {
						if(@snake['loc'][0] == @block[0] && @snake['loc'][1] == @block[1] && @snake['loc'][2] == @block[2]) {
							_snake_kill(@player, @game);
						} else {
							set_block(@block, 'AIR', false);
						}
					}
				} else if(@id == 'TNT') {
					set_block(@block, 'AIR', false);
					_snake_remove_powerup(@block, @game);
					_snake_drop_tnt(array_normalize(@block)[0..3], 'down');
				}
			}
		}
	}

	bind('inventory_open', array('id': 'snake-inventory'), null, @event, @game) {
		if(array_index_exists(@game['snakes'], player())) {
			cancel();
		}
	}

	bind('item_swap', array('id': 'snake-swap'), null, @event, @game) {
		if(array_index_exists(@game['snakes'], player())) {
			cancel();
		}
	}

	bind('item_drop', array('id': 'snake-drop'), null, @event, @game) {
		if(array_index_exists(@game['snakes'], player())) {
			cancel();
		}
	}
}

proc _snake_unbind_events() {
	unbind('snake-interact');
	unbind('snake-held');
	unbind('snake-explode');
	unbind('snake-inventory');
	unbind('snake-swap');
	unbind('snake-drop');
}
