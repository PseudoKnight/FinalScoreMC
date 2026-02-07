proc _class_load(@player, @pvp) {
	bind('item_swap', array(id: @player.'hoplite', priority: 'HIGH'), array(player: @player), @event, @pvp) {
		if(@event['off_hand']) {
			@item = @event['off_hand']['name'];
			if(@item === 'SHIELD' || @item === 'IRON_SPEAR') {
				// prevent pvp event handler from canceling
				consume();
			}
		}
	}
}

proc _class_unload(@player, @pvp) {
	unbind(@player.'hoplite');
}