// Add barriers to dangerous flint&steel use
bind('player_interact', null, array(itemname: 'FLINT_AND_STEEL', button: 'right'), @event) {
	@block = @event['block']
	if(!has_permission('item.lighter')
	&& @block
	&& @block !== 'TNT'
	&& @block !== 'CAMPFIRE'
	&& @block !== 'SOUL_CAMPFIRE'
	&& @block !== 'CANDLE_CAKE'
	&& !string_ends_with(@block, 'CANDLE')) {
		if(@block == 'OBSIDIAN' && @event['facing'] == 'up') {
			queue_push(closure(){
				if(get_block(location_shift(@event['location'], 'up')) != 'NETHER_PORTAL') {
					set_block(location_shift(@event['location'], 'up'), 'AIR');
				}
			});
		} else if(!sk_regions_at(location_shift(@event['location'], @event['facing']))) {
			cancel();
			msg('Flint and steel is limited here to nether portals, TNT, campfires, and candles.');
		}
	}
}