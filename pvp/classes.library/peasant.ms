switch(@action) {
case 'load':
	bind(entity_damage, array('id': @player.'pot'), array('type': 'PLAYER', 'cause': 'ENTITY_ATTACK', 'world': 'custom'), @e, @pvp) {
		if(!array_index_exists(@pvp['players'], @e['damager'])) {
			die();
		}
		@damager = @e['damager'];
		@damaged = @e['player'];
		@item = pinv(@damager, null);
		if(is_null(@item)) {
			die();
		}
		# regular potato -> launch
		switch(@item['type']) {
			case 392: # potato -> launch
				modify_event('amount', 3);
				set_timeout(50, closure(){
					@vector = entity_velocity(puuid(@damaged));
					@vector['x'] *= 2;
					@vector['y'] *= 2;
					@vector['z'] *= 2;
					set_pvelocity(@damaged, @vector);
				});
				
			case 394: # poison potato -> poison effect
				set_peffect(@damaged, 19, 0, 10);
				
			case 393: # cooked potato -> hot potato
				if(@item['qty'] == 1) {
					set_pinv(@damager, array(null: null));
				} else {
					@item['qty']--;
					set_pinv(@damager, array(null: @item));
				}
				
				if(!is_null(@item['meta']['lore'])) {
					clear_task(@item['meta']['lore'][0]);
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
				
				if(@item['meta']['display'] == 'HOT POTATO') {
					@item['meta']['display'] = '10';
				}
				
				@task = set_interval(1000, closure() {
					try(
						@potato = pinv(@damaged, @slot);
						if(@potato['meta']['display'] == '1') {
							bind(entity_damage, array('id': @damaged.'hotpotatodmg'), array('type': 'PLAYER', 'world': 'custom'), @e,
									@damager, @pvp) {
									
								if(!array_index_exists(@pvp['players'], @e['player']), die());
								_stats_damage(@damager, @e['player'], @e['amount'], @pvp);
							}
							explosion(_relative(ploc(@damaged), 'up', 1.5), 3, true);
							unbind(@damaged.'hotpotatodmg');
							clear_task();
						} else {
							@potato['meta']['display'] = string(integer(@potato['meta']['display']) - 1);
							play_sound(ploc(@damaged), array('sound': 'NOTE_STICKS'));
							@inv = array();
							@inv[@slot] = @potato;
							set_pinv(@damaged, @inv);
						}
					, #catch
						clear_task();
						die();
					);
				});
				
				@item['meta']['lore'] = array(@task);
				
				@inv = array();
				@inv[@slot] = @item;
				set_pinv(@damaged, @inv);

		}
	}
		
	bind(item_drop, array('id': @player.'hotdrop'), array('item': 393), @e, @pvp) {
		if(array_index_exists(@pvp['players'], player())) {
			cancel();
		}
	}
			
	bind(item_pickup, array('id': @player.'hotpickup', 'priority': 'HIGH'), array('item': 111), @e, @pvp) {
		if(!array_index_exists(@pvp['players'], @e['player'])) {
			die();
		}
		@inv = pinv();
		foreach(@slot in 0..8) {
			if(@inv[@slot] && @inv[@slot]['type'] == 393 && @inv[@slot]['meta'] && is_integral(@inv[@slot]['meta']['display'])) {
				@droppedItem = drop_item(_relative(ploc(), 'up', 2), @inv[@slot], true);
				set_entity_spec(@droppedItem, array('pickupdelay': 200));
				set_timeout(1000 * @inv[@slot]['meta']['display'], closure(){
					try(explosion(entity_loc(@droppedItem), 3, true));
				});
				@inv[@slot] = null;
				set_pinv(@inv);
			}
		}
	}
	
case 'unload':
	unbind(@player.'pot');
	unbind(@player.'hotdrop');
	unbind(@player.'hotpickup');
}