// Block enderchests when not in survival worlds
bind('inventory_open', null, null, @event) {
	if(@event['inventorytype'] === 'ENDER_CHEST' && !has_metadata(pworld(), 'survival')) {
		cancel();
	}
}