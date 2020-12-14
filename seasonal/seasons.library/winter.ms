bind('region_change', null, null, @event) {
	if(array_contains(@event['toRegions'], 'winterisle')) {
		set_pstorm(true);
	} else if(array_contains(@event['fromRegions'], 'winterisle')) {
		set_pstorm(false);
	}
}