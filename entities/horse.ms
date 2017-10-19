# prevent non-owners from riding a horse, unless shared
bind(player_interact_entity, null, array('clicked': '/(DONKEY|HORSE|LLAMA|MULE|SKELETON_HORSE|ZOMBIE_HORSE)/'), @event) {
	if(!_is_survival_world(pworld())) {
		die();
	}

	@jump = 0;
	try {
		@yVelocity = round(entity_spec(@event['id'])['jump'], 2);
		# calculate jump height in meters
		while(@yVelocity > 0) {
			@jump += @yVelocity;
			@yVelocity -= 0.08;
			@yVelocity *= 0.98;
		}
		@jump = round(@jump, 1);
	} catch(IndexOverflowException @ex) {
		// llama
	}
	@health = round(get_max_health(@event['id']) / 2, 1);
	@speed = round(get_attribute(@event['id'], 'movementspeed') * 43, 2);
	if(function_exists('action_msg')) {
		set_timeout(50, closure(){
			action_msg(colorize('&c'.@health.' \u2764 &e'.@jump.' \u279A &a'.@speed.' \u279F'));
		});
	}

	@item = pinv(player(), null);
	@owner = get_mob_owner(@event['id']);
	if(@owner && @owner != player()) {
		msg('This animal is owned by '.@owner);
		if(!has_permission('group.moderator')
		&& (!@item || (@item['type'] != 322	&& @item['type'] != 396))) {
			@pdata = null;
			try {
				@pdata = _pdata(@owner);
			} catch(NotFoundException @ex) {
				cancel();
				die('We have no records for the owner of this horse.'
					.' If this is in error, contact an administrator.');
			}
			if(!array_index_exists(@pdata, 'shared')
			|| !array_index_exists(@pdata['shared'], player())
			|| !array_contains(@pdata['shared'][player()], 'horses')) {
				cancel();
				# reset their view; mostly fixes client side glitch when canceling this event
				@facing = pfacing();
				pfacing(@facing[0], @facing[1]);
			}
		}
	} else if(is_null(@owner) && !is_null(entity_spec(@event['id'])['saddle'])) {
		tame_mob(@event['id']);
		msg('You now own this animal.');
	}

	# skeleton/zombie horses
	if(!is_cancelled() && !psneaking()) {
		if(@event['clicked'] === 'ZOMBIE_HORSE' || @event['clicked'] === 'SKELETON_HORSE') {
			if(@item) {
				switch(@item['type']) {
					case 322: # gold apple
					case 396: # gold carrot
					case 420: # lead
						die();
					case 367: # rotten flesh
						@heatlh = get_entity_health(@event['id']);
						if(@health != 100) {
							cancel();
							@facing = pfacing();
							pfacing(@facing[0], @facing[1]);
							set_entity_health(@event['id'], min(100, @health + (100 / get_max_health(@event['id']))));
							set_mob_age(@event['id'], min(0, get_mob_age(@event['id']) + 1200));
							@item['qty'] -= 1;
							set_pinv(player(), array(null: if(!@item['qty'], null, @item)));
							die();
						}
				}
			}
			if(is_null(entity_spec(@event['id'])['saddle'])
			&& is_null(get_entity_rider(@event['id']))) {
				set_entity_rider(@event['id'], puuid());
			}
		}
	}
}
