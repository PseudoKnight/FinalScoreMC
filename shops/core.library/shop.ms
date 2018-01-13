proc _get_shop(@loc) {
	try {
		@sign = get_sign_text(@loc);
	} catch(RangeException @ex) {
		return(null);
	}
	
	# Get owner
	@owner = @sign[3];
	if(length(@owner) < 2) {
		return(null);
	}
	
	# Get item
	@itemMatch = reg_match('^\\[(.+)\\]$', @sign[0]);
	@item = '';
	if(!@itemMatch) {
		return(null);
	} else {
		@item = _data_values(@itemMatch[1]);
		if(!@item) {
			return(null);
		}
	}
	
	@buy = _get_price(@sign[1]);
	@sell = _get_price(@sign[2]);
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
				set_sign_text(@loc, @sign);
			} else {
				console('Cannot convert shop owner from '.@sign[3].' to '.@owner.' due to length.', false);
				console('Location: '.@loc, false);
			}
		}
		
		return(array(
			'item': @item,
			'key': replace(@item, ':', '.'),
			'buy': @buy,
			'sell': @sell,
			'owner': @owner,
		));
	}
}

proc _is_shop_sign(@sign) {
	return(length(@sign[3]) > 2 && reg_match('^\\[(.+)\\]$', @sign[0]) && (_get_price(@sign[1]) || _get_price(@sign[2])));
}

proc _get_price(@string) {
	return(reg_match('^(?:Buy|Sell) ((\\d{1,4}) for (\\d{1,4})([degi]))$', @string));
}

proc _is_shop_owner(@player, @shopOwner) {
	if(length(@player) > 15) {
		try {
			if(substr(@shopOwner, 0, 13) == substr(@player, 0, 13)) {
				return(true);
			}
		} catch(RangeException @ex) {
			return(false);
		}
	} else if(@shopOwner == @player) {
		return(true);
	}
	return(false);
}

proc _data_values(@item) {
	@itemMatch = reg_match('^([\\w\\s]+)(?::(\\d{1,5}))?$', @item);
	if(!@itemMatch) {
		return(null);
	}
	if(!is_numeric(@itemMatch[1])) {
		@itemMatch[1] = data_values(@itemMatch[1]);
		if(!@itemMatch[1]) {
			return(null);
		}
		if(@itemMatch[2] && string_position(@itemMatch[1], ':') == -1) {
			@item = @itemMatch[1].':'.@itemMatch[2];
		} else {
			@item = @itemMatch[1];
		}
	}
	return(@item);
}
