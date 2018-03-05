proc _sign_get_shop(@location) {
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
	
	# Get item
	@itemMatch = _get_shop_item(@sign[0]);
	@item = '';
	if(!@itemMatch) {
		return(null);
	} else {
		@item = _data_values(@itemMatch[1]);
		if(!@item) {
			console('[Shop] Cannot find item value for '.@itemMatch[1], false);
			return(null);
		}
	}
	
	@buy = _get_shop_price(@sign[1]);
	@sell = _get_shop_price(@sign[2]);
	if(@buy || @sell) {
		# Update owner player name, if changed
		try {
			@autocomplete = (length(@owner) == 15 && @owner[13] === '~');
			if(@autocomplete) {
				@owner = substr(@owner, 0, 13);
			}
			@pdata = _pdata(@owner, @autocomplete);
		} catch(NotFoundException @ex) {
			return(null);
		}
		@currentName = @pdata['name'];
		if(@autocomplete) {
			@currentName = substr(@currentName, 0, 13);
		}
		if(@currentName != @owner) {
			@owner = @pdata['name'];
			if(length(@owner) < 16) {
				@sign[3] = @pdata['name'];
				set_sign_text(@location, @sign);
			} else {
				console('Cannot convert shop owner from '.@sign[3].' to '.@owner.' due to length.', false);
				console('Location: '.@location, false);
			}
		}
		
		return(array(
			'item': @item,
			'buy': @buy,
			'sell': @sell,
			'owner': @owner,
		));
	}
	return(null);
}

proc _is_shop_sign(@lines) {
	return(length(@lines[3]) > 2 && _get_shop_item(@lines[0]) && (_get_shop_price(@lines[1]) || _get_shop_price(@lines[2])));
}

proc _get_shop_item(@line) {
	return(reg_match('^\\[(.+)\\]$', @line));
}

proc _get_shop_price(@line) {
	return(reg_match('^(?:Buy|Sell) ((\\d{1,4}) for (\\d{1,4})([degi]))$', @line));
}
