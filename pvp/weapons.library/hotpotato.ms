array_push(@pvp['binds'], @id.'hotpotato');
bind(player_interact_entity, array('id': @id.'hotpotato'), array('clicked': 'PLAYER'), @event, @id) {
	@toPlayer = @event['data'];

	@pvp = import('pvp'.@id);
	if(!array_index_exists(@pvp['players'], player())
	|| !array_index_exists(@pvp['players'], @toPlayer)) {
		die();
	}
	
	@item = pinv(player(), null);
	if(is_null(@item) 
	|| @item['type'] != 393) {
		die();
	}
	
	if(@item['qty'] == 1) {
		set_pinv(player(), array('null': null));
	} else {
		@item['qty']--;
		set_pinv(player(), array('null': @item));
	}
	
	if(!is_null(@item['meta']['lore'])) {
		clear_task(@item['meta']['lore'][0]);
	}
	
	# get the slot this potato will be in so we can track multiple potatos
	@slot = 0;
	while(@slot < 9) {
		if(is_null(pinv(@toPlayer, @slot))) {
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
			@potato = pinv(@toPlayer, @slot);
			if(@potato['meta']['display'] == '1') {
				bind(entity_damage, array('id': player().'hotpotatodmg'), array('type': 'PLAYER', 'world': 'custom'), @e,
						@damager = player(), @pvp) {
						
					if(!array_index_exists(@pvp['players'], @e['player']), die());
					_stats_damage(@damager, @e['player'], @e['amount'], @pvp);
				}
				explosion(_relative(ploc(@toPlayer), 'up', 1.5), 3, true);
				unbind(player().'hotpotatodmg');
				clear_task();
			} else {
				@potato['meta']['display'] = string(integer(@potato['meta']['display']) - 1);
				play_sound(ploc(@toPlayer), array('sound': 'NOTE_STICKS'));
				@inv = array();
				@inv[@slot] = @potato;
				set_pinv(@toPlayer, @inv);
			}
		, #catch
			clear_task();
			die();
		);
	});
	
	@item['meta']['lore'] = array(@task);
	
	@inv = array();
	@inv[@slot] = @item;
	set_pinv(@toPlayer, @inv);
}

array_push(@pvp['binds'], @id.'hotdrop');
bind(item_drop, array('id': @id.'hotdrop'), array('item': 393), @event, @id) {
	@pvp = import('pvp'.@id);
	if(array_index_exists(@pvp['players'], player())) {
		cancel();
	}
}