// Protect farmland when using feather falling boots
bind('pressure_plate_activated', null, null, @event) {
	if(get_block(@event['location']) === 'FARMLAND') {
		@item = pinv(player(), 100);
		if(@item && @item['meta'] && array_index_exists(@item['meta']['enchants'], 'feather_falling')) {
			cancel();
		}
	}
}