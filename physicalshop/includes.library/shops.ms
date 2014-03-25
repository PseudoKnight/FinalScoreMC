proc('_is_shop', @loc) {
	@text = get_sign_text(@loc)
	if(reg_match('^\\[(.+)\\]$', @text[0])
	&& (length(@text[1]) > 7 && substr(@text[1], 0, 3) == 'Buy'
	|| length(@text[2]) > 8 && substr(@text[2], 0, 4) == 'Sell')) {
		return(true)
	} else {
		return(false)
	}
}

proc('_is_shop_owner', @loc) {
	@owner = get_sign_text(@loc)[3]
	if(length(player()) > 15) {
		if(substr(@owner, 0, 13) == substr(player(), 0, 13)) {
			return(true)
		} else {
			return(false)
		}
	} else if(@owner == player()) {
		return(true)
	} else {
		return(false)
	}
}


proc('_shop_item', @signtext) {
	@item = reg_match('\\[([\\w\\s]+)(?::([0-9]{1,4}))?\\]', @signtext)
	if(array_size(@item) < 2, die())
	if(is_numeric(@item[1])) {
		if(@item[2] != null) {
			@itemid = @item[1].'.'.@item[2]
		} else {
			@itemid = @item[1]
		}
	} else {
		if(@item[2] != null) {
			@itemid = reg_split('\\:', data_values(@item[1]))[0].'.'.@item[2]
		} else {
			@itemid = reg_replace(':', '.', data_values(@item[1]))
			if(@itemid == null, die())
		}
	}
	return(@itemid)
}