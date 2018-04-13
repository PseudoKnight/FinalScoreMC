bind(player_interact_entity, null, array('clicked': 'VILLAGER'), @event) {
	@item = pinv(player(), null);
	if(@item && @item['name'] == 'LEASH'
	&& get_leashholder(@event['id']) != puuid()) {
		cancel();
		set_leashholder(@event['id'], puuid());
		@item['qty']--;
		set_pinv(player(), null, @item);
	}
	@inv = get_inventory(@event['id']);
	@output = '';
	foreach(@item in @inv) {
		if(@item) {
			@output .= @item['qty'].'x '.@item['name'].' ';
		}
	}
	if(@output) {
		action_msg(player(), @output);
	}
}
