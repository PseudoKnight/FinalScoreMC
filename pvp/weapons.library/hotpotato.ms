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
	
	# get the slot this potato will be in so we can track multiple potatos
	foreach(@slot in pinv(@event['data'])) {
		if(is_null(@slot)) {
			break();
		}
	}
	
	if(@item['meta']['display'] == 'HOT POTATO') {
		@item['meta']['display'] = 10;
	}
	
	@task = set_interval(1000, closure() {
		@potato = pinv(@event['data'], @slot);
		if(is_null(@potato)) {
			clear_task();
			die();
		}
		
		try(
			@timeleft = integer(@inv[@slot]['meta']['display']);
		, # catch item without a countdown
			clear_task();
			die();
		);
		
		if(@timeleft == 1) {
			explosion(_relative(ploc(@event['data']), 'up', 1.5), 3, true);
			clear_task();
		} else {
			@inv[@slot]['meta']['display'] = @timeleft - 1;
			play_sound(ploc(@event['data']), array('sound': 'NOTE_STICKS'));
			set_pinv(@event['data'], @inv);
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