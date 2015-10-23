bind(player_move, null, null, @event) {
	if(@event['to']['world'] != 'outworld' || !ponline(@event['player'])) {
		die();
	}
	
	@loc = ploc();
	@block = get_block_at(@loc);
	switch(@block) {
		case '2:0': #grass
			set_block_at(@loc, '3:0');
		case '3:0':
			set_block_at(@loc, '3:1');
		case '3:1':
			set_block_at(@loc, '13:0');
		case '13:0':
			set_block_at(@loc, '4:0');
		case '4:0':
			set_block_at(@loc, '1:5');
		case '1:5':
			set_block_at(@loc, '1:0');
	}
	
}

bind(item_despawn, null, array('item': 6), @event) {
	if(@event['location']['world'] != 'outworld') {
		die();
	}
	
	@block = get_block_at(_relative(@event['location'], 'down'));
	if((@block[0] == 2 || @block[0] == 3) && @block[1] == ':') {
		set_block_at(@event['location'], @event['item']['type'].':'.@event['item']['data']);
	}
}