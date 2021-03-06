/*
	Returns how many of an item an inventory contains at a location.
	@item: 0:0 format
*/
proc _chest_item_count(@inv, @itemName) {
	@count = 0;
	foreach(@item in @inv) {
		if(!is_null(@item) && @item['name'] == @itemName) {
			@count += @item['qty'];
		}
	}
	return(@count);
}

/*
	Returns whether or not this inventory has an empty slot
*/
proc _chest_has_space(@inv) {
	foreach(@item in @inv) {
		if(is_null(@item)) {
			return(true);
		}
	}
	return(false);
}
