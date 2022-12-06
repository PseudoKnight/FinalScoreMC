/*
	Allows players to put heads/skulls on villagers.
	Also prints villager inventory information on right-click.
 */
bind('player_interact_at_entity', null, array(clicked: 'VILLAGER', hand: 'main_hand'), @event) {
	// place or remove heads/skull items on villagers
	@item = pinv(player(), null);
	if(@item) {
		@itemname = @item['name'];
	 	if(@event['position']['y'] > 1.77
				&& (@itemname == 'PLAYER_HEAD' || @itemname == 'ZOMBIE_HEAD' || @itemname == 'SKELETON_SKULL'
				|| @itemname == 'WITHER_SKELETON_SKULL' || @itemname == 'CREEPER_HEAD' || @itemname == 'DRAGON_HEAD')) {
			if(is_null(get_mob_equipment(@event['id'])['helmet'])) {
				cancel();
				@item['qty']--;
				set_pinv(player(), null, @item);
				@item['qty'] = 1;
				set_mob_equipment(@event['id'], array(helmet: @item));
			}
		}
	} else if(@event['position']['y'] > 1.77) {
		if(!is_null(get_mob_equipment(@event['id'])['helmet'])) {
			cancel();
			set_pinv(player(), null, get_mob_equipment(@event['id'])['helmet']);
			set_mob_equipment(@event['id'], array(helmet: null));
		}
	}

	// print villager inventory
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
