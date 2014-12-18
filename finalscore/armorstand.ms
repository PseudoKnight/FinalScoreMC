# Armor stand protection
bind(player_interact, null, array('item': 416, 'button': 'right'), @event) {
	if(@event['action'] == 'right_click_block' 
	&& _is_survival_world(@event['world'])
	&& (!sk_can_build(@event['location']) || !sk_region_check_flag(@event['location'], 'mob-spawning'))) {
		cancel();
	}
}

bind(player_interact_at_entity, null, array('clicked': 'ARMOR_STAND'), @event) {
	if(_is_survival_world(entity_loc(@event['id'])['world']) 
	&& !sk_can_build(entity_loc(@event['id']))) {
		cancel();
	}
	
	@item = pinv(player(), null);
	if(!is_null(@item) && @item['type'] == 280 && @item['qty'] >= 2 
	&& !entity_spec(@event['id'])['arms']) {
		set_entity_spec(@event['id'], array('arms': true));
		@item['qty'] -= 2;
		set_pinv(player(), array('null': if(@item['qty'] > 0, @item, null)));
		cancel();
	}
}

bind(entity_damage, null, array('type': 'ARMOR_STAND'), @event) {
	@damager = '';
	if(array_index_exists(@event, 'damager')) {
		@damager = @event['damager'];
	} else if(array_index_exists(@event, 'shooter')) {
		@damager = @event['shooter'];
	}
	
	if(@damager == '' || is_numeric(@damager)) {
		die();
	}
	
	if(_is_survival_world(@event['world']) 
	&& !sk_can_build(@damager, @event['location'])) {
		cancel();
		
	} else if(entity_spec(@event['id'])['arms']) {
		cancel();
		@weapon = get_mob_equipment(@event['id'])['weapon'];
		@loc = entity_loc(@event['id']);
		if(!is_null(@weapon)) {
			drop_item(@loc, @weapon);
			set_mob_equipment(@event['id'], array('weapon': null));
		}
		drop_item(@loc, array('type': 280, 'qty': 2));
		set_entity_spec(@event['id'], array('arms': false));
	}
}