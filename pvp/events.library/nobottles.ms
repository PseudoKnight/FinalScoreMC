proc _bind(@pvp) {
	@pvp['binds'][] = bind('player_consume', null, array(itemname: 'POTION'), @event, @pvp) {
		if(array_index_exists(@pvp['players'], player())) {
			queue_push(iclosure(){
				ptake_item(array(name: 'GLASS_BOTTLE'));
			});
		}
	}
}