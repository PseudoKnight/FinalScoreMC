// Block name tags in adventure mode
bind('player_interact_entity', null, null, @event) {
	if(pmode() === 'ADVENTURE' && is_entity_living(@event['id'])) {
		@item = pinv(player(), null);
		if(@item && @item['name'] === 'NAME_TAG') {
			cancel();
		}
	}
}