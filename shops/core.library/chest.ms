/*
	Returns how many of an item an inventory contains at a location.
	@item: 0:0 format
*/
proc _chest_item_count(@loc, @item) {
	try {
		@inv = get_inventory(@loc);
	} catch(FormatException @ex) {
		return(null);
	}
	if(is_numeric(@item)) {
		@item .= ':0';
	}
	@count = 0;
	foreach(@i in @inv) {
		if(!is_null(@i) && @i['type'].':'.@i['data'] === @item) {
			@count += @i['qty'];
		}
	}
	return(@count);
}
