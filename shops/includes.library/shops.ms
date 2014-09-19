proc _get_shop(@loc) {
	try(@sign = get_sign_text(@loc), return())
	@itemMatch = reg_match('^\\[(.+)\\]$', @sign[0])
	@item = ''
	if(!@itemMatch) {
		return()
	} else {
		@item = _data_values(@itemMatch[1])
		if(!@item) {
			return()
		}
	}
	@owner = @sign[3]
	if(!@owner) {
		return()
	}
	@buy = _get_price(@sign[1])
	@sell = _get_price(@sign[2])
	if(@buy || @sell) {
		return(array(
			item: @item,
			key: replace(@item, ':', '.'),
			buy: @buy,
			sell: @sell,
			owner: @owner,
		))
	}
}

proc _is_shop_sign(@sign) {
	if(reg_match('^\\[(.+)\\]$', @sign[0])
	&& (_get_price(@sign[1]) || _get_price(@sign[2]))
	&& @sign[3]) {
		return(true)
	}
	return(false)
}

proc _get_price(@string) {
	return(reg_match('^(?:Buy|Sell) ((\\d{1,4}) for (\\d{1,4})([degi]))$', @string))
}

proc _is_shop_owner(@player, @shopOwner) {
	if(length(@player) > 15) {
		try(
			if(substr(@shopOwner, 0, 13) == substr(@player, 0, 13)) {
				return(true)
			}
		)
	} else if(@shopOwner == @player) {
		return(true)
	}
}

proc _data_values(@item) {
	@itemMatch = reg_match('^([\\w\\s]+)(?::(\\d{1,5}))?$', @item)
	if(!@itemMatch, return())
	if(!is_numeric(@itemMatch[1])) {
		@itemMatch[1] = data_values(@itemMatch[1])
		if(!@itemMatch[1], return())
		if(@itemMatch[2] && string_position(@itemMatch[1], ':') == -1) {
			@item = @itemMatch[1].':'.@itemMatch[2]
		} else {
			@item = @itemMatch[1]
		}
	}
	return(@item)
}