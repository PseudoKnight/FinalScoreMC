switch(@action) {
case 'load':
	bind('inventory_click', array('id': @player.'invclick'), array('player': @player), @event) {
		cancel();
	}

	set_interval(250, closure() {
		try {
			if(pinv(@player, 103)['type'] != 7) {
				clear_task();
				die();
			}
		} catch(Exception @ex) {
			clear_task();
			die();
		}

		@hunter = puuid(@player);
		foreach(@p in array_keys(@pvp['players'])) {
			if(@p == @player, continue());
			@helm = pinv(@p, 103);
			if(entity_can_see(@hunter, puuid(@p))) {
				if(is_null(@helm)) {
					set_inventory_item(puuid(@p), 103, associative_array('type': 86));
				}
				set_ptexp(@player, ptexp(@player) + 1);
				set_phunger(@player, min(20, phunger(@player) + 1));
				set_phealth(@player, min(20, pinfo(@player, 5) + 0.2));
				set_peffect(@p, 9, 0, 4);
				set_peffect(@p, 24, 0, 9999, true);
				play_named_sound(ploc(@p), array('sound': 'entity.guardian.attack', 'pitch': 2));
			} else if(!is_null(@helm) && @helm['type'] == 86) {
				set_inventory_item(puuid(@p), 103, null);
			}
		}
	});

case 'unload':
	unbind(@player.'invclick');
}
