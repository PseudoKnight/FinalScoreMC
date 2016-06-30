switch(@action) {
case 'load':
	bind('inventory_click', array('id': @player.'invclick'), array('player': @player), @event) {
		cancel();
	}

	set_interval(250, closure() {
		try {
			if(pinv(@player, 103)['type'] != 7) {
				clear_task();
			}
		} catch(Exception @ex) {
			clear_task();
			die();
		}
		
		@hunter = puuid(@player);
		foreach(@p in array_keys(@pvp['players'])) {
			if(@p == @player, continue());
			@helm = pinv(@p, 103);
			if(!is_null(@helm) && @helm['type'] == 86) {
				set_ptexp(@player, ptexp(@player) + 1);
				set_pinv(@p, array(103: null));
			} else if(entity_can_see(@hunter, puuid(@p))) {
				set_ptexp(@player, ptexp(@player) + 1);
				set_pinv(@p, array(103: array('type': 86)));
				set_peffect(@p, 9, 0, 4);
				if(!rand(8)) {
					play_named_sound(ploc(@player), array('sound': 'mob.guardian.attack', 'pitch': 2));
				}
			}
		}
	});

case 'unload':
	unbind(@player.'invclick');
}
