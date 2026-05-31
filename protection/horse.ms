# prevent non-owners from riding a horse, unless shared
bind('player_interact_entity', null, array('clicked': '/(DONKEY|HORSE|MULE|SKELETON_HORSE|ZOMBIE_HORSE)/'), @event) {
	if(!_is_survival_world(pworld())) {
		die();
	}

	@jump = 0;
	try {
		@strength = entity_spec(@event['id'])['jump'];
		# calculate jump height in meters
		@jump = -0.9078526641492174 * @strength ** 3
				+ 5.380296913832499 * @strength ** 2
				+ 0.8696246225981936 * @strength
				- 0.04348078381106464;
		@jump = round(@jump, 2);
	} catch(IndexOverflowException @ex) {
		// llama
	}
	@health = round(get_max_health(@event['id']) / 2, 1);
	@speed = round(entity_attribute_base(@event['id'], 'GENERIC_MOVEMENT_SPEED') * 42.16, 3);
	set_timeout(50, closure(){
		action_msg(colorize('&c'.@health.' \u2764 &e'.@jump.' \u279A &a'.@speed.' \u279F'));
	});

	@item = pinv(player(), null);
	@owner = get_mob_owner(@event['id']);
	if(@owner && @owner != player()) {
		msg('This animal is owned by '.@owner);
		if(!has_permission('group.moderator')
		&& (!@item || (@event['clicked'] !== 'HORSE' && @event['clicked'] !== 'DONKEY'
		|| @item['name'] !== 'GOLDEN_APPLE' && @item['name'] !== 'GOLDEN_CARROT'))) {
			@pdata = null;
			try {
				@pdata = _pdata(@owner);
			} catch(NotFoundException @ex) {
				cancel();
				die('We have no records for the owner of this horse.'
					.' If this is in error, contact an administrator.');
			}
			if(@pdata['name'] == player()) {
				// account change
				set_mob_owner(@event['id'], player());
			} else if(!array_index_exists(@pdata, 'shared')
			|| !array_index_exists(@pdata['shared'], player())
			|| !array_contains(@pdata['shared'][player()], 'horses')) {
				cancel();
			}
		}
	} else if(is_null(@owner) && !is_null(entity_spec(@event['id'])['saddle'])) {
		set_mob_owner(@event['id'], player());
		msg('You now own this animal.');
	}
}