/*
	Allows a player to exchange any item in their hand with a pillager,
	provided that pillager is not holding a crossbow.
	Features region protections for these pillagers now that they're not hostile.
 */
bind('player_interact_entity', null, array('clicked': 'PILLAGER', 'hand': 'main_hand'), @event) {
	@loc = entity_loc(@event['id']);
	if(sk_can_build(@loc)) {
		@weapon = get_mob_equipment(@event['id'])['weapon'];
		if(!@weapon || @weapon['name'] != 'CROSSBOW') {
			cancel();
			@item = pinv(player(), null);
			if(@item) {		
				@item['qty']--;
				if(@item['qty']) {
					set_pinv(player(), null, @item);
					if(@weapon && pgive_item(@weapon) > 0) {
						drop_item(@weapon);
					}
				} else {
					set_pinv(player(), null, @weapon);
				}
				@item['qty'] = 1;
				set_mob_equipment(@event['id'], array('WEAPON': @item));
				set_equipment_droprates(@event['id'], array('WEAPON': 1.0));
				play_sound(@loc, array('sound': 'ITEM_ARMOR_EQUIP_LEATHER', 'volume': 0.2));
			} else if(@weapon) {
				set_pinv(player(), null, @weapon);
				set_mob_equipment(@event['id'], array('WEAPON': null));
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