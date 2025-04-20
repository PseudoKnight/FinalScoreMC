proc _sign_get_shop(@location) {
	@sign = null;
	try {
		@sign = get_sign_text(@location);
	} catch(RangeException @ex) {
		return(null);
	}
	
	# Get owner
	@owner = @sign[3];
	if(length(@owner) < 3) {
		return(null);
	}

	@buy = _sign_get_buy_price(@sign);
	@sell = _sign_get_sell_price(@sign);
	if(@buy || @sell) {	
		@itemString = _sign_get_item_string(@sign);
		@item = _item_get_material(@itemString);
		if(!equals_ic(@item, @itemString)) {
			console('Updating shop item from '.@itemString.' to '.@item);
			@sign[0] = '['.@item.']';
			set_sign_text(@location, @sign);
		}

		# Update owner player name, if changed
		@pdata = null;
		try {
			@autocomplete = (length(@owner) == 15 && @owner[13] === '~');
			if(@autocomplete) {
				@owner = substr(@owner, 0, 13);
			}
			@pdata = _pdata(@owner, @autocomplete);
		} catch(NotFoundException @ex) {
			console('Cannot find shop owner by the name "'.@owner.'" @ '.@location);
			return(null);
		}
		@currentName = @pdata['name'];
		if(@currentName != @owner) {
			@owner = @pdata['name'];
			@sign[3] = @owner;
			set_sign_text(@location, @sign);
		}

		return(array(
			'item': @item,
			'buy': @buy,
			'sell': @sell,
			'owner': @owner,
			'loc': @location,
		));
	}
	return(null);
}

proc _sign_get_item_string(@sign) {
	@match = reg_match('^\\[(.+)\\]$', @sign[0])
	if(@match && !equals_ic(@match[1], 'private')) { // ignore private/deadbolt signs
		return(replace(to_upper(@match[1]), ' ', '_'));
	} else {
		return(null);
	}
}

proc _sign_get_buy_price(@sign) {
	return(reg_match('^(?:Buy) ((\\d{1,4}) for (\\d{1,4})([degi]))$', @sign[1]));
}

proc _sign_get_sell_price(@sign) {
	return(reg_match('^(?:Sell) ((\\d{1,4}) for (\\d{1,4})([degi]))$', @sign[2]));
}
