bind('player_interact_entity', null, array('clicked': 'ITEM_FRAME'), @event) {
	if(pmode() == 'CREATIVE' && psneaking() && sk_can_build(entity_loc(@event['id']))) {
		cancel();
		@item = pinv(player(), null);
		if(@item && @item['name'] == 'SPIDER_EYE') {
			set_timeout(50, closure() {
				@itemframe = entity_spec(@event['id']);
				set_entity_spec(@event['id'], array('visible': !@itemframe['visible']));
			});
		}
	}
}