/*
	Allows a player to exchange any item in their hand with a pillager,
	provided that pillager is not holding a crossbow.
	Features region protections for these pillagers now that they're not hostile.
 */
bind('player_interact_at_entity', null, array('clicked': 'PILLAGER', 'hand': 'main_hand'), @event) {
	@loc = entity_loc(@event['id']);
	if(sk_can_build(@loc)) {
		@held = get_mob_equipment(@event['id'])['weapon'];
		if(!@held || @held['name'] != 'CROSSBOW') {
			// It's passive
			cancel();
			@slot = 'weapon';
			if(@event['position']['y'] > 1.7) {
				@slot = 'helmet';
				@held = get_mob_equipment(@event['id'])['helmet'];;
			}
			@item = pinv(player(), null);
			if(@item) {		
				@item['qty']--;
				if(@item['qty']) {
					set_pinv(player(), null, @item);
					if(@held && pgive_item(@held) > 0) {
						drop_item(@held);
					}
				} else {
					set_pinv(player(), null, @held);
				}
				@item['qty'] = 1;
				@gear = associative_array();
				@drops = associative_array();
				@gear[@slot] = @item;
				@drops[@slot] = 1.0;
				set_mob_equipment(@event['id'], @gear);
				set_equipment_droprates(@event['id'], @drops);
				play_sound(@loc, array('sound': 'ITEM_ARMOR_EQUIP_LEATHER', 'volume': 0.2));
			} else if(@held) {
				set_pinv(player(), null, @held);
				@gear = associative_array();
				@gear[@slot] = null;
				set_mob_equipment(@event['id'], @gear);
				play_sound(@loc, array('sound': 'ITEM_ARMOR_EQUIP_LEATHER', 'volume': 0.2));
			}
		}
	}
}

bind('entity_damage', null, array('type': 'PILLAGER'), @event) {
	if(_is_survival_world(@event['world'])) {
		@damager = '';
		if(array_index_exists(@event, 'shooter')) {
			@damager = @event['shooter'];
		} else if(array_index_exists(@event, 'damager')) {
			@damager = @event['damager'];
		}
		if(@damager && ponline(@damager) && !sk_can_build(@damager, @event['location'])) {
			@weapon = get_mob_equipment(@event['id'])['weapon'];
			if(!@weapon || @weapon['name'] != 'CROSSBOW') {
				cancel();
			}
		}
	}
}