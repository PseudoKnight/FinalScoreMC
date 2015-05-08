array_push(@pvp['binds'], @id.'hotpotato');
bind(player_interact_entity, array('id': @id.'hotpotato'), array('clicked': 'PLAYER'), @event, @id = @id) {
	@pvp = import('pvp'.@id);
	if(!array_index_exists(@pvp['players'], player())
	|| !array_index_exists(@pvp['players'], @event['data'])) {
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
	if(@item['meta']['display'] == 'HOT POTATO') {
		@item['meta']['display'] = 10;
	}
	@task = set_interval(1000, closure() {
		if(array_size(@slots = pitem_slot(@event['data'], 393)) > 0) {
			@inv = pinv(@event['data']);
			foreach(@slot in @slots) {
				if(is_numeric(@inv[@slot]['meta']['display'])) {
					break();
				}
			}
			if(integer(@inv[@slot]['meta']['display']) == 1) {
				explosion(_relative(ploc(@event['data']), 'up'), 3, true);
				clear_task();
			} else {
				@inv[@slot]['meta']['display'] = integer(@inv[@slot]['meta']['display']) - 1;
				play_sound(ploc(@event['data']), array('sound': 'NOTE_STICKS'));
				set_pinv(@event['data'], @inv);
			}
		} else {
			clear_task();
		}
	});
	@item['meta']['lore'] = array(@task);
	
	pgive_item(@event['data'], 393, 1, @item['meta']);
}

array_push(@pvp['binds'], @id.'hotdrop');
bind(item_drop, array('id': @id.'hotdrop'), array('item': 393), @event, @id = @id) {
	@pvp = import('pvp'.@id);
	if(array_index_exists(@pvp['players'], player())) {
		cancel();
	}
}