bind(player_interact_entity, null, array('clicked': 'VILLAGER'), @event) {
	if(pworld() == 'shard') {
		die();
	}
	@item = pinv(player(), null);
	if(@item && @item['type'] == 420
	&& get_player_from_entity_id(get_leashholder(@event['id'])) != player()) {
		cancel();
		set_leashholder(@event['id'], puuid());
		@item['qty'] = @item['qty'] - 1;
		set_pinv(array(null: @item));
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
