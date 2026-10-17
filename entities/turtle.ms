/*
	Make turtles leashable
 */
bind('player_interact_entity', null, array(clicked: 'TURTLE'), @event) {
	@item = pinv(player(), null);
	@loc = entity_loc(@event['id']);
	if(@item && @item['name'] === 'LEAD' && !get_leashholder(@event['id']) && sk_can_build(@loc)) {
		cancel();
		set_leashholder(@event['id'], puuid());
		@item['qty']--;
		set_pinv(player(), null, @item);
		play_sound(@loc, array(sound: 'ITEM_LEAD_TIED'));
	}
}