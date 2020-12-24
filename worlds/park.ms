bind('region_change', null, null, @event) {
	if(array_contains(@event['toRegions'], 'end')) {
		set_ptime(22000);
		set_psky(player(), 1, 1);
	} else if(array_contains(@event['fromRegions'], 'end')) {
		preset_time();
		set_psky(player(), 0, 0);
	}
}