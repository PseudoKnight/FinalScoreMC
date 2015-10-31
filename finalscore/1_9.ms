bind(block_break, null, array('type': data_values('deadbush')), @event) {
	if(!sk_can_build(@event['location'])) {
		die();
	}
	@qty = rand(3);
	if(@qty) {
		modify_event('drops', array(array('name': 'STICK', 'qty': @qty)));
	}
}

bind(entity_damage, null, array('type': 'ITEM_FRAME', 'cause': 'ENTITY_ATTACK'), @event) {
	if(ponline(@event['damager']) && sk_can_build(@event['damager'], @event['location'])) {
		@item = entity_spec(@event['id'])['item'];
		if(!is_null(@item)) {
			cancel();
			@loc = array(
				floor(@event['location']['x']) + 0.5,
				@event['location']['y'],
				floor(@event['location']['z']) + 0.5,
				@event['location']['world']
			);
			set_entity_spec(@event['id'], array('item': null));
			drop_item(@loc, @item, false);
		}
	}
}

bind(hanging_break, null, array('type': '/(ITEM_FRAME|PAINTING)/', 'cause': 'ENTITY'), @event) {
	if(!is_null(@event['player']) && sk_can_build(@event['player'], @event['location'])) {
		cancel();
		entity_remove(@event['id']);
		@loc = array(
			floor(@event['location']['x']) + 0.5,
			@event['location']['y'],
			floor(@event['location']['z']) + 0.5,
			@event['location']['world']
		);
		drop_item(@loc, array('name': @event['type']), false);
	}
}