# Dispenser handling
# Infinite dispensers on creative/game worlds
# Special behavior for other items (eg. place armor stands)
bind('block_dispense', null, array('type': 'DISPENSER'), @event, @ignored = array('BUCKET', 'WATER_BUCKET', 'LAVA_BUCKET')) {
	if(!@event['item'] || array_contains(@ignored, @event['item']['name'])) {
		die();
	}
	if(!_is_survival_world(@event['location']['world'])) {
		if(!array_contains(sk_region_check_flag(@event['location'], 'blocked-cmds'), '/finitedispensers')) {
			@inv = null;
			try {
				@inv = get_inventory(@event['location']);
			} catch(CastException @ex) {
				die();
			}
			foreach(@i: @item in @inv) {
				if(@item && @item['qty'] < 64) {
					@item['qty'] = 64;
					queue_push(closure(){
						try {
							set_inventory_item(@event['location'], @i, @item);
						} catch(IllegalArgumentException @ex) {
							console('Could not refill dispenser at '. @event['location'], false);
						}
					});
					break();
				}
			}
		}
	}
}
