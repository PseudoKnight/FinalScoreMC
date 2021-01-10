bind('region_change', null, null, @event) {
	if(array_contains(@event['toRegions'], 'end')) {
		set_ptime(22000);
	} else if(array_contains(@event['fromRegions'], 'end')) {
		preset_time();
	}
}