proc _is_shop_owner(@shop, @player) {
	if(!@player) {
		@player = player();
	}
	if(length(@player) > 15) {
		try {
			if(substr(@shop['owner'], 0, 13) == substr(@player, 0, 13)) {
				return(true);
			}
		} catch(RangeException @ex) {
			return(false);
		}
	} else if(@shop['owner'] == @player) {
		return(true);
	}
	return(false);
}
