// Sneak with an open hand to remove saddle from pig or strider
bind('player_interact_entity', null, array(hand: 'main_hand', clicked: '/(PIG|STRIDER)/'), @event) {
	if(psneaking() && !pinv(player(), null) && !get_entity_rider(@event['id']) && entity_spec(@event['id'])['saddled']) {
		cancel();
		set_pinv(player(), null, array(name: 'SADDLE'));
		set_entity_spec(@event['id'], array(saddled: false));
		play_sound(entity_loc(@event['id']), array(sound: 'ITEM_ARMOR_EQUIP_GENERIC'), player());
	}
}