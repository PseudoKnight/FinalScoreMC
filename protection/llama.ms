bind('player_interact_entity', null, array(clicked: 'LLAMA'), @event) {
	@owner = get_mob_owner(@event['id']);
	if(@owner && @owner != player()) {
		msg('This llama is owned by '.@owner);
		if(entity_spec(@event['id'])['chest']) { // only protect llamas with chest inventories
			@item = pinv(player(), null);
			if(!@item || @item['name'] !== 'HAY_BALE') {
				@pdata = null;
				try {
					@pdata = _pdata(@owner);
				} catch(NotFoundException @ex) {
					cancel();
					die('We have no records for the owner of this llama.'
						.' If this is in error, contact an administrator.');
				}
				if(@pdata['name'] == player()) {
					// account change
					set_mob_owner(@event['id'], player());
				} else if(!array_index_exists(@pdata, 'shared')
				|| !array_index_exists(@pdata['shared'], player())
				|| !array_contains(@pdata['shared'][player()], 'horses')) {
					cancel();
					# reset their view; mostly fixes client side glitch when canceling this event
					@facing = pfacing();
					pfacing(@facing[0], @facing[1]);
				}
			}
		}
	}
}