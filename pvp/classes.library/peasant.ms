switch(@action) {
case 'load':
	proc _prime_hot_potato(@damager, @damaged, @item, @pvp) {
		try {
			if(!is_null(@item['meta']['lore'])) {
				clear_task(@item['meta']['lore'][0]);
			}
		} catch(IndexOverflowException @ex) {
			// not a hot potato
			return();
		}

		# get the slot this potato will be in so we can track multiple potatos
		@slot = 0;
		while(@slot < 9) {
			if(is_null(pinv(@damaged, @slot))) {
				break();
			}
			@slot++;
			if(@slot > 8) {
				die();
			}
		}

		if(@item['meta']['display'] === 'HOT POTATO') {
			@item['meta']['display'] = '12';
		}

		@task = set_interval(1000, closure() {
			try {
				@potato = pinv(@damaged, @slot);
				if(@potato['meta']['display'] == '1') {
					bind('entity_damage', array('id': @damaged.'hotpotatodmg'), array('type': 'PLAYER'), @e,
							@damager, @pvp) {

						if(!array_index_exists(@pvp['players'], @e['player']), die());
						_stats_damage(@damager, @e['player'], @e['amount'], @pvp);
					}
					explosion(location_shift(ploc(@damaged), 'up', 1.5), 2, true);
					unbind(@damaged.'hotpotatodmg');
					clear_task();
				} else {
					@potato['meta']['display'] = string(integer(@potato['meta']['display']) - 1);
					play_sound(ploc(@damaged), array('sound': 'BLOCK_NOTE_BLOCK_STICKS'));
					set_pinv(@damaged, @slot, @potato);
				}
			} catch(Exception @e) {
				clear_task();
				die();
			};
		});

		@item['meta']['lore'] = array(@task);
		set_pinv(@damaged, @slot, @item);
	}
	bind('entity_damage', array('id': @player.'pot'), array('type': 'PLAYER', 'cause': 'ENTITY_ATTACK'), @e, @pvp, @player) {
		if(!array_index_exists(@pvp['players'], @e['damager'])) {
			die();
		}
		@damager = @e['damager'];
		@damaged = @e['player'];
		if(@damaged == @player) {
			drop_item(@damager, array('name': 'POTATO_ITEM'));
		}
		@item = pinv(@damager, null);
		if(is_null(@item)) {
			die();
		}
		# regular potato -> launch
		switch(@item['name']) {
			case 'POTATO_ITEM': # launch
				modify_event('amount', 3);
				set_timeout(50, closure(){
					@vector = entity_velocity(puuid(@damaged));
					@vector['x'] *= 1.5;
					@vector['y'] *= 2.5;
					@vector['z'] *= 1.5;
					set_pvelocity(@damaged, @vector);
				});

			case 'POISONOUS_POTATO': # poison effect
				set_peffect(@damaged, 19, 0, 10);

			case 'BAKED_POTATO': # hot potato
				set_pinv(@damager, null, null);
				_prime_hot_potato(@damager, @damaged, @item, @pvp);

		}
	}

	bind('item_drop', array('id': @player.'hotdrop'), array('itemname': 'BAKED_POTATO'), @e, @pvp) {
		if(array_index_exists(@pvp['players'], player())) {
			cancel();
		}
	}

	bind('item_pickup', array('id': @player.'hotpickup', 'priority': 'HIGH'), array('itemname': 'LILY_PAD'), @e, @pvp) {
		if(!array_index_exists(@pvp['players'], @e['player'])) {
			die();
		}
		@inv = pinv();
		foreach(@slot in 0..8) {
			if(@inv[@slot] && @inv[@slot]['name'] == 'BAKED_POTATO' && @inv[@slot]['meta'] && is_integral(@inv[@slot]['meta']['display'])) {
				@droppedItem = drop_item(location_shift(ploc(), 'up', 2), @inv[@slot], true);
				set_entity_spec(@droppedItem, array('pickupdelay': 200));
				set_timeout(1000 * @inv[@slot]['meta']['display'], closure(){
					try {
						explosion(entity_loc(@droppedItem), 3, true);
					} catch(BadEntityException @ex) {
						// dropped hot potato no longer exists
					}
				});
				set_pinv(player(), @slot, null);
			}
		}
	}

	bind('player_consume', array('id': @player.'hoteat'), array('itemname': 'BAKED_POTATO'), @e, @player, @pvp) {
		if(@player == @e['player']) {
			set_timeout(50, closure(){
				_prime_hot_potato(player(), player(), @e['item'], @pvp);
			});
		}
	}

case 'unload':
	unbind(@player.'pot');
	unbind(@player.'hotdrop');
	unbind(@player.'hotpickup');
	unbind(@player.'hoteat');
}
